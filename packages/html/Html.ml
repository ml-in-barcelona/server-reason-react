let is_self_closing_tag = function
  (* Take the list from
     https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/shared/omittedCloseTags.js but found https://github.com/wooorm/html-void-elements to be more complete. *)
  | "area" | "base" | "basefont" | "bgsound" | "br" | "col" | "command" | "embed" | "frame" | "hr" | "image" | "img"
  | "input" | "keygen" | "link" (* | "menuitem" *) | "meta" | "param" | "source" | "track" | "wbr" ->
      true
  | _ -> false

let escape buf s =
  let length = String.length s in
  let exception First_char_to_escape of int in
  match
    for i = 0 to length - 1 do
      match String.unsafe_get s i with
      | '&' | '<' | '>' | '\'' | '"' -> raise_notrace (First_char_to_escape i)
      | _ -> ()
    done
  with
  | exception First_char_to_escape first ->
      if first > 0 then Buffer.add_substring buf s 0 first;
      for i = first to length - 1 do
        match String.unsafe_get s i with
        | '&' -> Buffer.add_string buf "&amp;"
        | '<' -> Buffer.add_string buf "&lt;"
        | '>' -> Buffer.add_string buf "&gt;"
        | '\'' -> Buffer.add_string buf "&apos;"
        | '"' -> Buffer.add_string buf "&quot;"
        | c -> Buffer.add_char buf c
      done
  | () -> Buffer.add_string buf s

type attribute = [ `Present of string | `Value of string * string | `Omitted ]
type attribute_list = attribute list

let attribute name value = `Value (name, value)
let present name = `Present name
let omitted () = `Omitted

let write_attribute buf (attr : attribute) =
  match attr with
  | `Omitted -> ()
  | `Present name ->
      Buffer.add_char buf ' ';
      Buffer.add_string buf name
  | `Value (name, value) ->
      Buffer.add_char buf ' ';
      Buffer.add_string buf name;
      Buffer.add_string buf "=\"";
      escape buf value;
      Buffer.add_char buf '"'

type element =
  | Null
  | String of string
  | Raw of string (* text without encoding *)
  | Node of node
  | Int of int
  | Float of float
  | List of (string * element list)
  | Array of element array

and node = { tag : string; attributes : attribute_list; children : element list }

let string txt = String txt
let raw txt = Raw txt
let null = Null
let int i = Int i
let float f = Float f
let list ?(separator = "") list = List (separator, list)
let array arr = Array arr
let fragment arr = List arr
let node tag attributes children = Node { tag; attributes; children }

let to_string ?(add_separator_between_text_nodes = true) element =
  let out = Buffer.create 1024 in
  (* This ref is used to enable rendering comments <!-- --> between text nodes
     and can be disabled by `add_separator_between_text_nodes` *)
  let previous_was_text_node = ref false in
  let should_add_doctype_to_html = ref true in
  let rec write element =
    match element with
    | Null -> should_add_doctype_to_html.contents <- false
    | Int i -> Buffer.add_string out (Int.to_string i)
    | Float f -> Buffer.add_string out (Float.to_string f)
    | String text ->
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        if is_previous_text_node && add_separator_between_text_nodes then Buffer.add_string out "<!-- -->";
        escape out text;
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

(* The pretty print is used for debugging purposes *)
let pp element =
  let out = Buffer.create 1024 in
  let rec write element =
    match element with
    | Null -> ()
    | Int i -> Buffer.add_string out (Int.to_string i)
    | Float f -> Buffer.add_string out (Float.to_string f)
    | String text -> escape out text
    | Raw text -> Buffer.add_string out text
    | Node { tag; attributes; _ } when is_self_closing_tag tag ->
        Buffer.add_char out '<';
        Buffer.add_string out tag;
        List.iter (write_attribute out) attributes;
        Buffer.add_string out " />"
    | Node { tag; attributes; children } ->
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
      | '&' ->
          flush b start i;
          adds b "&amp;";
          loop next next
      | _ -> loop start next
  in
  loop 0 0

let single_quote_escape data =
  let buf = Buffer.create (String.length data) in
  add_single_quote_escaped buf data;
  Buffer.contents buf
