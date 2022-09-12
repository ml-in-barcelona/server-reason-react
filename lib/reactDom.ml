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

(* ignores "ref" prop *)
let attribute_is_not_html = function "ref" -> true | _ -> false

let attribute_to_string attr =
  let open Attribute in
  match attr with
  (* false attributes don't get rendered *)
  | Bool (_, false) -> ""
  | Bool (k, true) -> k
  | DangerouslyInnerHtml html -> html
  | Style styles -> Printf.sprintf "style=\"%s\"" (styles_to_string styles)
  | String (k, _) when attribute_is_not_html k -> ""
  | String (k, v) ->
      Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (Html.escape v)

let attribute_is_not_empty = function
  | Attribute.String (k, _v) -> k != ""
  | Bool (k, _) -> k != ""
  | DangerouslyInnerHtml _ -> false
  | Style styles -> List.length styles != 0

(* FIXME: Remove empty style attributes or class *)
let attribute_is_not_valid = attribute_is_not_empty

let attributes_to_string attrs =
  let attributes = List.filter attribute_is_not_valid attrs in
  match attributes with
  | [] -> ""
  | _ ->
      " "
      ^ (String.concat " " (attributes |> List.map attribute_to_string)
        |> String.trim)

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
    | Element { tag; attributes; children } ->
        is_root.contents <- false;
        let attributes = attributes_to_string attributes in
        let childrens =
          children |> List.map render_to_string_inner |> String.concat ""
        in
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attributes childrens
          tag
    | Closed_element { tag; attributes } ->
        is_root.contents <- false;
        let attributes = attributes_to_string attributes in
        Printf.sprintf "<%s%s%s />" tag root_attribute attributes
  in
  render_to_string_inner component
