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

(* This function is borrowed from https://github.com/dbuenzli/htmlit/blob/62d8f21a9233791a5440311beac02a4627c3a7eb/src/htmlit.ml#L10-L28 *)
let escape_and_add out str =
  let add = Buffer.add_string in
  let len = String.length str in
  let max_index = len - 1 in
  let flush out start index =
    if start < len then Buffer.add_substring out str start (index - start)
  in
  let rec loop start index =
    if index > max_index then flush out start index
    else
      let next = index + 1 in
      match String.get str index with
      | '&' ->
          flush out start index;
          add out "&amp;";
          loop next next
      | '<' ->
          flush out start index;
          add out "&lt;";
          loop next next
      | '>' ->
          flush out start index;
          add out "&gt;";
          loop next next
      | '\'' ->
          flush out start index;
          add out "&apos;";
          loop next next
      | '\"' ->
          flush out start index;
          add out "&quot;";
          loop next next
      | _ -> loop start next
  in
  loop 0 0

type attribute =
  string * [ `Bool of bool | `Int of int | `Float of float | `String of string ]

let write_attribute out (attr : attribute) =
  let write_name_value name value =
    Buffer.add_char out ' ';
    Buffer.add_string out name;
    Buffer.add_string out "=\"";
    escape_and_add out value;
    Buffer.add_char out '"'
  in
  match attr with
  | _name, `Bool false ->
      (* false attributes don't get rendered *)
      ()
  | name, `Bool true ->
      (* true attributes render solely the attribute name *)
      Buffer.add_char out ' ';
      Buffer.add_string out name
  | name, `String value -> write_name_value name value
  | name, `Int value -> write_name_value name (string_of_int value)
  | name, `Float value -> write_name_value name (string_of_float value)

type element =
  | Null
  | String of string
  | Raw of string (* text without encoding *)
  | Node of {
      tag : string;
      attributes : attribute list;
      children : element list;
    }
  | List of (string * element list)

let string txt = String txt
let raw txt = Raw txt
let null = Null
let int i = String (Int.to_string i)
let float f = String (Float.to_string f)
let list ?(separator = "") arr = List (separator, arr)
let fragment arr = List arr
let node tag attributes children = Node { tag; attributes; children }

let render element =
  let out = Buffer.create 1024 in
  let rec write element =
    match element with
    | Null -> ()
    | String text -> escape_and_add out text
    | Raw text -> Buffer.add_string out text
    | Node { tag; attributes; _ } when is_self_closing_tag tag ->
        Buffer.add_char out '<';
        Buffer.add_string out tag;
        List.iter (write_attribute out) attributes;
        Buffer.add_string out " />"
    | Node { tag; attributes; children } ->
        if tag = "html" then Buffer.add_string out "<!DOCTYPE html>";
        Buffer.add_char out '<';
        Buffer.add_string out tag;
        List.iter (write_attribute out) attributes;
        Buffer.add_char out '>';
        List.iter write children;
        Buffer.add_string out "</";
        Buffer.add_string out tag;
        Buffer.add_char out '>'
    | List (separator, list) ->
        let rec iter list =
          match list with
          | [] -> ()
          | [ one ] -> write one
          | [ first; second ] ->
              write first;
              Buffer.add_string out separator;
              write second
          | first :: rest ->
              write first;
              Buffer.add_string out separator;
              iter rest
        in
        iter list
  in
  write element;
  Buffer.contents out
