type t = float

let _NaN = Stdlib.Float.nan
let isNaN float = Stdlib.Float.is_nan float
let isFinite float = Stdlib.Float.is_finite float
let isInteger float = Stdlib.Float.is_finite float && Stdlib.Float.is_integer float

(* Number.prototype.toExponential(undefined) (ECMA-262 21.1.3.2): uses the
   number of digits necessary to uniquely specify the number. We take the
   shortest round-trip representation from Number::toString and rewrite it in
   exponential notation. *)
let exponential_of_shortest f =
  let s = Quickjs.Number.Prototype.to_string f in
  if s = "NaN" || s = "Infinity" || s = "-Infinity" then s
  else begin
    let sign, s =
      if Stdlib.String.length s > 0 && s.[0] = '-' then ("-", Stdlib.String.sub s 1 (Stdlib.String.length s - 1))
      else ("", s)
    in
    if Stdlib.String.contains s 'e' then sign ^ s
    else begin
      let int_part, frac_part =
        match Stdlib.String.index_opt s '.' with
        | Some dot -> (Stdlib.String.sub s 0 dot, Stdlib.String.sub s (dot + 1) (Stdlib.String.length s - dot - 1))
        | None -> (s, "")
      in
      let digits = int_part ^ frac_part in
      (* Position of the first significant digit determines the exponent. *)
      let first_significant = ref 0 in
      while !first_significant < Stdlib.String.length digits && digits.[!first_significant] = '0' do
        incr first_significant
      done;
      if !first_significant = Stdlib.String.length digits then sign ^ "0e+0"
      else begin
        let exponent = Stdlib.String.length int_part - 1 - !first_significant in
        let significant =
          Stdlib.String.sub digits !first_significant (Stdlib.String.length digits - !first_significant)
        in
        let significant =
          (* strip trailing zeros *)
          let last = ref (Stdlib.String.length significant) in
          while !last > 1 && significant.[!last - 1] = '0' do
            decr last
          done;
          Stdlib.String.sub significant 0 !last
        in
        let mantissa =
          if Stdlib.String.length significant = 1 then significant
          else
            Stdlib.String.sub significant 0 1 ^ "."
            ^ Stdlib.String.sub significant 1 (Stdlib.String.length significant - 1)
        in
        Printf.sprintf "%s%se%s%d" sign mantissa (if exponent >= 0 then "+" else "-") (Stdlib.abs exponent)
      end
    end
  end

let toExponential ?digits f =
  match digits with
  | None -> exponential_of_shortest f
  | Some d ->
      if d < 0 || d > 100 then raise (Invalid_argument "toExponential() digits argument must be between 0 and 100")
      else Quickjs.Number.Prototype.to_exponential d f

let toFixed ?(digits = 0) f =
  if digits < 0 || digits > 100 then raise (Failure "toFixed() digits argument must be between 0 and 100")
    (* Number.prototype.toFixed (ECMA-262 21.1.3.3): values >= 1e21 fall back
       to Number::toString (exponential form). *)
  else if Stdlib.abs_float f >= 1e21 then Quickjs.Number.Prototype.to_string f
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
