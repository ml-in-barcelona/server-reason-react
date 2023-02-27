(* https://github.com/Fyrd/caniuse/blob/7192d7bec6ab97231bd42bedeeaef5c01ffbabcb/features-json/css-all.json *)
(* https://github.com/browserslist/browserslist-rs/tree/main/vendor *)

let webkit property = Printf.sprintf "-webkit-%s" property
let moz property = Printf.sprintf "-moz-%s" property
let ms property = Printf.sprintf "-ms-%s" property
let o property = Printf.sprintf "-o-%s" property
let khtml property = Printf.sprintf "-khtml-%s" property

let prefix property value prefixes =
  prefixes
  |> List.map (fun prefix -> Rule.Declaration (prefix property, value))
  |> List.cons (Rule.Declaration (property, value))

let autoprefix (rule : Rule.t) : Rule.t list =
  match rule with
  | Rule.Declaration
      ( (( "animation" | "animation-name" | "animation-duration"
         | "animation-delay" | "animation-direction" | "animation-fill-mode"
         | "animation-iteration-count" | "animation-play-state"
         | "animation-timing-function" ) as property)
      , value ) ->
      prefix property value [ webkit ]
  | Declaration (("user-select" as property), value) ->
      prefix property value [ webkit; ms; moz; o ]
  | _ -> [ rule ]
