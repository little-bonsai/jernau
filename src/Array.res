include RescriptCore.Array

let keepMap = Belt.Array.keepMap
let zip = Belt.Array.zip

@new external make: int => array<unit> = "Array"
@send external flat: array<array<'t>> => array<'t> = "flat"
@send external fill: (array<'a>, 'b) => array<'b> = "fill"
@get_index @return(nullable) external get: (array<'a>, int) => option<'a> = ""
@get_index external getUnsafe: (array<'a>, int) => 'a = ""
@set_index external set: (array<'a>, int, 'a) => unit = ""

let makeFrom = x => [x]

module Uniq: {
  let uniq: array<'a> => array<'a>
} = {
  module Set = {
    type t<'a>

    @val external toArray: t<'a> => array<'a> = "Array.from"
    @new external fromArray: array<'a> => t<'a> = "Set"
  }

  let uniq = (xs: array<'a>): array<'a> => xs->Set.fromArray->Set.toArray
}
let uniq = Uniq.uniq

@val external clone: array<'a> => array<'a> = "Array.from"

let sortBy = (xs, fn) => xs->sort((l, r) => RescriptCore.Int.compare(fn(l), fn(r)))
let toSortedBy = (xs, fn) => xs->toSorted((l, r) => RescriptCore.Int.compare(fn(l), fn(r)))

let addIndexs = xs => xs->mapWithIndex((x, i) => (i, x))

let makeOfLength = n => {
  let acc = []
  for i in 0 to n - 1 {
    acc->push(i)->ignore
  }
  acc
}

let slice = (~start=?, ~end=?, xs: array<'a>) => {
  let start = switch start {
  | Some(x) => x
  | None => 0
  }

  let end = switch end {
  | Some(x) => x
  | None => xs->length
  }

  xs->slice(~start, ~end)
}

let smearChunks = (xs: array<'a>, n: int): array<array<'a>> => {
  let acc = []

  for i in 0 to xs->length - n {
    acc->push(xs->slice(~start=i, ~end=i + n))->ignore
  }

  acc
}

let segmentChunks = (~includeTail=true, xs: array<'a>, n: int): array<array<'a>> => {
  let acc = []
  let goto = xs->length / n

  let goto = if includeTail {
    goto
  } else {
    goto - 1
  }

  for i in 0 to goto {
    acc->push(xs->slice(~start=i * n, ~end=(i + 1) * n))->ignore
  }

  acc
}

let groupBy = (xs: array<'a>, fn: 'a => string): Js.Dict.t<array<'a>> => {
  let map: Dict.t<array<'a>> = Js.Dict.empty()

  xs->forEach(x => {
    let key = fn(x)
    let acc = map->Js.Dict.get(key)
    let acc = switch acc {
    | None => []
    | Some(vals) => vals
    }
    let acc = acc->concat([x])
    map->Js.Dict.set(key, acc)
  })

  map
}
