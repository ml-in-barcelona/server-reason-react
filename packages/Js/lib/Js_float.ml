type t = float

let _NaN = Stdlib.Float.nan
let isNaN float = Stdlib.Float.is_nan float
let isFinite float = Stdlib.Float.is_finite float
let isInteger float = Stdlib.Float.is_finite float && Stdlib.Float.is_integer float

let toExponential ?digits f =
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 0 || d > 100 then raise (Invalid_argument "toExponential() digits argument must be between 0 and 100")
      else Quickjs.Number.Prototype.to_exponential d f

let toFixed ?(digits = 0) f =
  if digits < 0 || digits > 100 then raise (Failure "toFixed() digits argument must be between 0 and 100")
  else Quickjs.Number.Prototype.to_fixed digits f

let toPrecision ?digits f =
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 1 || d > 100 then raise (Invalid_argument "toPrecision() digits argument must be between 1 and 100")
      else Quickjs.Number.Prototype.to_precision d f

let toString ?radix f =
  match radix with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some r ->
      if r < 2 || r > 36 then raise (Invalid_argument "toString() radix must be between 2 and 36")
      else Quickjs.Number.Prototype.to_radix r f

(* Whether [str] contains only JavaScript whitespace. Recognizes the ASCII
   whitespace characters plus the UTF-8 encodings of U+00A0 (no-break space)
   and U+FEFF (BOM). *)
let is_js_whitespace_only str =
  let len = String.length str in
  let rec loop i =
    if i >= len then true
    else
      match String.get str i with
      | '\x09' | '\x0A' | '\x0B' | '\x0C' | '\x0D' | '\x20' -> loop (i + 1)
      | '\xC2' when i + 1 < len && String.get str (i + 1) = '\xA0' -> loop (i + 2)
      | '\xEF' when i + 2 < len && String.get str (i + 1) = '\xBB' && String.get str (i + 2) = '\xBF' -> loop (i + 3)
      | _ -> false
  in
  loop 0

(* JavaScript Number(string) semantics (matching Melange's Js.Float.fromString,
   which is [Number]): the whole string, after trimming whitespace, must be a
   numeric literal. Empty or whitespace-only strings convert to 0.; anything
   that fails to parse is NaN. Accepts 0x/0b/0o prefixes and
   "Infinity"/"+Infinity"/"-Infinity"; rejects trailing garbage ("3.5px" is
   NaN, unlike parseFloat) and underscore separators ("1_0" is NaN).

   quickjs itself skips leading JavaScript whitespace (full Unicode); the
   trailing whitespace check only recognizes ASCII whitespace, U+00A0 and
   U+FEFF. Residual divergence: other Unicode whitespace (e.g. U+2028 or
   U+3000) in trailing position yields NaN where JavaScript returns the
   number. *)
let fromString str =
  match Quickjs.Global.parse_float_partial ~options:Quickjs.Global.js_number_options str with
  | Some (value, rest) when is_js_whitespace_only rest -> value
  | Some _ -> _NaN
  | None -> if is_js_whitespace_only str then 0. else _NaN
