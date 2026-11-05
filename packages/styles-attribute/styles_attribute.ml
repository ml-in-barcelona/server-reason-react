let is_jsx_attribute { Ppxlib.attr_name; _ } = attr_name.txt = "JSX"
let has_jsx_attribute apply_expr = List.exists is_jsx_attribute apply_expr.Ppxlib.pexp_attributes
let is_lowercase_name name = String.length name > 0 && match name.[0] with 'a' .. 'z' -> true | _ -> false

let is_lowercase_html_tag_call (fn : Ppxlib.expression) =
  match fn.pexp_desc with Pexp_ident { txt = Lident name; _ } -> is_lowercase_name name | _ -> false

let should_expand_apply (apply_expr : Ppxlib.expression) =
  match apply_expr.pexp_desc with
  | Pexp_apply (fn, _) -> has_jsx_attribute apply_expr && is_lowercase_html_tag_call fn
  | _ -> false

let expand_attributes ~loc attributes =
  let is_optional = function Ppxlib.Optional _ -> true | Ppxlib.Labelled _ | Ppxlib.Nolabel -> false in
  (* The generated binders are reserved names, so user expressions in either side cannot be captured. *)
  let merge ~name ~combine current (label, expr) =
    match current with
    | None -> Some (label, expr)
    | Some (existing_label, existing_expr) -> (
        match (is_optional existing_label, is_optional label) with
        | false, false -> Some (existing_label, combine expr existing_expr)
        | false, true ->
            Some
              ( existing_label,
                [%expr
                  let __existing = [%e existing_expr] in
                  match [%e expr] with
                  | None -> __existing
                  | Some __incoming -> [%e combine [%expr __incoming] [%expr __existing]]] )
        | true, false ->
            Some
              ( Ppxlib.Labelled name,
                [%expr
                  let __incoming = [%e expr] in
                  match [%e existing_expr] with
                  | None -> __incoming
                  | Some __existing -> [%e combine [%expr __incoming] [%expr __existing]]] )
        | true, true ->
            Some
              ( existing_label,
                [%expr
                  match ([%e expr], [%e existing_expr]) with
                  | None, None -> None
                  | Some __incoming, None -> Some __incoming
                  | None, Some __existing -> Some __existing
                  | Some __incoming, Some __existing -> Some [%e combine [%expr __incoming] [%expr __existing]]] ))
  in
  let merge_className =
    merge ~name:"className" ~combine:(fun incoming existing -> [%expr [%e incoming] ^ " " ^ [%e existing]])
  in
  let merge_style =
    merge ~name:"style" ~combine:(fun incoming existing -> [%expr ReactDOM.Style.combine [%e existing] [%e incoming]])
  in
  let handle_styles className style label arg =
    let className_label, className_expr, style_label, style_expr =
      match label with
      | Ppxlib.Labelled "styles" ->
          ( Ppxlib.Labelled "className",
            [%expr CSS.className [%e arg]],
            Ppxlib.Labelled "style",
            [%expr CSS.styles [%e arg]] )
      | _ ->
          ( Ppxlib.Optional "className",
            [%expr match [%e arg] with None -> None | Some x -> Some (CSS.className x)],
            Ppxlib.Optional "style",
            [%expr match [%e arg] with None -> None | Some x -> Some (CSS.styles x)] )
    in
    (merge_className className (className_label, className_expr), merge_style style (style_label, style_expr))
  in
  let rec aux (className, style, other_args) args =
    match args with
    | [] -> (
        let rest = List.rev other_args in
        match (className, style) with
        | Some c, Some s -> c :: s :: rest
        | Some c, None -> c :: rest
        | None, Some s -> s :: rest
        | None, None -> rest)
    | (label, arg) :: rest -> (
        match label with
        | Ppxlib.Labelled "className" | Ppxlib.Optional "className" ->
            aux (merge_className className (label, arg), style, other_args) rest
        | Ppxlib.Labelled "style" | Ppxlib.Optional "style" ->
            aux (className, merge_style style (label, arg), other_args) rest
        | Ppxlib.Labelled "styles" | Ppxlib.Optional "styles" ->
            let new_className, new_style = handle_styles className style label arg in
            aux (new_className, new_style, other_args) rest
        | _ -> aux (className, style, (label, arg) :: other_args) rest)
  in
  aux (None, None, []) attributes

let expand (expr : Ppxlib.expression) =
  match expr.pexp_desc with
  | Pexp_apply (({ pexp_loc = loc; _ } as tag), attributes) when should_expand_apply expr ->
      let new_attributes = expand_attributes ~loc attributes in
      { expr with pexp_desc = Pexp_apply (tag, new_attributes) }
  | _ -> expr
