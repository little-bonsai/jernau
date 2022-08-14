%%raw(`import InkJs from "inkjs"
global.InkJs = InkJs`)

open Lbz

module Log = Lbz.Logger.MakeScope(
  Log,
  {
    let scope = "Ink"
  },
)

let tapProm = (p: Prom.t<'a>, msg: string): Prom.t<'a> => {
  p->Prom.thenResolve(data => {
    Log.log(msg, ~data)
    data
  })
}

type t

@new external make: Js.Json.t => t = "InkJs.Story"

@unboxed type rawTag = Tag(string)
@unboxed type choiceIndex = Choice(int)

type state
@send external serialize: state => string = "ToJson"
@send external parse: (state, string) => unit = "LoadJson"
@get external currentPathString: state => string = "currentPathString"

type choice = {
  text: string,
  index: choiceIndex,
  sourcePath: string,
}

@send external chooseChoiceIndex: (t, choiceIndex) => unit = "ChooseChoiceIndex"
@send external continue: t => unit = "Continue"
@send external continueAsync: t => unit = "ContinueAsync"
@send external continueInternal: t => unit = "ContinueInternal"
@send external continueMaximally: t => unit = "ContinueMaximally"
@send external continueSingleStep: t => unit = "ContinueSingleStep"
@send external observeVariable: (t, string, (. string, 'a) => unit) => unit = "ObserveVariable"
@send external choosePathString: (t, string) => unit = "ChoosePathString"
@send external bindExternalFunction: (t, string, 'a) => unit = "BindExternalFunction"
@send external unbindExternalFunction: (t, 'a) => unit = "UnbindExternalFunction"

@get external canContinue: t => bool = "canContinue"
@get external currentChoices: t => array<choice> = "currentChoices"
@get external currentDebugMetadata: t => unit = "currentDebugMetadata"
@get external currentErrors: t => unit = "currentErrors"
@get external currentFlowName: t => string = "currentFlowName"
@get external currentTags: t => array<rawTag> = "currentTags"
@get external currentText: t => string = "currentText"
@get external currentWarnings: t => unit = "currentWarnings"
@get external getState: t => state = "state"
@get external globalTags: t => unit = "globalTags"
@get external hasError: t => bool = "hasError"
@get external hasWarning: t => bool = "hasWarning"
@get external listDefinitions: t => unit = "listDefinitions"
@get external mainContentContainer: t => unit = "mainContentContainer"

module List = {
  type ink = t
  type t

  type itemOrigin = {
    itemName: string,
    originName: string,
  }

  type item = {@as("Key") key: itemOrigin}

  @send external containsItemNamed: (t, string) => bool = "ContainsItemNamed"
  @get external orderedItems: t => array<item> = "orderedItems"
}

module Variables = {
  type ink = t
  type t

  @get external summon: ink => t = "variablesState"
  @get_index external getVar: (t, string) => 'a = ""
  @set_index external setVar: (t, string, 'a) => unit = ""

  let get = (ink, name) => ink->summon->getVar(name)

  let setBool = (ink, name, val: bool) => {
    Log.debug("setBool", ~data=(name, val))
    ink->summon->setVar(name, val)
  }

  let setFloat = (ink, name, val: float) => {
    Log.debug("setFloat", ~data=(name, val))
    ink->summon->setVar(name, val)
  }

  let setInt = (ink, name, val: int) => {
    Log.debug("setInt", ~data=(name, val))
    ink->summon->setVar(name, val)
  }

  let setString = (ink, name, val: string) => {
    Log.debug("setString", ~data=(name, val))
    ink->summon->setVar(name, val)
  }

  module type ConfigHookDef = {
    let name: string

    type t
    let t_encode: Spice.encoder<t>
    let t_decode: Spice.decoder<t>

    let initialValue: t
  }

  module type Helpers = {
    type t
    let use: ink => (t, (t => t) => unit)
    let transfer: (ink, ink) => unit
  }

  module MakeHelpers = (Def: ConfigHookDef): (Helpers with type t = Def.t) => {
    type t = Def.t

    let transfer = inkEngine => {
      let value = switch inkEngine
      ->get(Def.name ++ "Config")
      ->Option.map(Js.Json.parseExn)
      ->Option.map(Def.t_decode) {
      | None => Def.initialValue
      | Some(Error(e)) => {
          Log.error("Transfer Error", ~data=(Def.name, e->ErrStack.fromSpice))
          Def.initialValue
        }
      | Some(Ok(x)) => x
      }

      inkEngine => {
        inkEngine->setString(Def.name ++ "Config", value->Def.t_encode->Js.Json.stringify)
      }
    }

    let use = inkEngine => {
      let (_, setTick) = React.useState(_ => 1)
      let tick = () => setTick(x => x + 1)

      let value = React.useMemo1(() => {
        switch inkEngine
        ->get(Def.name ++ "Config")
        ->Option.map(Js.Json.parseExn)
        ->Option.map(Def.t_decode) {
        | None => Def.initialValue
        | Some(Error(e)) => {
            e->ErrStack.fromSpice->Js.log
            Def.initialValue
          }
        | Some(Ok(x)) => x
        }
      }, [inkEngine->get(Def.name ++ "Config")])

      let setState = updater => {
        tick()
        let newValue = updater(value)
        inkEngine->setString(Def.name ++ "Config", newValue->Def.t_encode->Js.Json.stringify)
      }

      (value, setState)
    }
  }
}

let debug = inkEngine => {
  Js.log((
    "Ink.Debug",
    inkEngine->canContinue,
    inkEngine->getState->currentPathString,
    inkEngine->currentChoices,
    inkEngine->currentText,
    inkEngine->currentTags,
    inkEngine->currentWarnings,
    inkEngine->currentErrors,
  ))
}
