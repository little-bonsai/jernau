open Lbz

%%raw(`import InkJs from "inkjs"
global.InkJs = InkJs`)

@module("../example.mjs") external storyDef: Js.Json.t = "default"
@val external cloneArray: array<'a> => array<'a> = "Array.from"
@get external setSize: Web.Set.t<'a> => int = "size"

type route = array<int>
let coverage = Web.Set.make()

module RouteHash = Belt.Id.MakeHashable({
  type t = route
  let hash = route => route->Random.hashArr->Random.getInt
  let eq = (a, b) => a == b
})

let subroutes = Belt.HashSet.make(~hintSize=10, ~id=module(RouteHash))

let runWithWithSubroute = (~seed, ~subroute: route) => {
  let story = Ink.make(storyDef)
  let gen = Random.gen(~seed, ())

  let route = []
  let foundNewNodes = ref(false)

  let rec do = i => {
    while story->Ink.canContinue {
      story->Ink.continueSingleStep

      let currentPathString = story->Ink.getState->Ink.currentPathString

      if !(coverage->Web.Set.has(currentPathString)) {
        coverage->Web.Set.add(currentPathString)
        subroutes->Belt.HashSet.add(route->cloneArray)
        foundNewNodes := true
      }
    }

    let choices = story->Ink.currentChoices
    let choice: option<Ink.choiceIndex> = Js.Option.firstSome(
      subroute[i]->Option.map(x => Ink.Choice(x)),
      gen()->Random.getFromArray(choices)->Option.map(({index}) => index),
    )

    switch choice {
    | Some(index) => {
        story->Ink.chooseChoiceIndex(index)

        let Ink.Choice(index) = index
        route->Array.push(index)->ignore

        do(i + 1)
      }
    | None => foundNewNodes.contents
    }
  }

  do(0)
}

let gen = Random.gen()

let rec do = uselessWalks => {
  Js.log(
    [
      "useless walks:",
      uselessWalks->Int.toString,
      "subroutes:",
      subroutes->Belt.HashSet.size->Int.toString,
      "coverage:",
      coverage->setSize->Int.toString,
    ]->Array.joinWith(" "),
  )

  let subroute = gen()->Random.getFromArray(subroutes->Belt.HashSet.toArray)

  switch subroute {
  | None =>
    if uselessWalks < 100 {
      runWithWithSubroute(~seed=gen()->Random.getInt, ~subroute=[])->ignore
      do(uselessWalks + 1)
    }

  | Some(subroute) => {
      //seeded walk
      let foundNewRoutes = runWithWithSubroute(~seed=gen()->Random.getInt, ~subroute)

      if !foundNewRoutes {
        subroutes->Belt.HashSet.remove(subroute)->ignore
      }

      do(0)
    }
  }
}

do(0)
