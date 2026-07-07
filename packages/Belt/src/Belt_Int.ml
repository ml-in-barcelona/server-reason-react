let toFloat = Stdlib.float_of_int
let fromFloat = Stdlib.int_of_float

(* JavaScript parseInt(input, 10) semantics via quickjs: skips leading
   whitespace and parses the longest decimal-digit prefix ("10px" is Some 10,
   "0x10" is Some 0, " 42 " is Some 42). None plays the role of JavaScript's
   NaN; values that do not fit in an OCaml int are also None instead of the
   lossy float JavaScript would return. *)
let fromString input = Quickjs.Global.parse_int ~radix:10 input
let toString = string_of_int
let ( + ) = Stdlib.( + )
let ( - ) = Stdlib.( - )
let ( * ) = Stdlib.( * )
let ( / ) = Stdlib.( / )
