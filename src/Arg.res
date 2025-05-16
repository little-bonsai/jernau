module Config = {
  type x
  @module("arg") external run: x = "default"

  type t

  @get external count: x => t = "COUNT"
  let count = run->count
  let string_: t = %raw("String")
  let number: t = %raw("Number")
  let stringArray: t = %raw("[String]")
  let boolean: t = %raw("Boolean")
}

module Raw = {
  type options = {permissive: bool, argv: array<string>}
  type t = {
    @as("--help") help: Js.Nullable.t<bool>,
    @as("--verbose") verbose: Js.Nullable.t<int>,
    @as("--itterations") itterations: Js.Nullable.t<int>,
    @as("--seed") seed: Js.Nullable.t<int>,
    @as("--ink") ink: Js.Nullable.t<string>,
    @as("--validators") validators: Js.Nullable.t<string>,
    @as("--externals") externals: Js.Nullable.t<string>,
  }

  @module("arg") external run: (Js.Dict.t<Config.t>, options) => t = "default"
}

module Parsed = {
  type t = {
    help: option<bool>,
    verbose: option<int>,
    itterations: option<int>,
    seed: option<int>,
    validators: option<string>,
    ink: option<string>,
    externals: option<string>,
  }

  let make = (raw: Raw.t): t => {
    help: raw.help->Js.Nullable.toOption,
    verbose: raw.verbose->Js.Nullable.toOption,
    itterations: raw.itterations->Js.Nullable.toOption,
    seed: raw.seed->Js.Nullable.toOption,
    ink: raw.ink->Js.Nullable.toOption,
    validators: raw.validators->Js.Nullable.toOption,
    externals: raw.externals->Js.Nullable.toOption,
  }
}

let get = argv => {
  Raw.run(
    Js.Dict.fromArray([
      ("--help", Config.boolean),
      ("--verbose", Config.count),
      ("--itterations", Config.number),
      ("--seed", Config.number),
      ("--ink", Config.string_),
      ("--validators", Config.string_),
      ("--externals", Config.string_),
    ]),
    {permissive: true, argv},
  )->Parsed.make
}
