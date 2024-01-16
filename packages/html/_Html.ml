(* Based on https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/server/escapeTextForBrowser.js#L51-L98 *)
(* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
let encode s =
  let buffer = Buffer.create (String.length s * 2) in
  s
  |> String.iter (function
       | '&' -> Buffer.add_string buffer "&amp;"
       | '<' -> Buffer.add_string buffer "&lt;"
       | '>' -> Buffer.add_string buffer "&gt;"
       | '"' -> Buffer.add_string buffer "&quot;"
       | '\'' -> Buffer.add_string buffer "&#x27;"
       | c -> Buffer.add_char buffer c);
  Buffer.contents buffer

let is_self_closing_tag = function
  (* Take the list from
     https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/shared/omittedCloseTags.js but found https://github.com/wooorm/html-void-elements to be more complete. *)
  | "area" | "base" | "basefont" | "bgsound" | "br" | "col" | "command"
  | "embed" | "frame" | "hr" | "image" | "img" | "input" | "keygen"
  | "link" (* | "menuitem" *) | "meta" | "param" | "source" | "track" | "wbr" ->
      true
  | _ -> false
