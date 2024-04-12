import * as Curry from "rescript/lib/es6/curry.js";
import * as Js_int from "rescript/lib/es6/js_int.js";
import * as Js_math from "rescript/lib/es6/js_math.js";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Caml_int32 from "rescript/lib/es6/caml_int32.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";

var squirrel3Raw = function (seed, n) {
  const n1 = 0xb5297a4d; //0b0110_1000_1110_0011_0001_1101_1010_0100
  const n2 = 0x68e31da4; //0b1011_0101_0010_1001_0111_1010_0100_1101
  const n3 = 0x1b56c4e9; //0b0001_1011_0101_0110_1100_0100_1110_1001
  n *= n1;
  n += seed;
  n ^= n >> 8;
  n += n2;
  n ^= n << 8;
  n *= n3;
  n ^= n >> 8;
  return n;
};

function hash(seedOpt, n) {
  var seed = seedOpt !== undefined ? seedOpt : 0;
  return squirrel3Raw(seed, n);
}

function hashArr(seedOpt, xs) {
  var seed = seedOpt !== undefined ? seedOpt : 0;
  var acc = seed;
  for (var i = 0, i_finish = xs.length; i < i_finish; ++i) {
    var x = xs[i];
    acc = squirrel3Raw(acc, x);
  }
  return acc;
}

function hashStr(seedOpt, s) {
  var seed = seedOpt !== undefined ? seedOpt : 0;
  return hashArr(
    seed,
    Array.from(s).map(function (__x) {
      return __x.codePointAt(0);
    }),
  );
}

var digest = squirrel3Raw;

var hash2Ints = squirrel3Raw;

function gen(seedOpt, param) {
  var seed = seedOpt !== undefined ? seedOpt : 0;
  var ittr = {
    contents: seed,
  };
  return function (param) {
    ittr.contents = (ittr.contents + 1) | 0;
    return hash(undefined, ittr.contents);
  };
}

var $$global = gen(Js_math.random_int(0, 65536), undefined);

function getIntRange(minOpt, maxOpt, rand) {
  var min = minOpt !== undefined ? minOpt : 0;
  var max = maxOpt !== undefined ? maxOpt : Js_int.max;
  var range = (max - min) | 0;
  if (range <= 1) {
    return min;
  }
  var divd = Caml_int32.div(Js_int.max, range);
  return (Caml_int32.div(rand, divd) + min) | 0;
}

function getFloat(rand) {
  return rand / Js_int.max;
}

function getFloatRange(minOpt, maxOpt, rand) {
  var min = minOpt !== undefined ? minOpt : 0.0;
  var max = maxOpt !== undefined ? maxOpt : 1.0;
  var range = max - min;
  return getFloat(rand) * range + min;
}

function getBool(rand) {
  return rand % 2 === 0;
}

function getFromArray(rand, xs) {
  var i = getIntRange(undefined, xs.length, rand);
  return Belt_Array.get(xs, i);
}

function getFromWeighted(rand, xs) {
  var total = 0;
  for (var i = 0, i_finish = xs.length; i < i_finish; ++i) {
    var match = xs[i];
    total = (total + match[1]) | 0;
  }
  var weightPosition = getIntRange(0, total, rand);
  var $$do = function (_weightPosition, _i) {
    while (true) {
      var i = _i;
      var weightPosition = _weightPosition;
      var match = xs[i];
      var weightPosition$1 = (weightPosition - match[1]) | 0;
      if (weightPosition$1 <= 0) {
        return match[0];
      }
      _i = (i + 1) | 0;
      _weightPosition = weightPosition$1;
      continue;
    }
  };
  if (xs.length === 0) {
    return;
  } else {
    return Caml_option.some($$do(weightPosition, 0));
  }
}

function shuffle(rand, xsIn) {
  var xs = Array.from(xsIn);
  var g = gen(rand, undefined);
  var length = xs.length;
  var swap = function (a, b) {
    var temp = xs[b];
    xs[b] = xs[a];
    xs[a] = temp;
  };
  for (var i = (length - 1) | 0; i >= 1; --i) {
    var j = getIntRange(undefined, i, Curry._1(g, undefined));
    swap(i, j);
  }
  return xs;
}

var Int;

export {
  Int,
  squirrel3Raw,
  hash,
  hashArr,
  hashStr,
  digest,
  hash2Ints,
  gen,
  $$global,
  getIntRange,
  getFloat,
  getFloatRange,
  getBool,
  getFromArray,
  getFromWeighted,
  shuffle,
};
/* global Not a pure module */
