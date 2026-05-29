let is_jsx_attribute { Ppxlib.attr_name; _ } = attr_name.txt = "JSX"
let has_jsx_attribute apply_expr = List.exists is_jsx_attribute apply_expr.Ppxlib.pexp_attributes
let is_lowercase_name name = String.length name > 0 && match name.[0] with 'a' .. 'z' -> true | _ -> false

let is_lowercase_html_tag_call fn =
  match fn.Ppxlib.pexp_desc with
  | Ppxlib.Pexp_ident { txt = Ppxlib.Lident name; _ } -> is_lowercase_name name
  | _ -> false

let should_expand_apply apply_expr =
  match apply_expr.Ppxlib.pexp_desc with
  | Ppxlib.Pexp_apply (fn, _) -> has_jsx_attribute apply_expr && is_lowercase_html_tag_call fn
  | _ -> false

let expand_attributes ~loc attributes =
  let merge_className current_className (label, expr) =
    match current_className with
    | Some (existing_label, existing_expr) ->
        let merged =
          match label with
          | Ppxlib.Optional "className" ->
              [%expr match [%e expr] with None -> [%e existing_expr] | Some x -> x ^ " " ^ [%e existing_expr]]
          | _ -> [%expr [%e expr] ^ " " ^ [%e existing_expr]]
        in
        Some (existing_label, merged)
    | None -> Some (label, expr)
  in
  let merge_style current_style (label, expr) =
    match current_style with
    | Some (existing_label, existing_expr) ->
        let merged =
          match label with
          | Ppxlib.Optional "style" ->
              [%expr
                match [%e expr] with
                | None -> [%e existing_expr]
                | Some x -> ReactDOM.Style.combine [%e existing_expr] x]
          | _ -> [%expr ReactDOM.Style.combine [%e existing_expr] [%e expr]]
        in
        Some (existing_label, merged)
    | None -> Some (label, expr)
  in
  let handle_styles className style label arg =
    let className_label, className_expr, style_label, style_expr =
      match label with
      | Ppxlib.Labelled "styles" ->
          (Ppxlib.Labelled "className", [%expr fst [%e arg]], Ppxlib.Labelled "style", [%expr snd [%e arg]])
      | _ ->
          ( Ppxlib.Optional "className",
            [%expr match [%e arg] with None -> None | Some x -> Some (fst x)],
            Ppxlib.Optional "style",
            [%expr match [%e arg] with None -> None | Some x -> Some (snd x)] )
    in
    (merge_className className (className_label, className_expr), merge_style style (style_label, style_expr))
  in
  let rec aux (className, style, other_args) args =
    match args with
    | [] ->
        let rest = List.rev other_args in
        ([ className; style ] |> List.filter_map Stdlib.Fun.id) @ rest
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

let make ~loc ~apply_expr attributes =
  if should_expand_apply apply_expr then expand_attributes ~loc attributes else attributes

let make_expression apply_expr =
  match apply_expr.Ppxlib.pexp_desc with
  | Ppxlib.Pexp_apply (({ pexp_loc = loc; _ } as fn), attributes) when should_expand_apply apply_expr ->
      { apply_expr with pexp_desc = Ppxlib.Pexp_apply (fn, expand_attributes ~loc attributes) }
  | _ -> apply_expr
