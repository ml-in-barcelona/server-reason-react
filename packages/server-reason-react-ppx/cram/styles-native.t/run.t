Styles expansion should run in native mode before DOM JSX is rewritten.
  $ ../ppx.sh --output ml input.re
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some (React.JSX.String ("class", "className", (fst x : string)));
         Some (React.JSX.Style (snd x : ReactDOM.Style.t));
       ])
    []
