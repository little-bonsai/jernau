type t<'k, 'v>

@new external make: unit => t<'k, 'v> = "Map"
@new external makeFromArray: array<('k, 'v)> => t<'k, 'v> = "Map"
@send external add: (t<'k, 'v>, 'k, 'v) => unit = "set"
@send external has: (t<'k, 'v>, 'k) => bool = "has"
@send @return(nullable) external get: (t<'k, 'v>, 'k) => option<'v> = "get"
@send external remove: (t<'k, 'v>, 'k) => bool = "delete"

@send external keys: t<'k, 'v> => Iterator.t<'k> = "keys"
@send external values: t<'k, 'v> => Iterator.t<'v> = "values"
@send external entries: t<'k, 'v> => Iterator.t<('k, 'v)> = "entries"

@send external forEach: (t<'k, 'v>, ('k, 'v) => unit) => unit = "forEach"
@val external toArray: t<'k, 'v> => array<('k, 'v)> = "Array.from"
