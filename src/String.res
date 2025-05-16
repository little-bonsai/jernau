include RescriptCore.String

let slice = (~start=?, ~end=?, xs: string) => {
  let from = switch start {
  | Some(x) => x
  | None => 0
  }

  let to_ = switch end {
  | Some(x) => x
  | None => xs->length
  }

  xs->Js.String2.slice(~from, ~to_)
}

let toTitleCase = s => {
  s
  ->split(" ")
  ->Array.map(word =>
    word
    ->split("")
    ->Array.mapWithIndex((character, i) =>
      if i === 0 {
        character->toUpperCase
      } else {
        character->toLowerCase
      }
    )
    ->Array.join("")
  )
  ->Array.join(" ")
}

let toCamelCase = s =>
  s
  ->toTitleCase
  ->split("")
  ->Array.mapWithIndex((c, i) => i === 0 ? c->toLowerCase : c)
  ->Array.join("")

let toKebabCase: string => string = %raw(` x => x
    .trim()
    .replace(/[^ \-a-zA-Z0-9]/g, "")
    .replace(/([a-z])([A-Z])/g, (_, x, y) => x + "-" + y)
    .toLowerCase()
    .replace(/[\-\s]+/g, "-")`)
