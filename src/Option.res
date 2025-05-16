include RescriptCore.Option

let unwrap = x => getExn(x)

let orElse = (o, fn) => {
  switch o {
  | None => fn()
  | Some(x) => Some(x)
  }
}

let fromResult = r =>
  switch r {
  | Ok(o) => Some(o)
  | Error(_) => None
  }

let toResult = (o, e) =>
  switch o {
  | Some(o) => Ok(o)
  | None => Error(e())
  }

let flat = o =>
  switch o {
  | None => None
  | Some(None) => None
  | Some(Some(x)) => Some(x)
  }
