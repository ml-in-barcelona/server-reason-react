let is_self_closing_tag = function
  (* Take the list from
     https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/shared/omittedCloseTags.js but found https://github.com/wooorm/html-void-elements to be more complete. *)
  | "area" | "base" | "basefont" | "bgsound" | "br" | "col" | "command" | "embed" | "frame" | "hr" | "image" | "img"
  | "input" | "keygen" | "link" (* | "menuitem" *) | "meta" | "param" | "source" | "track" | "wbr" ->
      true
  | _ -> false

(* This function is borrowed from https://github.com/dbuenzli/htmlit/blob/62d8f21a9233791a5440311beac02a4627c3a7eb/src/htmlit.ml#L10-L28 *)
let escape_and_add out str =
  let add = Buffer.add_string in
  let getc = String.unsafe_get str in
  let len = String.length str in
  let max_index = len - 1 in
  let flush out start index = if start < len then Buffer.add_substring out str start (index - start) in
  let rec loop start index =
    if index > max_index then flush out start index
    else
      let next = index + 1 in
      match getc index with
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

type attribute = [ `Present of string | `Value of string * string | `Omitted ]
type attribute_list = attribute list

let attribute name value = `Value (name, value)
let present name = `Present name
let omitted () = `Omitted

let write_attribute out (attr : attribute) =
  let write_name_value name value =
    Buffer.add_char out ' ';
    Buffer.add_string out name;
    Buffer.add_string out "=\"";
    escape_and_add out value;
    Buffer.add_char out '"'
  in
  match attr with
  | `Omitted -> ()
  | `Present name ->
      Buffer.add_char out ' ';
      Buffer.add_string out name
  | `Value (name, value) -> write_name_value name value

type element =
  | Null
  | String of string
  | Raw of string (* text without encoding *)
  | Node of node
  | List of (string * element list)
  | Array of element array

and node = { tag : string; attributes : attribute_list; children : element list }

let string txt = String txt
let raw txt = Raw txt
let null = Null
let int i = String (Int.to_string i)
let float f = String (Float.to_string f)
let list ?(separator = "") list = List (separator, list)
let array arr = Array arr
let fragment arr = List arr
let node tag attributes children = Node { tag; attributes; children }

let to_string ?(add_separator_between_text_nodes = true) element =
  let out = Buffer.create 1024 in
  (* This ref is used to enable rendering comments <!-- --> between text nodes
     and can be disabled by `add_separator_between_text_nodes` *)
  let previous_was_text_node = ref false in
  (* *)
  let should_add_doctype_to_html = ref true in
  let rec write element =
    match element with
    | Null -> should_add_doctype_to_html.contents <- false
    | String text ->
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        if is_previous_text_node && add_separator_between_text_nodes then Buffer.add_string out "<!-- -->";
        escape_and_add out text;
        should_add_doctype_to_html.contents <- false
    | Raw text ->
        Buffer.add_string out text;
        should_add_doctype_to_html.contents <- false
    | Node { tag; attributes; _ } when is_self_closing_tag tag ->
        Buffer.add_char out '<';
        Buffer.add_string out tag;
        List.iter (write_attribute out) attributes;
        Buffer.add_string out " />";
        should_add_doctype_to_html.contents <- false
    | Node { tag; attributes; children } ->
        (* capturing the value of should_add_doctype_to_html before setting it to false, so the first thing is set to false and use the captured value *)
        let should_add_doctype = should_add_doctype_to_html.contents in
        should_add_doctype_to_html.contents <- false;
        (* If the previous node was text, but from another parent node, then the comment shouldn't be added.
           Check `separated_text_nodes_by_other_nodes` in test_renderToString.ml *)
        if add_separator_between_text_nodes then previous_was_text_node.contents <- false;
        if tag = "html" && should_add_doctype then Buffer.add_string out "<!DOCTYPE html>";
        Buffer.add_char out '<';
        Buffer.add_string out tag;
        List.iter (write_attribute out) attributes;
        Buffer.add_char out '>';
        List.iter write children;
        Buffer.add_string out "</";
        Buffer.add_string out tag;
        Buffer.add_char out '>'
    | List ("", list) -> List.iter write list
    | List (separator, list) ->
        let rec iter = function
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
    | Array elements -> Array.iter write elements
  in
  write element;
  Buffer.contents out

let add_single_quote_escaped b s =
  let getc = String.unsafe_get s in
  let adds = Buffer.add_string in
  let len = String.length s in
  let max_idx = len - 1 in
  let flush b start i = if start < len then Buffer.add_substring b s start (i - start) in
  let rec loop start i =
    if i > max_idx then flush b start i
    else
      let next = i + 1 in
      match getc i with
      | '\'' ->
          flush b start i;
          adds b "&#x27;";
          loop next next
      | _ -> loop start next
  in
  loop 0 0

let single_quote_escape data =
  let buf = Buffer.create (String.length data) in
  add_single_quote_escaped buf data;
  Buffer.contents buf
