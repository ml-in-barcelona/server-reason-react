open React

module Html = struct
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
end

let attribute_name_to_jsx k =
  match k with
  | "className" -> "class"
  | "htmlFor" -> "for"
  (* serialize defaultX props to the X attribute *)
  (* FIXME: Add link *)
  | "defaultValue" -> "value"
  | "defaultChecked" -> "checked"
  | "defaultSelected" -> "selected"
  | _ -> k

let is_onclick_event event =
  match event with
  | Attribute.Event (name, _) when String.equal name "_onclick" -> true
  | _ -> false

let attribute_is_html tag attr_name =
  match DomProps.findByName tag attr_name with Ok _ -> true | Error _ -> false

let replace_reserved_names attr =
  match attr with "type" -> "type_" | "as" -> "as_" | _ -> attr

let get_key = function
  | Attribute.Bool (k, _) -> k
  | String (k, _) -> replace_reserved_names k
  | Ref _ -> "ref"
  | DangerouslyInnerHtml _ -> "dangerouslySetInnerHTML"
  | Style _ -> "style"
  | Event (name, _) -> (* FIXME: tolowercase? does it even matter? *) name

let is_react_custom_attribute attr =
  match get_key attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_is_not_event attr =
  match attr with
  (* We treat _onclick as "not an event", so attribute_is_valid turns it true *)
  | Attribute.Event _ as event when is_onclick_event event -> true
  | Attribute.Event _ -> false
  | _ -> true

let attribute_is_valid tag attr =
  attribute_is_html tag (get_key attr)
  && attribute_is_not_event attr
  && not (is_react_custom_attribute attr)

let attribute_to_string attr =
  let open Attribute in
  match attr with
  (* ignores "ref" prop *)
  | Ref _ -> ""
  (* false attributes don't get rendered *)
  | Bool (_, false) -> ""
  (* true attributes render solely the attribute name *)
  | Bool (k, true) -> k
  (* Since we extracted the attribute as children (Element.InnerHtml),
     we don't want to render anything here *)
  | DangerouslyInnerHtml _ -> ""
  (* We ignore events on SSR, the only exception is "_onclick" which renders as string onclick *)
  | Event (name, Inline value) when String.equal name "_onclick" ->
      Printf.sprintf "onclick=\"%s\"" value
  | Event _ -> ""
  | Style styles -> Printf.sprintf "style=\"%s\"" styles
  | String (k, v) ->
      Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (Html.encode v)

let attributes_to_string tag attrs =
  let valid_attributes =
    attrs |> Array.to_list
    |> List.filter_map (fun attr ->
           if attribute_is_valid tag attr then Some (attribute_to_string attr)
           else None)
  in
  match valid_attributes with
  | [] -> ""
  | rest -> " " ^ (rest |> String.concat " " |> String.trim)

let react_root_attr_name = "data-reactroot"
let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

type mode =
  | String
  | Markup

(** The DOCTYPE declaration is an instruction to the web browser about what version of HTML the page is written in. This ensures that the web page is parsed the same way by different web browsers. *)
type docType =
  | HTML5
  | HTML4
  | HTML4_frameset
  | HTML4_transactional

let render_docType = function
  | HTML5 -> "<!DOCTYPE html>"
  | HTML4 ->
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \
       \"http://www.w3.org/TR/html4/strict.dtd\">"
  | HTML4_frameset ->
      "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\" \
       \"http://www.w3.org/TR/html4/frameset.dtd\">"
  | HTML4_transactional ->
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \
       \"http://www.w3.org/TR/html4/loose.dtd\">"

let render_tree ~docType ~mode (element : Element.t) =
  let open Element in
  let buff = Buffer.create 16 in
  let push = Buffer.add_string buff in
  Option.iter (fun docType -> push (render_docType docType)) docType;
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in
  (* previous_was_text_node is the flag to enable rendering comments
     <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_inner element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> push ""
    | Provider childrens ->
        childrens |> List.map (fun f -> f ()) |> List.iter render_inner
    | Consumer children -> children () |> List.iter render_inner
    | Fragment [] -> push ""
    | Fragment childrens -> childrens |> List.iter render_inner
    | List list -> list |> Array.iter render_inner
    | Upper_case_element f -> render_inner (f ())
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        let attrs = attributes_to_string tag attributes in
        push "<";
        push tag;
        push root_attribute;
        push attrs;
        push ">";
        children |> List.iter render_inner;
        push "</";
        push tag;
        push ">"
    | Lower_case_closed_element { tag; attributes } ->
        is_root.contents <- false;
        push "<";
        push tag;
        push (attributes_to_string tag attributes);
        push " />"
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            push (Printf.sprintf "<!-- -->%s" (Html.encode text))
        | _ -> push (Html.encode text))
    | InnerHtml text -> push text
  in
  render_inner element;
  buff |> Buffer.contents

let renderToString ?docType element = render_tree ~mode:String element ~docType

let renderToStaticMarkup ?docType element =
  render_tree ~mode:Markup element ~docType

let querySelector _str = None

let fail_impossible_action_in_ssr =
  (* failwith seems bad, but I don't know any other way
     of warning the user without changing the types. Doing a unit *)
  (* failwith
     (Printf.sprintf "render shouldn't run on the server %s, line %d" __FILE__
        __LINE__) *)
  ()

let render _element _node = fail_impossible_action_in_ssr
let hydrate _element _node = fail_impossible_action_in_ssr
let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle
