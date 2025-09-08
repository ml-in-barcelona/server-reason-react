Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  React.createElementWithKey ~key:None "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some (React.JSX.String ("class", "className", (fst x : string)));
         Some (React.JSX.Style (snd x : ReactDOM.Style.t));
       ])
    []
