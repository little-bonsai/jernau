type t<'a>

type output<'a> = {
  done: bool,
  value: Js.Nullable.t<'a>,
}

@send external next: t<'a> => output<'a> = "next"
@send external toArray: t<'a> => array<'a> = "toArray"
