module Hash = struct
  let make (str : string) = Murmur3.hash32 str |> Int32.abs |> Int32.to_string

  (* let make str =
     (* Initialize the hash *)
     let h = ref 0 in

     (* Mix 4 bytes at a time into the hash *)
     let k = ref 0 in
     let i = 0 in
     let len = String.length str in

     for i = 0 to (len / 4) - 1 do
       let or_0xff = ( land ) 0xff in
       let first = String.get str i |> Char.code |> or_0xff in
       let second = String.get str (i + 1) |> Char.code |> or_0xff |> ( lsl ) 8 in
       let third = String.get str (i + 2) |> Char.code |> or_0xff |> ( lsl ) 16 in
       let forth = String.get str (i + 3) |> Char.code |> or_0xff |> ( lsl ) 24 in
       k := first lor (second lor (third lor forth));
       k := (k.contents land 0xffff * 0x5bd1e995) + (k.contents lsr 16);
       k := k.contents lxor (k.contents lsr 24) land 0xffffffff;
       h := h.contents * 0x5bd1e995 lxor !k;
       h := h.contents lxor (h.contents lsr 24)
     done;

     (* Handle the last few bytes of the input array *)
     (h :=
        match len with
        | 3 ->
            h.contents
            lxor (String.get str (i + 2)
                 |> Char.code |> ( land ) 0xff |> ( lsl ) 16)
        | 2 ->
            h.contents
            lxor (String.get str (i + 1) |> Char.code |> ( land ) 0xff |> ( lsl ) 8)
        | 1 -> h.contents lxor (String.get str i |> Char.code |> ( land ) 0xff)
        | _ -> h.contents);

     (* Do a few final mixes of the hash to ensure the last few *)
     (* bytes are well-incorporated. *)
     h := h.contents lxor (h.contents lsr 13);
     h := h.contents * 0x5bd1e995;
     h := h.contents lxor (h.contents lsr 15);

     h.contents |> Int.to_string
  *)
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

and to_string rules = rules |> Array.fold_left rule_to_string "" |> String.trim

let make_style_fn side_effect (styles : Css.Rule.t array) =
  let hash = Hash.make (to_string styles) in
  side_effect hash styles;
  hash

let cache = ref (Hashtbl.create 1000)

let push hash (styles : Css.Rule.t array) =
  Hashtbl.add cache.contents hash styles

let _get hash = Hashtbl.find cache.contents hash
let create () = make_style_fn push

let render_style_tag () =
  Hashtbl.fold
    (fun hash rules accumulator ->
      let selector = "." ^ hash in
      let rules = to_string rules in
      Printf.sprintf "%s%s { %s } " accumulator selector rules)
    cache.contents ""
  |> String.trim
