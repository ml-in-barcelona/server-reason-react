open React

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

let styles_to_string styles =
  styles
  |> List.map (fun (k, v) -> k ^ ": " ^ String.trim v)
  |> String.concat "; "

let attribute_is_html tag attr_name =
  match DomProps.findByName tag attr_name with Ok _ -> true | Error _ -> false

let get_key = function
  | Attribute.Bool (k, _) -> k
  | String (k, _) -> k
  | Ref _ -> "ref"
  | DangerouslyInnerHtml _ -> "dangerouslySetInnerHTML"
  | Style _ -> "style"

let is_react_custom_attributes attr =
  match get_key attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_is_valid tag attr = attribute_is_html tag (get_key attr)

let attribute_to_string attr =
  let open Attribute in
  match attr with
  | Ref _ -> ""
  (* false attributes don't get rendered *)
  | Bool (_, false) -> ""
  | Bool (k, true) -> k
  | String (k, v) ->
      Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (Html.escape v)
  | DangerouslyInnerHtml html -> html
  | Style styles -> Printf.sprintf "style=\"%s\"" (styles_to_string styles)

let attributes_to_string tag attrs =
  let valid_attributes =
    attrs |> Array.to_list
    |> List.filter (attribute_is_valid tag)
    |> List.filter (Fun.negate is_react_custom_attributes)
    |> List.map attribute_to_string
  in
  match valid_attributes with
  | [] -> ""
  | _ -> " " ^ (valid_attributes |> String.concat " " |> String.trim)

(* FIXME: Add link to source *)
let react_root_attr_name = "data-reactroot"
let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

let renderToStaticMarkup (component : Node.t) =
  (* is_root starts at true (when renderToString) and only goes to false when renders an element or closed element *)
  let is_root = ref false in
  let rec render_to_string_inner component =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match component with
    | Node.Empty -> ""
    | Fragment [] -> ""
    | Text text -> Html.escape text
    | Provider children ->
        children
        |> List.map (fun f -> f ())
        |> List.map render_to_string_inner
        |> String.concat ""
    | Consumer children ->
        children () |> List.map render_to_string_inner |> String.concat ""
    | Fragment children ->
        children |> List.map render_to_string_inner |> String.concat ""
    | Component f -> render_to_string_inner (f ())
    | Element { tag; attributes; children } ->
        is_root.contents <- false;
        let attributes = attributes_to_string tag attributes in
        let childrens =
          children |> List.map render_to_string_inner |> String.concat ""
        in
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attributes childrens
          tag
    | Closed_element { tag; attributes } ->
        is_root.contents <- false;
        let attributes = attributes_to_string tag attributes in
        Printf.sprintf "<%s%s%s />" tag root_attribute attributes
  in
  render_to_string_inner component

module Style = ReactDomStyle
