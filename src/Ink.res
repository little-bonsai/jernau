type inkEngine

module Path = {
  type t

  @send external toString: t => string = "toString"
}

module Pointer = {
  type t

  @return(nullable) @get external path: t => option<Path.t> = "node:path"
}

module List = {
  module Item = {
    type t

    external cast: 'a => t = "%identity"

    @get external getOriginName: t => string = "originName"
    @get external getItemName: t => string = "itemName"
  }

  module ItemKeyValue = {
    type t = {
      @as("Key") key: Item.t,
      @as("Value") value: int,
    }

    let make = (key, value) => {key, value}
  }

  module Origin = {
    type t

    @get external name: t => string = "_name"

    @get external __itemNameToValue: t => Map.t<string, int> = "_itemNameToValues"
    @get external __items: t => Map.t<string, int> = "items"

    let items = (x): array<(Item.t, int)> =>
      x
      ->__items
      ->Map.entries
      ->Iterator.toArray
      ->Array.map(((key, val)) => (Js.Json.parseExn(key)->Item.cast, val))
  }

  module Instance = {
    type t

    @get external all: t => t = "all"
    @get external count: t => int = "count"
    @get external inverse: t => t = "inverse"
    @get external maxItem: t => ItemKeyValue.t = "maxItem"
    @get external minItem: t => ItemKeyValue.t = "minItem"
    @get external orderedItems: t => array<ItemKeyValue.t> = "orderedItems"
    @get external values: t => Iterator.t<int> = "values"
    @get external keys: t => Iterator.t<string> = "keys"
    @get external origins: t => array<Origin.t> = "origins"
    @send external containsItemNamed: (t, string) => bool = "ContainsItemNamed"
    @send external intersect: (t, t) => t = "Intersect"
    @send external addNamedItem: (t, string) => unit = "AddItem"
    @send external addItem: (t, Item.t) => unit = "AddItem"
    @send external removeItem: (t, Item.t) => unit = "Remove"
    external from_unsafe: 'a => t = "%identity"
    external into_unsafe: t => 'a = "%identity"

    /*
		There are other ways to create lists, if needed:
			constructor();
			constructor(otherList: InkList);
			constructor(singleOriginListName: string, originStory: Story);
			constructor(singleElement: KeyValuePair<InkListItem, number>);
		*/
    @new @module("inkjs") external makeFromItem: ItemKeyValue.t => t = "InkList"
    @new @module("inkjs") external makeFromName: (string, inkEngine) => t = "InkList"
  }

  module TryGet = {
    type t<'a> = {exists: bool, result: 'a}

    let toOption = x => x.exists ? Some(x.result) : None
  }

  module Definition = {
    type t

    @get external getName: t => string = "name"
    @send external tryGetItemWithValue: (t, int) => TryGet.t<Item.t> = "TryGetItemWithValue"
    @get external itemNamesToValues: t => Map.t<string, int> = "_itemNameToValues"
  }

  module Definitions = {
    type t

    @get external lists: t => array<Definition.t> = "lists"
    @get external listsMap: t => Map.t<string, Definition.t> = "_lists"
  }
}

module Variable = {
  type t

  type typed = Bool(bool) | Float(float) | String(string) | List(List.Instance.t) | Null

  @scope("variablesState") @get_index external get: (inkEngine, string) => t = ""
  @scope("variablesState") @set_index external set: (inkEngine, string, t) => unit = ""

  external fromBool: bool => t = "%identity"
  external fromFloat: float => t = "%identity"
  external fromInt: int => t = "%identity"
  external fromString: string => t = "%identity"
  external fromNull: unit => t = "%identity"
  external fromList: List.Instance.t => t = "%identity"

  external asBool_unsafe: t => bool = "%identity"
  external asFloat_unsafe: t => float = "%identity"
  external asInt_unsafe: t => int = "%identity"
  external asString_unsafe: t => string = "%identity"
  external asList_unsafe: t => List.Instance.t = "%identity"
  external asPath_unsafe: t => Path.t = "%identity"
  external asSomethingVeryUnsafe_unsafe: t => 'a = "%identity"

  let toTyped = (var: t): typed => {
    switch var->Js.Types.classify {
    | JSFalse => Bool(false)
    | JSTrue => Bool(true)
    | JSNull => Null
    | JSUndefined => Null
    | JSNumber(f) => Float(f)
    | JSString(s) => String(s)
    | JSObject(l) => List(List.Instance.from_unsafe(l))
    | _ => Null
    }
  }

  let fromTyped = (var: typed): t => {
    switch var {
    | Bool(x) => x->fromBool
    | Float(x) => x->fromFloat
    | String(x) => x->fromString
    | Null => fromNull()
    | List(x) => x->fromList
    }
  }

  let toBool = x =>
    switch toTyped(x) {
    | Bool(x) => Some(x)
    | _ => None
    }

  let toFloat = x =>
    switch toTyped(x) {
    | Float(x) => Some(x)
    | _ => None
    }

  let toInt = x =>
    switch toTyped(x) {
    | Float(x) => Some(x->Float.toInt)
    | _ => None
    }

  let toString = x =>
    switch toTyped(x) {
    | String(x) => Some(x)
    | _ => None
    }

  let toList = x =>
    switch toTyped(x) {
    | List(x) => Some(x)
    | _ => None
    }
}

module State = {
  type t
  @return(nullable) @get external previousPointer: t => option<Pointer.t> = "previousPointer"
  @return(nullable) @get external currentPathString: t => option<string> = "currentPathString"
  @get external currentTurnIndex: t => int = "currentTurnIndex"
  @set external setStorySeed: (t, int) => unit = "storySeed"
  @send external parse: (t, string) => unit = "LoadJson"
  @send external serialize: t => string = "ToJson"
}

@unboxed type rawTag = Tag(string)

module Choice = {
  @unboxed type index = ChoiceIndex(int)
  external indexToInt: index => int = "%identity"
  type t

  @get external text: t => string = "text"
  @get external index: t => index = "index"
  @get external sourcePath: t => string = "sourcePath"
  @get external targetPath: t => Path.t = "targetPath"
  @return(nullable) @get external tags: t => option<array<rawTag>> = "tags"
  let tags = x => x->tags->Option.getOr([])
}

type t = inkEngine

@new @module("inkjs") external make: Js.Json.t => t = "Story"

@get external canContinue: t => bool = "canContinue"
@get external currentChoices: t => array<Choice.t> = "currentChoices"
@get external currentDebugMetadata: t => unit = "currentDebugMetadata"
@get external currentErrors: t => unit = "currentErrors"
@get external currentFlowName: t => string = "currentFlowName"
@get external currentFlowIsDefaultFlow: t => bool = "currentFlowIsDefaultFlow"
@get external currentTags: t => array<rawTag> = "currentTags"
@get external currentText: t => string = "currentText"
@get external currentWarnings: t => unit = "currentWarnings"
@get external getState: t => State.t = "state"
@get external globalTags: t => unit = "globalTags"
@get external hasError: t => bool = "hasError"
@get external hasWarning: t => bool = "hasWarning"
@get external listDefinitions: t => List.Definitions.t = "listDefinitions"
@get external mainContentContainer: t => unit = "mainContentContainer"
@send
external bindExternalFunction: (t, ~name: string, ~fn: 'a, ~lookaheadSafe: bool) => unit =
  "BindExternalFunction"
@send external unbindExternalFunction: (t, ~name: string) => unit = "UnbindExternalFunction"
@send external chooseChoiceIndex: (t, Choice.index) => unit = "ChooseChoiceIndex"
@send external choosePathString: (t, string) => unit = "ChoosePathString"
@send
external choosePathStringWithArguments: (t, string, @as(`true`) _, array<Variable.t>) => unit =
  "ChoosePathString"
@send external choosePath: (t, Path.t) => unit = "ChoosePath"
@send external continue: t => unit = "Continue"
@send external continueAsync: t => unit = "ContinueAsync"
@send external continueInternal: t => unit = "ContinueInternal"
@send external continueMaximally: t => unit = "ContinueMaximally"
@send external continueSingleStep: t => bool = "ContinueSingleStep"
@send external observeVariable: (t, string, (string, 'a) => unit) => unit = "ObserveVariable"
@send external reset: t => unit = "ResetState"
@new @module("inkjs")
external makeListInstanceFromListOriginName: (string, t) => List.Instance.t = "InkList"

@send external switchFlow: (t, string) => unit = "SwitchFlow"
@send external removeFlow: (t, string) => unit = "RemoveFlow"
@get external aliveFlowNames: t => array<string> = "aliveFlowNames"
@set external allowExternalFunctionFallbacks: (t, bool) => unit = "allowExternalFunctionFallbacks"

type fullyEvaluatedFunction = {output: string, returned: Variable.t}
@send
external evaluateFunction: (t, string, array<Variable.t>, @as(json`false`) _) => Variable.t =
  "EvaluateFunction"
@send
external evaluateFunctionFully: (
  t,
  string,
  array<Variable.t>,
  @as(json`true`) _,
) => fullyEvaluatedFunction = "EvaluateFunction"

/* Because some lines will only contain direction, but ink thinks they count as dialogue, I have to fully
 drive the Ink Engine and proxy the output. Providing augmenting meta data is not enough */
