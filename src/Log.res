@spice
type logLevels = Lbz.Logger.logLevels

include Lbz.Logger.MakeScope(
  Lbz.Logger,
  {
    let scope = "mercer"
  },
)

let useWatch = (~level=#debug, msg, data) => {
  React.useEffect1(() => {
    tap(~msg, ~level, data)->ignore
    None
  }, [data])
}

module BuiltInConsole = {
  external defaultifyData: 'a => string = "%identity"

  @val @variadic external debug: array<string> => unit = "console.debug"
  @val @variadic external info: array<string> => unit = "console.info"
  @val @variadic external log: array<string> => unit = "console.log"
  @val @variadic external warn: array<string> => unit = "console.warn"
  @val @variadic external error: array<string> => unit = "console.error"

  let consoleLogDriver = (
    ~level: Lbz.Logger.logLevels,
    ~scope: string,
    ~msg: string,
    ~data: option<'a>,
  ) => {
    let args = [scope, msg]

    switch data {
    | Some(data) => args->Js.Array2.push(defaultifyData(data))->ignore
    | None => ()
    }

    switch level {
    | #debug => debug(args)
    | #info => info(args)
    | #log => log(args)
    | #warn => warn(args)
    | #error => error(args)
    | #event => error(args)
    }
  }

  let bind = () => Lbz.Logger.registerDriver(consoleLogDriver)
}

module LogFile = {
  type writeStream
  type writeStreamOpts = {flags: string}
  @module("fs")
  external createWriteStream: (string, writeStreamOpts) => writeStream = "createWriteStream"
  @send external writeToStream: (writeStream, string) => unit = "write"

  let fileLogDriver = path => {
    log("start log file", ~data=path)

    Lbz.Fs.Node.getDirname(path)
    ->Lbz.Fs.mkdir
    ->Promise.then(_ => {
      let writeStream = createWriteStream(path, {flags: "a"})

      let driver = (
        ~level: Lbz.Logger.logLevels,
        ~scope: string,
        ~msg: string,
        ~data: option<'a>,
      ) => {
        let lines = [Js.Date.make()->Js.Date.toISOString, (level :> string), scope, msg]

        switch data {
        | Some(data) =>
          switch data->Js.Json.stringifyAny {
          | Some(data) => lines->Js.Array2.push(data)->ignore
          | None => ()
          }
        | None => ()
        }

        writeStream->writeToStream(lines->Js.Array2.joinWith("\t") ++ "\n")
      }

      Promise.resolve(driver)
    })
  }

  let bind = path =>
    fileLogDriver(path)->Promise.then(driver => {
      Lbz.Logger.registerDriver(driver)
      Promise.resolve()
    })
}
