An optional host-element prop must be emitted with its concrete option type so
that a bare `None`/`Some` inside the value expression disambiguates to `option`
even when a user type in scope shadows `None`. Both the `emit` fast path and the
`original` variant-tree thunk carry the `: string option` annotation.
  $ ../ppx.sh --output ml input.re
  type roundness = Full | None
  
  let link ~href =
   fun ~disabled ->
    React.Writer
      {
        emit =
          (fun b ->
            Buffer.add_string b "<a";
            Buffer.add_char b ' ';
            Buffer.add_string b "class";
            Buffer.add_string b "=\"";
            ReactDOM.escape_to_buffer b (fst x : string);
            Buffer.add_char b '"';
            Buffer.add_string b " style=\"";
            ReactDOM.escape_to_buffer b
              (ReactDOM.Style.to_string (snd x : ReactDOM.Style.t));
            Buffer.add_char b '"';
            (match
               (match disabled with
                | true -> None
                | false -> Some href [@explicit_arity]
                 : string option)
             with
            | None -> ()
            | Some v ->
                Buffer.add_char b ' ';
                Buffer.add_string b "href";
                Buffer.add_string b "=\"";
                ReactDOM.escape_to_buffer b (v : string);
                Buffer.add_char b '"');
            Buffer.add_string b ">x</a>";
            ());
        original =
          (fun () ->
            React.createElement "a"
              (Stdlib.List.filter_map Stdlib.Fun.id
                 [
                   Some
                     (React.JSX.String ("class", "className", (fst x : string)));
                   Some (React.JSX.Style (snd x : ReactDOM.Style.t));
                   (match
                      (match disabled with
                       | true -> None
                       | false -> Some href [@explicit_arity]
                        : string option)
                    with
                   | None -> None
                   | Some v -> Some (React.JSX.String ("href", "href", v)));
                 ])
              [ React.string "x" ]);
      }
