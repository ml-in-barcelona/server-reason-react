let make ~loc attributes =
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
