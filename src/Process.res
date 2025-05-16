@val external arch: Js.Nullable.t<string> = "process.arch"
let arch = arch->Js.Nullable.toOption->Option.getOr("")

@val external platform: Js.Nullable.t<string> = "process.platform"
let platform = platform->Js.Nullable.toOption->Option.getOr("")

@val external argv: array<string> = "process.argv"
@val external cwd: unit => string = "process.cwd"
@val external exit: int => unit = "process.exit"

module Env = {
  @val external analUrl: Js.Nullable.t<string> = "process.env.ANAL_URL"
  @val external dateTime: Js.Nullable.t<string> = "process.env.DATE_TIME"
  @val external nodeEnv: Js.Nullable.t<string> = "process.env.NODE_ENV"
  @val external steamAppId: Js.Nullable.t<string> = "process.env.STEAM_APP_ID"
  @val external tag: Js.Nullable.t<string> = "process.env.MERCER_TAG"
  @val external scalewayS3Key: Js.Nullable.t<string> = "process.env.SCALEWAY_S3_KEY"
  @val external scalewayS3Secret: Js.Nullable.t<string> = "process.env.SCALEWAY_S3_SECRET"

  let analUrl = analUrl->Js.Nullable.toOption->Option.getOr("")
  let dateTime = dateTime->Js.Nullable.toOption->Option.getOr("")
  let nodeEnv = nodeEnv->Js.Nullable.toOption->Option.getOr("")
  let steamAppId = steamAppId->Js.Nullable.toOption->Option.getOr("")
  let tag = tag->Js.Nullable.toOption->Option.getOr("")
  let scalewayS3Key = scalewayS3Key->Js.Nullable.toOption->Option.getOr("")
  let scalewayS3Secret = scalewayS3Secret->Js.Nullable.toOption->Option.getOr("")
}
