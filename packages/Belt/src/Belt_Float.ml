let toInt = Stdlib.int_of_float
let fromInt = Stdlib.float_of_int

(* JavaScript parseFloat semantics via quickjs: skips leading whitespace and
   parses the longest numeric prefix ("3.5px" is Some 3.5, "0x10" is Some 0.).
   None plays the role of JavaScript's NaN. *)
let fromString i = Quickjs.Global.parse_float i

(* JavaScript String(number) semantics via quickjs: shortest round-trip
   representation, so 0.1 +. 0.2 is "0.30000000000000004", nan is "NaN" and
   infinity is "Infinity". *)
let toString value = Quickjs.Number.Prototype.to_string value
let ( + ) = Stdlib.( +. )
let ( - ) = Stdlib.( -. )
let ( * ) = Stdlib.( *. )
let ( / ) = Stdlib.( /. )
