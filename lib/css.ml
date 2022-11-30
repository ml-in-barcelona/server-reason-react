include Bs_css.Properties
include Bs_css.Colors

module Hash = struct
  (* This monstruosity runs a few bitwise operations as Int32 while the rest
     of the algorithm is on Int64. *)
  module I32 = struct
    let ( << ) a b = Int32.shift_left (Int64.to_int32 a) b |> Int64.of_int32

    let ( * ) a b =
      Int32.mul (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32

    let ( >>> ) a b = Int32.shift_right (Int64.to_int32 a) b |> Int64.of_int32

    let ( ++ ) a b =
      Int32.add (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32

    let ( ^ ) a b =
      Int32.logxor (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32
  end

  let ( << ) = Int64.shift_left
  let ( & ) = Int64.logand
  let ( ||| ) = Int64.logor
  let ( * ) = Int64.mul
  let ( >>> ) = Int64.shift_right
  let ( ++ ) = Int64.add
  let ( ^ ) = Int64.logxor

  (*
    This hashing is a rewrite of @emotion/hash. What's below it's an ongoing effort to match the hashing function, currently not very precise. It's currenlty
    a big WIP and that's why it's full of prints and comments.

    Reference: https://github.com/emotion-js/emotion/blob/main/packages/hash/src/index.js
  *)
  let make (str : string) =
    (* Initialize the hash *)
    let len = str |> String.length |> Int64.of_int in
    let h = ref (Int64.mul len len) in

    (* Mix 4 bytes at a time into the hash *)
    let k = ref Int64.zero in
    let i = ref 0 in
    let len = ref (String.length str) in

    let get_int64_char str i = String.get str i |> Char.code |> Int64.of_int in

    while !len >= 4 do
      let first = get_int64_char str !i & 255L in
      let second = (get_int64_char str (!i + 1) & 255L) << 8 in
      let third = (get_int64_char str (!i + 2) & 255L) << 16 in
      let forth = (get_int64_char str (!i + 3) & 255L) << 24 in
      k := first ||| (second ||| (third ||| forth));

      (* print_endline (Int64.to_string first); *)
      (* print_endline (Int64.to_string second); *)
      (* print_endline (Int64.to_string third); *)
      (* print_endline (Int64.to_string forth); *)
      (* print_endline "--"; *)
      let k_one = !k & 65535L in
      (* print_endline (Int64.to_string k_one); *)
      (* print_endline (Int64.to_string (k_one * 1540483477L)); *)
      let k_pre_16 = I32.( * ) (!k >>> 16) 59797L in
      (* print_endline (Int64.to_string k_pre_16); *)
      let k_16 = I32.( << ) k_pre_16 16 in
      (* print_endline (Int64.to_string k_16); *)
      k := (k_one * 1540483477L) ++ k_16;

      (* print_endline (Int64.to_string !k); *)

      (* k ^= k >>> 24; *)
      (* k ^= /* k >>> r: */ k >>> 24; *)
      k := I32.( ^ ) !k (I32.( >>> ) !k 24);

      (* print_endline (Int64.to_string !k); *)
      (* print_endline "--"; *)
      let first_h =
        ((!k & 65535L) * 1540483477L)
        ++ I32.( << ) (I32.( >>> ) !k 16 * 59797L) 16
      in
      let second_h =
        ((!h & 65535L) * 1540483477L)
        ++ I32.( << ) (I32.( >>> ) !h 16 * 59797L) 16
      in

      h := I32.( ^ ) first_h second_h;
      (* print_endline
         (Int64.to_string
            (I32.( << ) (I32.( >>> ) !k 16 * 59797L) 16)) *)
      (* print_endline (Int64.to_string ((!h & 65535L) * 1540483477L)); *)
      (* print_endline (Int64.to_string !h) *)
      len := !len - 4;
      i := !i + 1
    done;

    (* print_endline (Int64.to_string !h); *)

    (* Handle the last few bytes of the input array *)
    (* (h :=
       match !len with
       | 3 -> !h ^ I32.( << ) (get_int64_char str (!i + 2) & 255L) 16
       | 2 -> !h ^ (get_int64_char str (!i + 1) & 255L) << 8
       | 1 ->
           h := I32.( ^ ) !h (get_int64_char str !i & 255L);
           print_endline (Int64.to_string !h);
           print_endline (Int64.to_string (Int64.shift_right !h 16));
           ((!h & 65535L) * 1540483477L) ++ ((!h >>> 16) * 59797L << 16)
       | _ -> !h); *)

    (* Do a few final mixes of the hash to ensure the last few
       * bytes are well-incorporated. *)

    (* h ^= h >>> 13;
       h =
         (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16);
    *)

    (* Do a few final mixes of the hash to ensure the last few *)
    (* bytes are well-incorporated. *)
    (* print_endline (Int64.to_string (!h >>> 13)); *)
    h := !h ^ I32.( >>> ) !h 13;
    h :=
      I32.( ++ )
        (I32.( * ) (!h & 65535L) 1540483477L)
        (I32.( * ) (!h >>> 16) (59797L << 16));
    h := !h ^ I32.( >>> ) !h 15;

    (* turn to base 36 *)
    (* let result = ((h ^ (h >>> 15)) >>> 0).toString(36); *)
    !h |> Int64.to_string |> String.cat "css-"
end

let rec rule_to_string accumulator rule =
  let open Bs_css.Rule in
  let next_rule =
    match rule with
    | Declaration (property, value) -> Printf.sprintf "%s: %s" property value
    | Selector (selector, rules) ->
        Printf.sprintf ".%s { %s }" selector (to_string rules)
    | Pseudoclass (pseduoclass, rules) ->
        Printf.sprintf ":%s { %s }" pseduoclass (to_string rules)
    | PseudoclassParam (pseudoclass, param, rules) ->
        Printf.sprintf ":%s ( %s ) %s" pseudoclass param (to_string rules)
  in
  accumulator ^ next_rule ^ "; "

and to_string rules = rules |> List.fold_left rule_to_string "" |> String.trim

let render_declaration rule =
  match rule with
  | Bs_css.Rule.Declaration (property, value) ->
      Some (Printf.sprintf "%s: %s;" property value)
  | _ -> None

let is_media_query selector = String.contains selector '@'

let replace_all input output =
  Str.global_replace (Str.regexp_string input) output

let replace_first input output =
  Str.replace_first (Str.regexp_string input) output

let remove_first_ampersand selector =
  if String.starts_with ~prefix:"&" selector then replace_first "&" "" selector
  else selector

let resolve_ampersand hash selector = replace_all "&" ("." ^ hash) selector

let make_prelude hash selector =
  let new_selector =
    selector |> remove_first_ampersand |> String.trim |> resolve_ampersand hash
  in
  Printf.sprintf ".%s %s" hash new_selector

let render_selectors hash rule =
  match rule with
  | Bs_css.Rule.Selector (selector, rules) when is_media_query selector ->
      Some (Printf.sprintf "%s { .%s { %s } }" selector hash (to_string rules))
  | Bs_css.Rule.Selector (selector, rules) ->
      let prelude = make_prelude hash selector in
      Some (Printf.sprintf "%s { %s }" prelude (to_string rules))
  | Pseudoclass (pseduoclass, rules) ->
      Some (Printf.sprintf ".%s:%s { %s }" hash pseduoclass (to_string rules))
  | PseudoclassParam (pseudoclass, param, rules) ->
      Some
        (Printf.sprintf ".%s:%s ( %s ) %s" hash pseudoclass param
           (to_string rules))
  | _ -> None

let rec rule_to_debug nesting accumulator rule =
  let open Bs_css.Rule in
  let next_rule =
    match rule with
    | Declaration (property, value) ->
        Printf.sprintf "Declaration (\"%s\", \"%s\")" property value
    | Selector (selector, rules) ->
        Printf.sprintf "Selector (\"%s\", %s)" selector
          (to_debug (nesting + 1) rules)
    | Pseudoclass (pseduoclass, rules) ->
        Printf.sprintf "Pseudoclass (\"%s\", %s)" pseduoclass
          (to_debug (nesting + 1) rules)
    | PseudoclassParam (pseudoclass, param, rules) ->
        Printf.sprintf "PseudoclassParam (\"%s\", \"%s\", %s)" pseudoclass param
          (to_debug (nesting + 1) rules)
  in
  let space = if nesting > 0 then String.make (nesting * 2) ' ' else "" in
  accumulator ^ Printf.sprintf "\n%s" space ^ next_rule

and to_debug nesting rules =
  rules |> List.fold_left (rule_to_debug nesting) "" |> String.trim

let print_rules rules =
  rules |> List.iter (fun rule -> print_endline (to_debug 0 [ rule ]))

let rec unnest ~prefix =
  let open Bs_css.Rule in
  List.partition_map (function
    | Selector (title, selector_rules) ->
        let new_prelude = prefix ^ title in
        let content, tail = unnest ~prefix:(new_prelude ^ " ") selector_rules in
        Right (Selector (new_prelude, content) :: List.flatten tail)
    | Declaration _ as rule -> Left rule
    | _ as rule -> Left rule)

let unnest_selectors rules =
  rules
  |> List.map (fun rule ->
         let declarations, selectors = unnest ~prefix:"" [ rule ] in
         List.flatten (declarations :: selectors))
  |> List.flatten |> List.rev

let rec nested_rule_to_string hash rules =
  (* TODO: Refactor with partition or partition_map. List.filter_map is error prone.
     Selectors might need to respect the order of definition, and this breaks the order *)
  let list_of_rules = rules |> unnest_selectors |> List.rev in
  let declarations =
    list_of_rules |> List.filter_map render_declaration |> String.concat " "
    |> fun all -> Printf.sprintf ".%s { %s }" hash all
  in
  let selectors =
    list_of_rules
    |> List.filter_map (render_selectors hash)
    |> String.concat " "
  in
  Printf.sprintf "%s %s" declarations selectors

and nested_to_string hash rules =
  rules |> nested_rule_to_string hash |> String.trim

let cache = ref (Hashtbl.create 1000)
let _get hash = Hashtbl.find cache.contents hash
let flush () = Hashtbl.clear cache.contents

let push hash (styles : Bs_css.Rule.t list) =
  Hashtbl.add cache.contents hash styles

let style (styles : Bs_css.Rule.t list) =
  let hash = Hash.make (to_string styles) in
  push hash styles;
  hash

let render_style_tag () =
  Hashtbl.fold
    (fun hash rules accumulator ->
      let rules = nested_to_string hash rules in
      Printf.sprintf "%s %s" accumulator rules)
    cache.contents ""
  |> String.trim

(* let keyframes name rules =
   let rules =
     rules
     |> List.map (fun (percentage, rule) ->
            let percentage = percentage |> string_of_float |> String.trim in
            Printf.sprintf "%s%% { %s }" percentage (to_string rule))
     |> String.concat " "
   in
   Printf.sprintf "@keyframes %s { %s }" name rules
*)

(*
   type t = string;
   let to_string = Rule.to_string;
   let mergeStyles = Emotion_bindings.mergeStyles;
   let make = Emotion_bindings.make;
   let injectRules = Emotion_bindings.injectRules;
   let injectRaw = Emotion_bindings.injectRaw;
   let global = (. selector, rules) => Emotion_bindings.injectRules(. selector, to_string(rules));
   let keyframe = (. frames) =>
       Emotion_bindings.keyframe(.
           Array.fold_left(
             (. dict, (stop, rules)) => {
               Js_of_ocaml.Js.Unsafe.set(
                 dict,
                 Int.to_string(stop) ++ "%",
                 to_string(rules),
               );
               dict;
             },
             Js_of_ocaml.Js.Unsafe.obj([||]),
             frames
           ),
         );
*)

(* external injectRaw: (. string) => unit = "injectGlobal"
   let renderRaw = (. _, css) => injectRaw(. css)

   @module("@emotion/css")
   external injectRawRules: (. Js.Json.t) => unit = "injectGlobal"

   let injectRules = (. selector, rules) =>
     injectRawRules(. Js.Dict.fromArray([(selector, rules)])->Js.Json.object_)
   let renderRules = (. _, selector, rules) =>
     injectRawRules(. Js.Dict.fromArray([(selector, rules)])->Js.Json.object_)

   @module("@emotion/css")
   external mergeStyles: (. array<styleEncoding>) => styleEncoding = "cx"

   @module("@emotion/css") external make: (. Js.Json.t) => styleEncoding = "css"

   @module("@emotion/css")
   external makeAnimation: (. Js.Dict.t<Js.Json.t>) => string = "keyframes" *)
