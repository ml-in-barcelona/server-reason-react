open Ppxlib

type static_attr_value = Static_string of string | Static_int of int | Static_bool of bool

(* [is_event] distinguishes real attributes from synthetic [Event] entries
   whose [kind] has been coerced to [String] for downstream code that only
   cares about the HTML serialization shape. Events must never be inlined
   into a [Writer.emit] body because their runtime value is a function,
   not a string.

   See [React.Writer] (React.ml). *)
type attr_render_info = { html_name : string; is_boolean : bool; kind : DomProps.attributeType; is_event : bool }

(* A [static_part] is the unit of work inside a [React.Writer.emit] function:
   either a pre-baked string or a hole that must be filled at render time.

   [Dynamic_attr_slot] emits an attribute (possibly zero width) based on a
   runtime expression. [~is_optional] distinguishes [?foo] (expression is an
   [option]) from [foo={...}] (expression is the unwrapped value). The
   emission side uses [kind] from [info] to pick the right runtime
   serialization. *)
type static_part =
  | Static_str of string
  | Dynamic_string of expression
  | Dynamic_int of expression
  | Dynamic_float of expression
  | Dynamic_element of expression
  | Dynamic_attr_slot of { info : attr_render_info; expr : expression; is_optional : bool }

type parsed_attr =
  | Static_attr of attr_render_info * static_attr_value
  | Optional_attr of attr_render_info * expression
  | Dynamic_attr of attr_render_info * expression

type attr_validation_result = Valid_attr of attr_render_info | Invalid_attr
type attr_analysis_result = Ok of parsed_attr option | Invalid

(* [attrs_analysis] carries either a pre-baked static attribute string or a
   list of ordered parts mixing static runs with dynamic-attribute slots.
   The list preserves source order so the emitted HTML is deterministic. *)
type attrs_analysis = All_static of string | Mixed_attrs of static_part list | Validation_failed

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

(* Wrap [Html.escape] to return a [string] since call sites here build
   PPX-time strings. Runtime code paths keep using [Html.escape]/
   [ReactDOM.escape_to_buffer] directly to avoid the intermediate string. *)
let escape_html s =
  let buf = Buffer.create (String.length s) in
  Html.escape buf s;
  Buffer.contents buf

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

(* Attribute kinds whose runtime emission we know how to inline into a
   [React.Writer.emit] body. [String], [Int], [Bool], and [BooleanishString] all
   serialize to " name=\"value\"" (or nothing, for false booleans) via a
   small, well-defined rule set mirroring [ReactDOM.write_attribute_to_buffer].

   [Action], [Style], [Ref], and [InnerHtml] have more complex semantics
   (variant dispatch, style serialization, DOM-ref handling, or zero-render
   for events). We leave those on the variant-tree path by treating any such
   non-literal attribute as forcing [Validation_failed], which collapses the
   element to [Cannot_optimize]. Same behavior as before this change — we
   only widen what succeeds, never what fails. *)
let is_lowerable_kind = function
  | DomProps.String | DomProps.Int | DomProps.Bool | DomProps.BooleanishString -> true
  | DomProps.Action | DomProps.Style | DomProps.Ref | DomProps.InnerHtml -> false

(* Kept in lock-step with [ReactDOM.is_react_custom_attribute] so the set is
   audit-identical. In practice only ["suppressContentEditableWarning"] and
   ["suppressHydrationWarning"] are load-bearing here: ["ref"] and ["key"]
   are already filtered in [analyze_attribute], and ["dangerouslySetInnerHTML"]
   has kind [InnerHtml] which [is_lowerable_kind] already rejects. *)
let is_react_custom_attribute_name = function
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning" | "suppressHydrationWarning" -> true
  | _ -> false

(* An attribute is emittable into a [Writer.emit] body iff its kind has a
   well-defined buffer-write shape mirroring
   [ReactDOM.write_attribute_to_buffer], and its name is not one the
   runtime discards. *)
let attr_is_emittable (info : attr_render_info) =
  (not info.is_event) && is_lowerable_kind info.kind && not (is_react_custom_attribute_name info.html_name)

let analyze_attributes ~tag_name attrs =
  (* Walk left-to-right, accumulating static HTML into [static_buf] between
     dynamic slots. On hitting a dynamic/optional attr we flush the buffer
     into a [Static_str] part, then append a [Dynamic_attr_slot] part.
     On success we return the coalesced part list; on any lowerability
     failure we return [`Failed] (caller maps to [Validation_failed] then
     [Cannot_optimize]). *)
  let parts = ref [] in
  let static_buf = Buffer.create 64 in
  let has_dynamic = ref false in
  let flush_static () =
    if Buffer.length static_buf > 0 then begin
      parts := Static_str (Buffer.contents static_buf) :: !parts;
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
        | Ok (Some (Static_attr (info, value))) ->
            Buffer.add_string static_buf (render_static_attr_with_info info value);
            loop rest
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

(* Classify a child expression. Ordered so the cheapest and most-specific
   extractors run first; the generic [Dynamic_element] is the fallback.
   Sequential [match] avoids allocating a closure list per child (the
   earlier [List.find_map] form allocated 8 thunks + 8 cons cells). *)
let analyze_child (expr : expression) : static_part =
  match extract_unsafe_literal expr with
  | Some s -> Static_str s
  | None -> (
      match extract_react_text_literal expr with
      | Some s -> Static_str (escape_html s)
      | None -> (
          match extract_literal_string expr with
          | Some s -> Static_str (escape_html s)
          | None -> (
              match extract_react_int_literal expr with
              | Some i -> Static_str (string_of_int i)
              | None -> (
                  match extract_react_float_literal expr with
                  | Some f -> Static_str (Float.to_string f)
                  | None -> (
                      match extract_react_string_arg expr with
                      | Some e -> Dynamic_string e
                      | None -> (
                          match extract_react_int_arg expr with
                          | Some e -> Dynamic_int e
                          | None -> (
                              match extract_react_float_arg expr with
                              | Some e -> Dynamic_float e
                              | None -> Dynamic_element expr)))))))

(* Caller [analyze_element] always runs [coalesce_static_parts] on the
   combined [open_tag; ...children...; close_tag] list, so returning
   un-coalesced children here just means the merge happens once downstream
   instead of twice. *)
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
      else if not has_element_dynamic then All_string_dynamic parts
      else Mixed_children parts

(* Build the ordered [static_part list] for a lower-case element whose
   attributes are partly dynamic. [attr_parts] is the output of
   [analyze_attributes] in [Mixed_attrs]: an alternating sequence of
   [Static_str] (literal attribute runs) and [Dynamic_attr_slot] (runtime
   holes). We wrap it between the opening "<tag" and closing ">" (or " />"
   for self-closing tags), then append the children parts and the closing
   tag. *)
let mixed_attrs_parts ~tag_name ~is_self_closing ~children_parts attr_parts =
  let open_prefix = Static_str (Printf.sprintf "<%s" tag_name) in
  if is_self_closing then open_prefix :: (attr_parts @ [ Static_str " />" ])
  else
    let close_tag = Static_str (Printf.sprintf "</%s>" tag_name) in
    open_prefix :: (attr_parts @ (Static_str ">" :: (children_parts @ [ close_tag ])))

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
  | All_static attrs_html, All_string_dynamic parts ->
      let open_tag = Printf.sprintf "<%s%s>" tag_name attrs_html in
      let close_tag = Printf.sprintf "</%s>" tag_name in
      let all_parts = Static_str open_tag :: (parts @ [ Static_str close_tag ]) in
      Needs_string_concat (coalesce_static_parts all_parts)
  | All_static attrs_html, Mixed_children parts ->
      let open_tag = Printf.sprintf "<%s%s>" tag_name attrs_html in
      let close_tag = Printf.sprintf "</%s>" tag_name in
      let all_parts = Static_str open_tag :: (parts @ [ Static_str close_tag ]) in
      Needs_buffer (coalesce_static_parts all_parts)
  | Mixed_attrs attr_parts, No_children ->
      let parts =
        mixed_attrs_parts ~tag_name ~is_self_closing:(Html.is_self_closing_tag tag_name) ~children_parts:[] attr_parts
      in
      Needs_buffer (coalesce_static_parts parts)
  | Mixed_attrs attr_parts, All_static_children children_html ->
      let parts =
        mixed_attrs_parts ~tag_name ~is_self_closing:false ~children_parts:[ Static_str children_html ] attr_parts
      in
      Needs_buffer (coalesce_static_parts parts)
  | Mixed_attrs attr_parts, All_string_dynamic children_parts | Mixed_attrs attr_parts, Mixed_children children_parts ->
      let parts = mixed_attrs_parts ~tag_name ~is_self_closing:false ~children_parts attr_parts in
      Needs_buffer (coalesce_static_parts parts)

let maybe_add_doctype tag_name html = if tag_name = "html" then "<!DOCTYPE html>" ^ html else html
