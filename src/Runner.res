@val external import: string => promise<'a> = "import"

let main = async (msg: Msg.t): (Evt.t, int, array<Buffer.t>) => {
  let textBuffer: array<Buffer.t> = []

  switch msg {
  | Run({inkPath, validatorsPath, externalsPath, seed, maxBufferLength}) =>
    try {
      let (inkSrc, validators, externals) = await RescriptCore.Promise.all3((
        Fs.readFile(inkPath, "utf8"),
        import(validatorsPath),
        switch externalsPath {
        | None => RescriptCore.Promise.resolve(Js.Nullable.Null)
        | Some(externalsPath) => import(externalsPath)
        },
      ))

      let inkSrc = inkSrc->Js.Json.parseExn
      let story = Ink.make(inkSrc)

      switch externals->Js.Nullable.toOption {
      | None => ()
      | Some(externals) =>
        externals->RescriptCore.Dict.forEachWithKey((fn, name) => {
          story->Ink.bindExternalFunction(~name, ~fn, ~lookaheadSafe=false)
        })
      }

      story->Ink.allowExternalFunctionFallbacks(true)
      let currentPathString = ref(
        story->Ink.getState->Ink.State.currentPathString->Option.getOr(""),
      )
      let rand = Random.gen(~seed, ())
      story->Ink.getState->Ink.State.setStorySeed(seed)

      let rec do = (): (Evt.t, int, array<Buffer.t>) => {
        switch maxBufferLength {
        | None => ()
        | Some(maxBufferLength) =>
          while textBuffer->Array.length > maxBufferLength {
            let _ = textBuffer->Array.shift
          }
        }

        switch story {
        | story if story->Ink.canContinue => {
            story->Ink.continue
            textBuffer->Array.push(Text(story->Ink.currentText))

            switch validators["lineValid"]->Js.Nullable.toOption {
            | None => do()
            | Some(lineValid) =>
              if lineValid(story->Ink.currentText, story) {
                do()
              } else {
                (
                  InvalidLine({
                    currentPathString: currentPathString.contents,
                  }),
                  seed,
                  textBuffer,
                )
              }
            }
          }

        | story if story->Ink.currentChoices->Array.length > 0 => {
            let idx =
              rand()->Random.getIntRange(~min=0, ~max=story->Ink.currentChoices->Array.length)

            textBuffer->Array.push(
              Options({
                choices: story->Ink.currentChoices->Array.map(Ink.Choice.text),
                chosen: idx,
              }),
            )

            story->Ink.chooseChoiceIndex(Ink.Choice.ChoiceIndex(idx))
            do()
          }

        | story if validators["isDone"](story) => (Done, seed, textBuffer)

        | _ => (
            NotDone({
              currentPathString: currentPathString.contents,
            }),
            seed,
            textBuffer,
          )
        }
      }

      do()
    } catch {
    | e => (Error(e), seed, textBuffer)
    }
  }
}

if !WorkerThreads.isMainThread {
  WorkerThreads.parentPort->WorkerThreads.onMessage(async msg => {
    WorkerThreads.parentPort->WorkerThreads.postMessage(await main(msg))
  })
}
