open Ppxlib

type static_part =
  | Static_str of string
  | Dynamic_string of expression
  | Dynamic_int of expression
  | Dynamic_float of expression
  | Dynamic_element of expression

type static_attr_value = Static_string of string | Static_int of int | Static_bool of bool
type attr_render_info = { html_name : string; is_boolean : bool; kind : DomProps.attributeType }

type parsed_attr =
  | Static_attr of attr_render_info * static_attr_value
  | Optional_attr of attr_render_info * expression
  | Dynamic_attr of string * expression

type attr_validation_result = Valid_attr of attr_render_info | Invalid_attr
type attr_analysis_result = Ok of parsed_attr option | Invalid

type attrs_analysis =
  | All_static of string
  | Has_optional of (attr_render_info * expression) list * string
  | Has_dynamic
  | Validation_failed

type children_analysis =
  | No_children
  | All_static_children of string
  | All_string_dynamic of static_part list
  | Mixed_children of static_part list

type element_analysis =
  | Fully_static of string
  | Needs_string_concat of static_part list
  | Needs_buffer of static_part list
  | Cannot_optimize

let rec coalesce_static_parts = function
  | Static_str a :: Static_str b :: rest -> coalesce_static_parts (Static_str (a ^ b) :: rest)
  | x :: rest -> x :: coalesce_static_parts rest
  | [] -> []

let escape_html s =
  let len = String.length s in
  let buf = Buffer.create (len * 2) in
  for i = 0 to len - 1 do
    match s.[i] with
    | '&' -> Buffer.add_string buf "&amp;"
    | '<' -> Buffer.add_string buf "&lt;"
    | '>' -> Buffer.add_string buf "&gt;"
    | '\'' -> Buffer.add_string buf "&apos;"
    | '"' -> Buffer.add_string buf "&quot;"
    | c -> Buffer.add_char buf c
  done;
  Buffer.contents buf

(* Must match Html.is_self_closing_tag *)
let is_self_closing_tag = function
  | "area" | "base" | "basefont" | "bgsound" | "br" | "col" | "command" | "embed" | "frame" | "hr" | "image" | "img"
  | "input" | "keygen" | "link" | "meta" | "param" | "source" | "track" | "wbr" ->
      true
  | _ -> false

let rec extract_literal_string expr =
  match expr.pexp_desc with
  | Pexp_constant (Pconst_string (s, _, _)) -> Some s
  | Pexp_constraint (inner, _) -> extract_literal_string inner
  | _ -> None

let rec extract_literal_int expr =
  match expr.pexp_desc with
  | Pexp_constant (Pconst_integer (s, _)) -> ( try Some (int_of_string s) with _ -> None)
  | Pexp_constraint (inner, _) -> extract_literal_int inner
  | _ -> None

let rec extract_literal_float expr =
  match expr.pexp_desc with
  | Pexp_constant (Pconst_float (s, _)) -> ( try Some (float_of_string s) with _ -> None)
  | Pexp_constraint (inner, _) -> extract_literal_float inner
  | _ -> None

let rec extract_literal_bool expr =
  match expr.pexp_desc with
  | Pexp_construct ({ txt = Lident "true"; _ }, None) -> Some true
  | Pexp_construct ({ txt = Lident "false"; _ }, None) -> Some false
  | Pexp_constraint (inner, _) -> extract_literal_bool inner
  | _ -> None

let extract_react_string_arg expr =
  match expr.pexp_desc with
  | Pexp_apply
      ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "React", ("string" | "text")); _ }; _ }, [ (Nolabel, arg) ]) ->
      Some arg
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident ("string" | "text"); _ }; _ }, [ (Nolabel, arg) ]) -> Some arg
  | _ -> None

let extract_react_int_arg expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "React", "int"); _ }; _ }, [ (Nolabel, arg) ]) -> Some arg
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "int"; _ }; _ }, [ (Nolabel, arg) ]) -> Some arg
  | _ -> None

let extract_react_float_arg expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "React", "float"); _ }; _ }, [ (Nolabel, arg) ]) ->
      Some arg
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "float"; _ }; _ }, [ (Nolabel, arg) ]) -> Some arg
  | _ -> None

let extract_react_text_literal expr =
  match extract_react_string_arg expr with Some arg -> extract_literal_string arg | None -> None

let extract_react_int_literal expr =
  match extract_react_int_arg expr with Some arg -> extract_literal_int arg | None -> None

let extract_react_float_literal expr =
  match extract_react_float_arg expr with Some arg -> extract_literal_float arg | None -> None

let extract_unsafe_literal expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Ldot (Lident "Html", "raw"); _ }; _ }, [ (Nolabel, arg) ]) ->
      extract_literal_string arg
  | _ -> None

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
      let html_name, kind =
        match prop with
        | DomProps.Attribute { name; type_; _ } -> (name, type_)
        | DomProps.Event { jsxName; _ } -> (jsxName, DomProps.String)
      in
      let is_boolean = kind = DomProps.Bool in
      Valid_attr { html_name; is_boolean; kind }

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
              | None -> Ok (Some (Dynamic_attr (info.html_name, expr))))))

let analyze_attributes ~tag_name attrs =
  let rec loop static_buf optionals = function
    | [] ->
        if optionals = [] then All_static (Buffer.contents static_buf)
        else Has_optional (List.rev optionals, Buffer.contents static_buf)
    | attr :: rest -> (
        match analyze_attribute ~tag_name attr with
        | Invalid -> Validation_failed
        | Ok None -> loop static_buf optionals rest
        | Ok (Some (Static_attr (info, value))) ->
            Buffer.add_string static_buf (render_static_attr_with_info info value);
            loop static_buf optionals rest
        | Ok (Some (Optional_attr (info, expr))) -> loop static_buf ((info, expr) :: optionals) rest
        | Ok (Some (Dynamic_attr _)) -> Has_dynamic)
  in
  loop (Buffer.create 64) [] attrs

let analyze_child (expr : expression) : static_part =
  let extractions =
    [
      (fun () -> extract_unsafe_literal expr |> Option.map (fun s -> Static_str s));
      (fun () -> extract_react_text_literal expr |> Option.map (fun s -> Static_str (escape_html s)));
      (fun () -> extract_literal_string expr |> Option.map (fun s -> Static_str (escape_html s)));
      (fun () -> extract_react_int_literal expr |> Option.map (fun i -> Static_str (string_of_int i)));
      (fun () -> extract_react_float_literal expr |> Option.map (fun f -> Static_str (Float.to_string f)));
      (fun () -> extract_react_string_arg expr |> Option.map (fun e -> Dynamic_string e));
      (fun () -> extract_react_int_arg expr |> Option.map (fun e -> Dynamic_int e));
      (fun () -> extract_react_float_arg expr |> Option.map (fun e -> Dynamic_float e));
    ]
  in
  List.find_map (fun f -> f ()) extractions |> Option.value ~default:(Dynamic_element expr)

let analyze_children children =
  match children with
  | None -> No_children
  | Some [] -> No_children
  | Some children ->
      let parts = List.map analyze_child children in
      let all_static = List.for_all (function Static_str _ -> true | _ -> false) parts in
      let has_element_dynamic = List.exists (function Dynamic_element _ -> true | _ -> false) parts in
      if all_static then (
        let buf = Buffer.create 128 in
        List.iter (function Static_str s -> Buffer.add_string buf s | _ -> ()) parts;
        All_static_children (Buffer.contents buf))
      else if not has_element_dynamic then All_string_dynamic (coalesce_static_parts parts)
      else Mixed_children (coalesce_static_parts parts)

let analyze_element ~tag_name ~attrs ~children =
  let attrs_result = analyze_attributes ~tag_name attrs in
  let children_result = analyze_children children in

  match (attrs_result, children_result) with
  | Validation_failed, _ -> Cannot_optimize
  | Has_dynamic, _ -> Cannot_optimize
  | Has_optional _, _ -> Cannot_optimize
  | All_static attrs_html, No_children when is_self_closing_tag tag_name ->
      let html = Printf.sprintf "<%s%s />" tag_name attrs_html in
      Fully_static html
  | All_static attrs_html, No_children ->
      let html = Printf.sprintf "<%s%s></%s>" tag_name attrs_html tag_name in
      Fully_static html
  | All_static attrs_html, All_static_children children_html ->
      let html = Printf.sprintf "<%s%s>%s</%s>" tag_name attrs_html children_html tag_name in
      Fully_static html
  | All_static attrs_html, All_string_dynamic parts ->
      let open_tag = Printf.sprintf "<%s%s>" tag_name attrs_html in
      let close_tag = Printf.sprintf "</%s>" tag_name in
      let all_parts = [ Static_str open_tag ] @ parts @ [ Static_str close_tag ] in
      Needs_string_concat (coalesce_static_parts all_parts)
  | All_static attrs_html, Mixed_children parts ->
      let open_tag = Printf.sprintf "<%s%s>" tag_name attrs_html in
      let close_tag = Printf.sprintf "</%s>" tag_name in
      let all_parts = [ Static_str open_tag ] @ parts @ [ Static_str close_tag ] in
      Needs_buffer (coalesce_static_parts all_parts)

let maybe_add_doctype tag_name html = if tag_name = "html" then "<!DOCTYPE html>" ^ html else html
