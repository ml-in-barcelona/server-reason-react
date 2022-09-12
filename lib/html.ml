(* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
(* If problems http://projects.camlcity.org/projects/dl/ocamlnet-4.1.6/doc/html-main/Netencoding.Html.html *)
let escape s =
  let add = Buffer.add_string in
  let len = String.length s in
  let b = Buffer.create len in
  let max_idx = len - 1 in
  let flush b start i =
    if start < len then Buffer.add_substring b s start (i - start)
  in
  let rec escape_inner start i =
    if i > max_idx then flush b start i
    else
      let next = i + 1 in
      match String.get s i with
      | '&' ->
          flush b start i;
          add b "&amp;";
          escape_inner next next
      | '<' ->
          flush b start i;
          add b "&lt;";
          escape_inner next next
      | '>' ->
          flush b start i;
          add b "&gt;";
          escape_inner next next
      | '\'' ->
          flush b start i;
          add b "&apos;";
          escape_inner next next
      | '\"' ->
          flush b start i;
          add b "&quot;";
          escape_inner next next
      | ' ' ->
          flush b start i;
          add b "&nbsp;";
          escape_inner next next
      | _ -> escape_inner start next
  in
  escape_inner 0 0 |> ignore;
  Buffer.contents b
