Styles expansion should run in native mode before DOM JSX is rewritten.
  $ ../ppx.sh --output ml input.re
  (fun __jsx_value__001_ __jsx_value__002_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__001_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__002_ : ReactDOM.Style.t));
            Buffer.add_char __buf '"';
            Buffer.add_string __buf "></div>";
            ());
        original =
          (fun () ->
            React.createElement "div"
              (Stdlib.List.filter_map Stdlib.Fun.id
                 [
                   Some
                     (React.JSX.String
                        ("class", "className", (__jsx_value__001_ : string)));
                   Some (React.JSX.Style (__jsx_value__002_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (CSS.className x) (CSS.styles x)
