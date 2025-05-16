@unboxed
type noise = Val(int)
external unwrap: noise => int = "%identity"

let squirrel3Raw: (int, int) => int = %raw(`
	  function(seed, n){
		  const n1 = 0xb5297a4d //0b0110_1000_1110_0011_0001_1101_1010_0100
		  const n2 = 0x68e31da4 //0b1011_0101_0010_1001_0111_1010_0100_1101
		  const n3 = 0x1b56c4e9 //0b0001_1011_0101_0110_1100_0100_1110_1001
		  n *= n1 
		  n += seed 
		  n ^= n >> 8 
		  n += n2 
		  n ^= n << 8 
		  n *= n3 
		  n ^= n >> 8 
		  return n 
	  }
  `)

let hash = (~seed: int=0, n: int): noise => Val(squirrel3Raw(seed, n))
let hashArr = (~seed: int=0, xs: array<int>): noise => {
  let acc = ref(seed)

  for i in 0 to xs->Array.length - 1 {
    let x = xs->Array.getUnsafe(i)
    acc := squirrel3Raw(acc.contents, x)
  }

  Val(acc.contents)
}

@send external codePointAt: (string, int) => int = "codePointAt"
@val external arrayFrom: string => array<string> = "Array.from"

let hashStr = (~seed: int=0, s: string): noise => {
  s->arrayFrom->Array.map(codePointAt(_, 0))->hashArr(~seed)
}

let digest = (Val(prev), new) => {
  Val(squirrel3Raw(prev, new))
}

let hash2Ints = (a, b) => Val(a)->digest(b)->unwrap

let gen = (~seed: int=0, ()) => {
  let ittr = ref(seed)

  () => {
    ittr := ittr.contents + 1
    hash(ittr.contents)
  }
}

let global = gen(~seed=Js.Math.random_int(0, 65536), ())

external getInt: noise => int = "%identity"
let getIntRange = (~min: int=0, ~max: int=Int.maxValue, rand: noise): int => {
  let range = max - min
  if range > 1 {
    let divd = Int.maxValue / range
    let val = getInt(rand) / divd + min
    val
  } else {
    min
  }
}

let getFloat = (Val(rand): noise): float => Int.toFloat(rand) /. Int.toFloat(Int.maxValue)
let getFloatRange = (~min: float=0.0, ~max: float=1.0, rand: noise): float => {
  let range = max -. min
  let val = getFloat(rand) *. range +. min
  val
}

let getBool = (rand): bool => rand->getInt->(mod(_, 2))->(x => x === 0)

let getFromArray = (rand: noise, xs: array<'a>): option<'a> => {
  let i = rand->getIntRange(~max=xs->Belt.Array.length)
  xs->Belt.Array.get(i)
}

let getFromWeighted = (rand: noise, xs: array<('a, int)>): option<'a> => {
  let total = ref(0)

  for i in 0 to xs->Array.length - 1 {
    let (_, weight) = xs->Array.getUnsafe(i)
    total := total.contents + weight
  }

  let weightPosition = rand->getIntRange(~min=0, ~max=total.contents)

  let rec do = (weightPosition, i) => {
    let (val, weight) = xs->Array.getUnsafe(i)
    let weightPosition = weightPosition - weight

    if weightPosition <= 0 {
      val
    } else {
      do(weightPosition, i + 1)
    }
  }

  if xs->Array.length === 0 {
    None
  } else {
    Some(do(weightPosition, 0))
  }
}

@val external arrayClone: array<'a> => array<'a> = "Array.from"
let shuffle = (rand: noise, xsIn: array<'a>): array<'a> => {
  let xs = xsIn->arrayClone
  let g = gen(~seed=rand->getInt, ())

  let length = xs->Array.length
  let swap = (a, b) => {
    let temp = xs->Array.getUnsafe(b)
    xs->Array.setUnsafe(b, xs->Array.getUnsafe(a))
    xs->Array.setUnsafe(a, temp)
  }

  for i in length - 1 downto 1 {
    let j = g()->getIntRange(~max=i)
    swap(i, j)
  }

  xs
}

let obsfucate = (~seed=0, str: string) => {
  let rec do = (chars: list<string>, hash) => {
    switch chars {
    | list{} => list{}
    | list{head, ...tail} =>
      if Js.Re.test_(%re(`/\w/`), head) {
        let isUpper = head->String.toUpperCase === head

        let head = head->String.toLowerCase
        let hash = hash->digest(head->codePointAt(0))
        let head = hash->getIntRange(~min=97, ~max=122)->String.fromCharCode

        let head = if isUpper {
          head->String.toUpperCase
        } else {
          head
        }

        list{head, ...do(tail, hash)}
      } else {
        list{head, ...do(tail, hash)}
      }
    }
  }

  str
  ->String.split("")
  ->RescriptCore.List.fromArray
  ->do(Val(seed))
  ->RescriptCore.List.toArray
  ->Array.join("")
}
