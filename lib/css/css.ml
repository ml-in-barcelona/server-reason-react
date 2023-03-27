include Properties
include Colors
include Rule

let rec generate_rule rule =
  let buff = Buffer.create 16 in
  let push = Buffer.add_string buff in
  (match rule with
  | Declaration (property, value) ->
      push (Printf.sprintf "%s: %s; " property value)
  | Selector (selector, rules) ->
      push (Printf.sprintf ".%s { %s }" selector (generate_rules rules))
  | Pseudoclass (pseudoclass, rules) ->
      push (Printf.sprintf ":%s { %s }" pseudoclass (generate_rules rules))
  | PseudoclassParam (pseudoclass, param, rules) ->
      push
        (Printf.sprintf ":%s (%s) { %s }" pseudoclass param
           (generate_rules rules)));
  Buffer.contents buff

and generate_rules rules =
  rules
  |> List.map Autoprefixer.prefix
  |> List.flatten |> List.map generate_rule |> String.concat ""

let rule_to_string rule = generate_rule rule
let rules_to_string rules = generate_rules rules

let render_declaration rule =
  match rule with
  | Declaration (property, value) ->
      Some (Printf.sprintf "%s: %s;" property value)
  | _ -> None

let is_media_query selector = String.contains selector '@'

let prefix ~pre s =
  let len = String.length pre in
  if len > String.length s then false
  else
    let rec check i =
      if i = len then true
      else if Stdlib.( <> ) (String.unsafe_get s i) (String.unsafe_get pre i)
      then false
      else check (i + 1)
    in
    check 0

let chop_prefix ~pre s =
  if prefix ~pre s then
    Some
      (String.sub s (String.length pre) (String.length s - String.length pre))
  else None

let remove_first_ampersand selector =
  selector |> chop_prefix ~pre:"&" |> Option.value ~default:selector

let replace_ampersand str with_ =
  let rec replace_ampersand' str var =
    let len = String.length str in
    if len = 0 then ""
    else if str.[0] = '&' then
      var ^ replace_ampersand' (String.sub str 1 (len - 1)) var
    else
      String.sub str 0 1 ^ replace_ampersand' (String.sub str 1 (len - 1)) var
  in
  replace_ampersand' str with_

let resolve_ampersand hash selector = replace_ampersand selector ("." ^ hash)

let make_prelude hash selector =
  let new_selector =
    selector |> remove_first_ampersand |> resolve_ampersand hash
  in
  Printf.sprintf ".%s %s" hash new_selector

let render_selectors hash rule =
  match rule with
  | Selector (selector, rules) when is_media_query selector ->
      Some
        (Printf.sprintf "%s { .%s { %s } }" selector hash
           (rules_to_string rules))
  | Selector (selector, rules) ->
      let prelude = make_prelude hash selector in
      Some (Printf.sprintf "%s { %s }" prelude (rules_to_string rules))
  | Pseudoclass (pseduoclass, rules) ->
      Some
        (Printf.sprintf ".%s:%s { %s }" hash pseduoclass (rules_to_string rules))
  | PseudoclassParam (pseudoclass, param, rules) ->
      Some
        (Printf.sprintf ".%s:%s ( %s ) %s" hash pseudoclass param
           (rules_to_string rules))
  | _ -> None

let rec rule_to_debug nesting accumulator rule =
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

and to_debug nesting rules = rules |> List.fold_left (rule_to_debug nesting) ""

let print_rules rules =
  rules |> List.iter (fun rule -> print_endline (to_debug 0 [ rule ]))

let rec unnest ~prefix =
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

let nested_rule_to_string hash rules =
  (* TODO: Refactor with partition or partition_map. List.filter_map is error prone.
     Selectors might need to respect the order of definition, and this breaks the order *)
  let list_of_rules = rules |> unnest_selectors |> List.rev in
  let declarations =
    list_of_rules
    |> List.map Autoprefixer.prefix
    |> List.flatten
    |> List.filter_map render_declaration
    |> String.concat " "
    |> fun all -> Printf.sprintf ".%s { %s }" hash all
  in
  let selectors =
    list_of_rules
    |> List.filter_map (render_selectors hash)
    |> String.concat " "
  in
  Printf.sprintf "%s %s" declarations selectors

let cache = ref (Hashtbl.create 1000)
let _get hash = Hashtbl.find cache.contents hash
let flush () = Hashtbl.clear cache.contents
let push hash (styles : t list) = Hashtbl.add cache.contents hash styles

let style (styles : t list) =
  let hash = Hash.default (rules_to_string styles) |> String.cat "css-" in
  push hash styles;
  hash

let render_style_tag () =
  Hashtbl.fold
    (fun hash rules accumulator ->
      let rules = rules |> nested_rule_to_string hash |> String.trim in
      Printf.sprintf "%s %s" accumulator rules)
    cache.contents ""

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
