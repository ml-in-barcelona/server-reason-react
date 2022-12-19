open React

module Html = struct
  (* Based on https://github.com/facebook/react/blob/97d75c9c8bcddb0daed1ed062101c7f5e9b825f4/packages/react-dom-bindings/src/server/escapeTextForBrowser.js#L51-L98 *)
  (* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
  let encode s =
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
            add b "&#x27;";
            escape_inner next next
        | '\"' ->
            flush b start i;
            add b "&quot;";
            escape_inner next next
        | _ -> escape_inner start next
    in
    escape_inner 0 0 |> ignore;
    Buffer.contents b
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

let attribute_is_html tag attr_name =
  (* We make sure that onclick is valid attribute *)
  if String.equal attr_name "onclick" then true
  else
    match DomProps.findByName tag attr_name with
    | Ok _ -> true
    | Error _ -> false

let replace_reserved_names attr =
  match attr with "type" -> "type_" | _ -> attr

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
  match attr with Attribute.Event _ -> false | _ -> true

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
  (* Simply render the attribute name when is true *)
  | Bool (k, true) -> k
  (* Since we extracted the attribute as children (Eleent.InnerHtml),
     we don't want to render anything here *)
  | DangerouslyInnerHtml _ -> ""
  (* We ignore events on SSR, the only exception is "_onclick" which turns to be an Attribute.String *)
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

let render_tree ~mode (element : Element.t) =
  let open Element in
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_to_string = mode = String in
  let is_root = ref is_to_string in
  (* previous_was_text_node ensures to add <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_inner element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> ""
    | Fragment [] -> ""
    | InnerHtml text -> text
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            Printf.sprintf "<!-- -->%s" (Html.encode text)
        | _ -> Html.encode text)
    | Provider children ->
        children
        |> List.map (fun f -> f ())
        |> List.map render_inner |> String.concat ""
    | List list ->
        list |> Array.map render_inner |> Array.to_list |> String.concat ""
    | Consumer children ->
        children () |> List.map render_inner |> String.concat ""
    | Fragment children -> children |> List.map render_inner |> String.concat ""
    | Upper_case_element f -> render_inner (f ())
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        let attrs = attributes_to_string tag attributes in
        let childrens = children |> List.map render_inner |> String.concat "" in
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attrs childrens tag
    | Lower_case_closed_element { tag; attributes } ->
        is_root.contents <- false;
        let attrs = attributes_to_string tag attributes in
        Printf.sprintf "<%s%s%s />" tag root_attribute attrs
  in
  render_inner element

let renderToString element = render_tree ~mode:String element
let renderToStaticMarkup element = render_tree ~mode:Markup element
let querySelector _str = None
let render _element _node = ()

module Style = ReactDOMStyle
