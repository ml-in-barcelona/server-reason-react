(* Based on https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/server/escapeTextForBrowser.js#L51-L98 *)
(* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
let encode s =
  let add = Buffer.add_string in
  let len = String.length s in
  let buff = Buffer.create len in
  let max_idx = len - 1 in
  let flush buff start i =
    if start < len then Buffer.add_substring buff s start (i - start)
  in
  let rec escape_inner start i =
    if i > max_idx then flush buff start i
    else
      let next = i + 1 in
      match String.get s i with
      | '&' ->
          flush buff start i;
          add buff "&amp;";
          escape_inner next next
      | '<' ->
          flush buff start i;
          add buff "&lt;";
          escape_inner next next
      | '>' ->
          flush buff start i;
          add buff "&gt;";
          escape_inner next next
      | '\'' ->
          flush buff start i;
          add buff "&#x27;";
          escape_inner next next
      | '\"' ->
          flush buff start i;
          add buff "&quot;";
          escape_inner next next
      | _ -> escape_inner start next
  in
  escape_inner 0 0 |> ignore;
  Buffer.contents buff

let is_self_closing_tag = function
  (* https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/shared/omittedCloseTags.js *)
  | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
  | "meta" | "param" | "source" | "track" | "wbr" (* | "menuitem" *) ->
      true
  | _ -> false
