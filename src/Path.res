@module("node:path") external sep: string = "sep"
@module("node:path") @variadic external join: array<string> => string = "join"
@module("node:path") external relative: (string, string) => string = "relative"
