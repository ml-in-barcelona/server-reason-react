An optional host-element prop must be emitted with its concrete option type so
that a bare `None`/`Some` inside the value expression disambiguates to `option`
even when a user type in scope shadows `None`. Both the `emit` fast path and the
`original` variant-tree thunk carry the `: string option` annotation.
  $ ../ppx.sh --output ml input.re
  type roundness = Full | None
  
  let link ~href =
   fun ~disabled ->
    (fun __jsx_value__001_ __jsx_value__002_ __jsx_value__003_ ->
      React.Writer
        {
          emit =
            (fun __buf ~separators:_ ->
              Buffer.add_string __buf "<a";
              Buffer.add_char __buf ' ';
              Buffer.add_string __buf "class";
              Buffer.add_string __buf "=\"";
              ReactDOM.escape_to_buffer __buf (__jsx_value__001_ : string);
              Buffer.add_char __buf '"';
              Buffer.add_string __buf " style=\"";
              ReactDOM.escape_to_buffer __buf
                (ReactDOM.Style.to_string (__jsx_value__002_ : ReactDOM.Style.t));
              Buffer.add_char __buf '"';
              (match (__jsx_value__003_ : string option) with
              | None -> ()
              | Some v ->
                  Buffer.add_char __buf ' ';
                  Buffer.add_string __buf "href";
                  Buffer.add_string __buf "=\"";
                  ReactDOM.escape_to_buffer __buf (v : string);
                  Buffer.add_char __buf '"');
              Buffer.add_string __buf ">x</a>";
              ());
          original =
            (fun () ->
              React.createElement "a"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     Some
                       (React.JSX.String
                          ("class", "className", (__jsx_value__001_ : string)));
                     Some (React.JSX.Style (__jsx_value__002_ : ReactDOM.Style.t));
                     (match (__jsx_value__003_ : string option) with
                     | None -> None
                     | Some v -> Some (React.JSX.String ("href", "href", v)));
                   ])
                [ React.string "x" ]);
        })
      (CSS.className x) (CSS.styles x)
      (match disabled with true -> None | false -> Some href [@explicit_arity])
