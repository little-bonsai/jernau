type t =
  | Done
  | Timeout
  | Error(exn)
  | NotDone({currentPathString: string})
  | InvalidLine({currentPathString: string})
