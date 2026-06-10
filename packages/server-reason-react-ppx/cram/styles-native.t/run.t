Styles expansion should run in native mode before DOM JSX is rewritten.
  $ ../ppx.sh --output ml input.re
  React.Writer
    {
      emit =
        (fun b ->
          Buffer.add_string b "<div";
          Buffer.add_char b ' ';
          Buffer.add_string b "class";
          Buffer.add_string b "=\"";
          ReactDOM.escape_to_buffer b (fst x : string);
          Buffer.add_char b '"';
          Buffer.add_string b " style=\"";
          ReactDOM.Style.write_to_buffer b (snd x : ReactDOM.Style.t);
          Buffer.add_char b '"';
          Buffer.add_string b "></div>";
          ());
      original =
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Stdlib.Fun.id
               [
                 Some (React.JSX.String ("class", "className", (fst x : string)));
                 Some (React.JSX.Style (snd x : ReactDOM.Style.t));
               ])
            []);
    }
