Styles expansion should run in native mode before DOM JSX is rewritten.
  $ ../ppx.sh --output ml input.re
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf (CSS.className x : string);
          Buffer.add_char __buf '"';
          Buffer.add_string __buf " style=\"";
          ReactDOM.escape_to_buffer __buf
            (ReactDOM.Style.to_string (CSS.styles x : ReactDOM.Style.t));
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
                      ("class", "className", (CSS.className x : string)));
                 Some (React.JSX.Style (CSS.styles x : ReactDOM.Style.t));
               ])
            []);
    }
