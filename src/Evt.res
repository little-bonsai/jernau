type t =
  | Done
  | Error(exn)
  | NotDone({currentPathString: string})
  | InvalidLine({currentPathString: string})
