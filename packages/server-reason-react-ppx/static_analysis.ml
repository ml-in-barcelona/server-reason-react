open Ppxlib

type static_attr_value = Static_string of string | Static_int of int | Static_bool of bool
type attr_render_info = { html_name : string; is_boolean : bool; kind : DomProps.attributeType; is_event : bool }

type static_part =
  | Static_str of { html : string; starts_text : bool; ends_text : bool }
  | Dynamic_string of expression
  | Dynamic_int of expression
  | Dynamic_element of expression
  | Dynamic_attr_slot of { info : attr_render_info; expr : expression; is_optional : bool }

let static_markup html = Static_str { html; starts_text = false; ends_text = false }
let static_text html = Static_str { html; starts_text = true; ends_text = true }

type parsed_attr =
  | Static_attr of attr_render_info * static_attr_value
  | Optional_attr of attr_render_info * expression
  | Dynamic_attr of attr_render_info * expression

type attr_validation_result = Valid_attr of attr_render_info | Invalid_attr
type attr_analysis_result = Ok of parsed_attr option | Invalid
type attrs_analysis = All_static of string | Mixed_attrs of static_part list | Validation_failed
type children_analysis = No_children | All_static_children of string | Dynamic_children of static_part list
type element_analysis = Fully_static of string | Needs_buffer of static_part list | Cannot_optimize

let rec coalesce_static_parts = function
  | Static_str a :: Static_str b :: rest when not (a.ends_text && b.starts_text) ->
      coalesce_static_parts
        (Static_str { html = a.html ^ b.html; starts_text = a.starts_text; ends_text = b.ends_text } :: rest)
  | x :: rest -> x :: coalesce_static_parts rest
  | [] -> []

let escape_html s =
  let buf = Buffer.create (String.length s) in
  Html.escape buf s;
  Buffer.contents buf

let rec strip_constraint expr =
  match expr.pexp_desc with Pexp_constraint (inner, _) -> strip_constraint inner | _ -> expr

let extract_literal_string expr =
  match (strip_constraint expr).pexp_desc with Pexp_constant (Pconst_string (s, _, _)) -> Some s | _ -> None

let extract_literal_int expr =
  match (strip_constraint expr).pexp_desc with
  | Pexp_constant (Pconst_integer (s, _)) -> ( try Some (int_of_string s) with _ -> None)
  | _ -> None

let extract_literal_bool expr =
  match (strip_constraint expr).pexp_desc with
  | Pexp_construct ({ txt = Lident "true"; _ }, None) -> Some true
  | Pexp_construct ({ txt = Lident "false"; _ }, None) -> Some false
  | _ -> None

let extract_react_string_arg expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "React", "string"); _ }; _ }, [ (Nolabel, arg) ]) ->
      Some arg
  | _ -> None

let extract_react_int_arg expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "React", "int"); _ }; _ }, [ (Nolabel, arg) ]) -> Some arg
  | _ -> None

let extract_react_text_literal expr =
  match extract_react_string_arg expr with Some arg -> extract_literal_string arg | None -> None

let extract_react_int_literal expr =
  match extract_react_int_arg expr with Some arg -> extract_literal_int arg | None -> None

let extract_static_attr_value expr =
  match extract_literal_string expr with
  | Some s -> Some (Static_string s)
  | None -> (
      match extract_literal_int expr with
      | Some i -> Some (Static_int i)
      | None -> ( match extract_literal_bool expr with Some b -> Some (Static_bool b) | None -> None))

let render_attr_value = function
  | Static_string s -> escape_html s
  | Static_int i -> string_of_int i
  | Static_bool true -> "true"
  | Static_bool false -> "false"

let validate_attr_for_static ~tag_name jsx_name =
  match DomProps.findByJsxName ~tag:tag_name jsx_name with
  | Error _ -> Invalid_attr
  | Ok prop ->
      let html_name, kind, is_event =
        match prop with
        | DomProps.Attribute { name; type_; _ } -> (name, type_, false)
        | DomProps.Event { jsxName; _ } -> (jsxName, DomProps.String, true)
      in
      let is_boolean = kind = DomProps.Bool in
      Valid_attr { html_name; is_boolean; kind; is_event }

let render_static_attr_with_info info value =
  match value with
  | Static_bool false when info.is_boolean -> ""
  | Static_bool true when info.is_boolean -> " " ^ info.html_name
  | Static_bool b when info.kind = DomProps.BooleanishString ->
      Printf.sprintf " %s=\"%s\"" info.html_name (if b then "true" else "false")
  | _ ->
      let value_str = render_attr_value value in
      Printf.sprintf " %s=\"%s\"" info.html_name value_str

let analyze_attribute ~tag_name (label, expr) : attr_analysis_result =
  match label with
  | Nolabel -> Ok None
  | Optional name -> (
      match name with
      | "ref" -> Ok None
      | _ -> (
          match validate_attr_for_static ~tag_name name with
          | Invalid_attr -> Invalid
          | Valid_attr info -> Ok (Some (Optional_attr (info, expr)))))
  | Labelled name -> (
      match name with
      | "key" | "children" | "ref" -> Ok None
      | _ -> (
          match validate_attr_for_static ~tag_name name with
          | Invalid_attr -> Invalid
          | Valid_attr info -> (
              match extract_static_attr_value expr with
              | Some value -> Ok (Some (Static_attr (info, value)))
              | None -> Ok (Some (Dynamic_attr (info, expr))))))

let is_lowerable_kind = function
  | DomProps.String | DomProps.Int | DomProps.Bool | DomProps.BooleanishString | DomProps.Style -> true
  | DomProps.Float | DomProps.Action | DomProps.Ref | DomProps.InnerHtml -> false

let is_react_custom_attribute_name = function
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning" | "suppressHydrationWarning" -> true
  | _ -> false

let attr_is_emittable (info : attr_render_info) =
  (not info.is_event) && is_lowerable_kind info.kind && not (is_react_custom_attribute_name info.html_name)

let attr_is_ignored_by_ssr (info : attr_render_info) =
  info.is_event || (is_react_custom_attribute_name info.html_name && info.kind <> DomProps.InnerHtml)

let extract_static_style expr =
  let rec collect acc expr =
    match (strip_constraint expr).pexp_desc with
    | Pexp_construct ({ txt = Lident "[]"; _ }, None) -> Some (List.rev acc)
    | Pexp_construct ({ txt = Lident "::"; _ }, Some arg) -> (
        match (strip_constraint arg).pexp_desc with
        | Pexp_tuple [ head; tail ] -> (
            match (strip_constraint head).pexp_desc with
            | Pexp_tuple [ key; _camel; value ] -> (
                match (extract_literal_string key, extract_literal_string value) with
                | Some key, Some value -> collect ((key, value) :: acc) tail
                | _ -> None)
            | _ -> None)
        | _ -> None)
    | _ -> None
  in
  match collect [] expr with
  | None -> None
  | Some entries ->
      let body = Buffer.create 64 in
      let first = ref true in
      List.iter
        (fun (key, value) ->
          if value <> "" then begin
            if not !first then Buffer.add_char body ';';
            Buffer.add_string body key;
            Buffer.add_char body ':';
            Buffer.add_string body (String.trim value);
            first := false
          end)
        entries;
      let buf = Buffer.create 64 in
      Buffer.add_string buf " style=\"";
      Html.escape buf (Buffer.contents body);
      Buffer.add_char buf '"';
      Some (Buffer.contents buf)

let analyze_attributes ~tag_name attrs =
  let parts = ref [] in
  let static_buf = Buffer.create 64 in
  let has_dynamic = ref false in
  let flush_static () =
    if Buffer.length static_buf > 0 then begin
      parts := static_markup (Buffer.contents static_buf) :: !parts;
      Buffer.clear static_buf
    end
  in
  let push_dynamic info expr ~is_optional =
    flush_static ();
    parts := Dynamic_attr_slot { info; expr; is_optional } :: !parts;
    has_dynamic := true
  in
  let rec loop = function
    | [] -> `Ok
    | attr :: rest -> (
        match analyze_attribute ~tag_name attr with
        | Invalid -> `Failed
        | Ok None -> loop rest
        | Ok (Some (Static_attr (info, _) | Optional_attr (info, _) | Dynamic_attr (info, _)))
          when attr_is_ignored_by_ssr info ->
            loop rest
        | Ok (Some (Static_attr (info, value))) ->
            Buffer.add_string static_buf (render_static_attr_with_info info value);
            loop rest
        | Ok (Some (Dynamic_attr (info, expr))) when info.kind = DomProps.Style -> (
            match extract_static_style expr with
            | Some rendered ->
                Buffer.add_string static_buf rendered;
                loop rest
            | None ->
                push_dynamic info expr ~is_optional:false;
                loop rest)
        | Ok (Some (Optional_attr (info, expr))) when attr_is_emittable info ->
            push_dynamic info expr ~is_optional:true;
            loop rest
        | Ok (Some (Dynamic_attr (info, expr))) when attr_is_emittable info ->
            push_dynamic info expr ~is_optional:false;
            loop rest
        | Ok (Some (Optional_attr _)) | Ok (Some (Dynamic_attr _)) -> `Failed)
  in
  match loop attrs with
  | `Failed -> Validation_failed
  | `Ok when !has_dynamic ->
      flush_static ();
      Mixed_attrs (List.rev !parts)
  | `Ok -> All_static (Buffer.contents static_buf)

let analyze_child (expr : expression) : static_part =
  match extract_react_text_literal expr with
  | Some s -> static_text (escape_html s)
  | None -> (
      match extract_literal_string expr with
      | Some s -> static_text (escape_html s)
      | None -> (
          match extract_react_int_literal expr with
          | Some i -> static_text (string_of_int i)
          | None -> (
              match extract_react_string_arg expr with
              | Some e -> Dynamic_string e
              | None -> (
                  match extract_react_int_arg expr with Some e -> Dynamic_int e | None -> Dynamic_element expr))))

let has_adjacent_text parts =
  let rec loop = function
    | Static_str a :: (Static_str b :: _ as rest) -> (a.ends_text && b.starts_text) || loop rest
    | _ :: rest -> loop rest
    | [] -> false
  in
  loop parts

let analyze_children children =
  match children with
  | None -> No_children
  | Some [] -> No_children
  | Some children ->
      let parts = List.map analyze_child children in
      let all_static = List.for_all (function Static_str _ -> true | _ -> false) parts in
      if all_static && not (has_adjacent_text parts) then (
        let buf = Buffer.create 128 in
        List.iter (function Static_str { html; _ } -> Buffer.add_string buf html | _ -> ()) parts;
        All_static_children (Buffer.contents buf))
      else Dynamic_children parts

let mixed_attrs_parts ~tag_name ~is_self_closing ~children_parts attr_parts =
  let open_prefix = static_markup (Printf.sprintf "<%s" tag_name) in
  if is_self_closing then open_prefix :: (attr_parts @ [ static_markup " />" ])
  else
    let close_tag = static_markup (Printf.sprintf "</%s>" tag_name) in
    open_prefix :: (attr_parts @ (static_markup ">" :: (children_parts @ [ close_tag ])))

let analyze_element ~tag_name ~attrs ~children =
  let attrs_result = analyze_attributes ~tag_name attrs in
  let children_result = analyze_children children in

  match (attrs_result, children_result) with
  | Validation_failed, _ -> Cannot_optimize
  | All_static attrs_html, No_children when Html.is_self_closing_tag tag_name ->
      let html = Printf.sprintf "<%s%s />" tag_name attrs_html in
      Fully_static html
  | All_static attrs_html, No_children ->
      let html = Printf.sprintf "<%s%s></%s>" tag_name attrs_html tag_name in
      Fully_static html
  | All_static attrs_html, All_static_children children_html ->
      let html = Printf.sprintf "<%s%s>%s</%s>" tag_name attrs_html children_html tag_name in
      Fully_static html
  | All_static attrs_html, Dynamic_children parts ->
      let open_tag = Printf.sprintf "<%s%s>" tag_name attrs_html in
      let close_tag = Printf.sprintf "</%s>" tag_name in
      let all_parts = static_markup open_tag :: (parts @ [ static_markup close_tag ]) in
      Needs_buffer (coalesce_static_parts all_parts)
  | Mixed_attrs attr_parts, No_children ->
      let parts =
        mixed_attrs_parts ~tag_name ~is_self_closing:(Html.is_self_closing_tag tag_name) ~children_parts:[] attr_parts
      in
      Needs_buffer (coalesce_static_parts parts)
  | Mixed_attrs attr_parts, All_static_children children_html ->
      let parts =
        mixed_attrs_parts ~tag_name ~is_self_closing:false ~children_parts:[ static_markup children_html ] attr_parts
      in
      Needs_buffer (coalesce_static_parts parts)
  | Mixed_attrs attr_parts, Dynamic_children children_parts ->
      let parts = mixed_attrs_parts ~tag_name ~is_self_closing:false ~children_parts attr_parts in
      Needs_buffer (coalesce_static_parts parts)

let maybe_add_doctype tag_name html = if tag_name = "html" then "<!DOCTYPE html>" ^ html else html
