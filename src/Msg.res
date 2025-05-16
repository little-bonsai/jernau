type t =
  | Run({
      inkPath: string,
      validatorsPath: string,
      externalsPath: option<string>,
      seed: int,
      maxBufferLength: option<int>,
    })
