type t
@val @module("chalk") external instance: t = "default"

@variadic @send external blue: (t, array<string>) => string = "blue"
@variadic @send external cyan: (t, array<string>) => string = "cyan"
@variadic @send external green: (t, array<string>) => string = "green"
@variadic @send external red: (t, array<string>) => string = "red"
let blue = blue(instance, _)
let cyan = cyan(instance, _)
let green = green(instance, _)
let red = red(instance, _)
