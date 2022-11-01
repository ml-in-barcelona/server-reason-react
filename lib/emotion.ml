module Hash = struct
  (*
    TODO: This hashing function should be a rewrite of @emotion/hash,
    what's below it's an ongoing effort to match the hashing function.

    Reference: https://github.com/emotion-js/emotion/blob/main/packages/hash/src/index.js
    https://github.com/garycourt/murmurhash-js/blob/master/murmurhash2_gc.js
    *)
  let make (str : string) =
    (* Initialize the hash *)
    let h = ref Int64.zero in

    (* Mix 4 bytes at a time into the hash *)
    let k = ref Int64.zero in
    let i = 0 in
    let len = String.length str in

    let ( << ) = Int64.shift_left in
    let ( & ) = Int64.logand in
    let ( ||| ) = Int64.logor in
    let ( * ) = Int64.mul in
    let ( >>> ) = Int64.shift_right in
    let ( ++ ) = Int64.add in
    let ( ^ ) = Int64.logxor in
    let get_int64_char str i = String.get str i |> Char.code |> Int64.of_int in

    for i = 0 to (len / 4) - 1 do
      let first = get_int64_char str i & 255L in
      let second = get_int64_char str (i + 1) & 255L << 8 in
      let third = get_int64_char str (i + 2) & 255L << 16 in
      let forth = get_int64_char str (i + 3) & 255L << 24 in
      (* print_endline (Printf.sprintf "first: %d" first);
         print_endline (Printf.sprintf "second: %d" second);
         print_endline (Printf.sprintf "third: %d" third);
         print_endline (Printf.sprintf "forth: %d" forth); *)
      k := first ||| (second ||| (third ||| forth));

      (* k =
         (k & 0xffff) * 0x5bd1e995 + (((k >>> 16) * 0xe995) << 16); *)
      let k_one = (!k & 65535L) * 1540483477L in
      let k_16 = (!k >>> 16) * 59797L << 16 in
      k := k_one ++ k_16;
      (* k ^= /* k >>> r: */ k >>> 24; *)
      k := !k ^ (!k >>> 24);

      (* h =
         /* Math.imul(k, m): */
         ((k & 0xffff) * 0x5bd1e995 + (((k >>> 16) * 0xe995) << 16)) ^
         /* Math.imul(h, m): */
         ((h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16)); *)
      h :=
        (((!k & 65535L) * 1540483477L) ++ ((!k >>> 16) * 59797L << 16))
        ^ (((!h & 65535L) * 1540483477L) ++ ((!h >>> 16) * 59797L << 16))
    done;

    (* Handle the last few bytes of the input array *)
    (h :=
       match len with
       | 3 -> !h ^ (get_int64_char str (i + 2) & 255L) << 16
       | 2 -> !h ^ (get_int64_char str (i + 1) & 255L) << 8
       | 1 ->
           let h' =
             ((!h & 65535L) * 1540483477L) ++ ((!h >>> 16) * 59797L << 16)
           in
           h' ^ (get_int64_char str (i + 1) & 255L)
       | _ -> h.contents);

    (* print_endline (Printf.sprintf "h-pre: %d" h.contents); *)

    (* h ^= h >>> 13;
       h =
         (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16);
    *)

    (* Do a few final mixes of the hash to ensure the last few *)
    (* bytes are well-incorporated. *)
    h := !h ^ (!h >>> 13);
    h := ((!h & 65535L) * 1540483477L) ++ ((!h >>> 16) * 59797L << 16);
    h := !h ^ (!h >>> 15);

    (* let result = ((h ^ (h >>> 15)) >>> 0).toString(36); *)
    !h |> Int64.abs |> Int64.to_string |> String.cat "s"
end

(* include Values;
   include Properties;
   include Colors;

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

let rec rule_to_string accumulator rule =
  let open Css.Rule in
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
  | Css.Rule.Declaration (property, value) ->
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
  let selector =
    selector |> remove_first_ampersand |> String.trim |> resolve_ampersand hash
  in
  Printf.sprintf ".%s %s" hash selector

let render_selectors hash rule =
  match rule with
  | Css.Rule.Selector (selector, rules) when is_media_query selector ->
      Some (Printf.sprintf "%s { .%s { %s } }" selector hash (to_string rules))
  | Css.Rule.Selector (selector, rules) ->
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
  let open Css.Rule in
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
  let open Css.Rule in
  List.partition_map (function
    | Selector (title, selector_rules) ->
        let new_prelude = prefix ^ title in
        print_endline prefix;
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
  let list_of_rules = rules |> unnest_selectors |> List.rev in
  print_rules list_of_rules;
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

let make_style_fn side_effect (styles : Css.Rule.t list) =
  let hash = Hash.make (to_string styles) in
  side_effect hash styles;
  hash

let cache = ref (Hashtbl.create 1000)

let push hash (styles : Css.Rule.t list) =
  Hashtbl.add cache.contents hash styles

let _get hash = Hashtbl.find cache.contents hash
let flush () = Hashtbl.clear cache.contents

let create () =
  (* Each time a style function is created,
     previous styles from the cache got removed *)
  flush ();
  make_style_fn push

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
