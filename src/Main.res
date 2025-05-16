let main = async () => {
  switch Arg.get(Process.argv) {
  | {help: Some(true)} => Error("Print Help")
  | {
      ink: Some(inkPath),
      validators: Some(validatorsPath),
      seed: Some(seed),
      externals: externalsPath,
    } => {
      let validatorsPath = Path.join([Process.cwd(), validatorsPath])
      let externalsPath =
        externalsPath->Option.map(externalsPath => Path.join([Process.cwd(), externalsPath]))

      let (output, _, buffer) = await Runner.main(
        Msg.Run({inkPath, validatorsPath, seed, externalsPath, maxBufferLength: None}),
      )

      buffer->Array.map(Buffer.print)->Array.join("\n")->Js.log
      Js.log(output)
      Js.log(seed)

      Ok()
    }
  | {
      ink: Some(inkPath),
      validators: Some(validatorsPath),
      itterations,
      externals: externalsPath,
    } => {
      let inkSrc = await Fs.readFile(inkPath, "utf8")
      let sqrtInkLen = inkSrc->String.length->Int.toFloat->Js.Math.sqrt->Float.toInt
      let itterations = switch itterations {
      | Some(x) => x
      | None => sqrtInkLen
      }

      let validatorsPath = Path.join([Process.cwd(), validatorsPath])
      let externalsPath =
        externalsPath->Option.map(externalsPath => Path.join([Process.cwd(), externalsPath]))

      for seed in 1 to itterations {
        let (output, _, buffer) = await Runner.main(
          Msg.Run({
            inkPath,
            validatorsPath,
            seed,
            externalsPath,
            maxBufferLength: Some(sqrtInkLen->Int.toFloat->Js.Math.sqrt->Float.toInt),
          }),
        )

        // buffer->Array.map(Buffer.print)->Array.join("\n")->Js.log
        Js.log(
          `${seed->Int.toString}/${itterations->Int.toString}\t${output
            ->Js.Json.stringifyAny
            ->Option.unwrap}`,
        )

        switch output {
        | Done => ()
        | _ => {
            Js.log("")
            buffer->Array.map(Buffer.print)->Array.join("\n")->Js.log
            Js.log(output->Js.Json.stringifyAny->Option.unwrap->Array.makeFrom->Chalk.red)
            Js.log("seed: " ++ seed->Int.toString)
            Process.exit(1)
          }
        }
      }

      Ok()
    }
  | {ink: None} => Error("missing required argument: --ink")
  | {validators: None} => Error("missing required argument: --validators")
  }
}

let _ = main()->RescriptCore.Promise.thenResolve(result =>
  switch result {
  | Ok(_) => ()
  | Error(err) => {
      Js.log(`
Jernau
A CLI for testing .ink files

Usage:
         $ jernau --ink story.json

Arguments:
        --help
        --version
    
        --ink            : Path to the story.json file to run
        --itterations    : How many times to run
        --seed           : run a single seeded playthrough
        --validators     : Path to the js module that exports the required validators
        --externals      : Optional path to a js module that exports external functions by name
`)

      Js.log(err)
    }
  }
)
