type t =
  | Text(string)
  | Options({choices: array<string>, chosen: int})

let print = (x): string =>
  switch x {
  | Text(x) => x->String.trim
  | Options({choices, chosen}) =>
    choices
    ->Array.mapWithIndex((x, i) => {
      if i === chosen {
        Chalk.green([i->Int.toString->String.padStart(4, " "), "->", x])
      } else {
        Chalk.blue([i->Int.toString->String.padStart(4, " "), "  ", x])
      }
    })
    ->Array.join("\n")
  }
