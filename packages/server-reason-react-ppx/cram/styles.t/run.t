Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some (React.JSX.String ("class", "className", (fst x : string)));
         Some (React.JSX.Style (snd x : ReactDOM.Style.t));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         (match
            (match x with None -> None | Some x -> Some (fst x) : string option)
          with
         | None -> None
         | Some v -> Some (React.JSX.String ("class", "className", v)));
         (match
            (match x with None -> None | Some x -> Some (snd x)
              : ReactDOM.Style.t option)
          with
         | None -> None
         | Some v -> Some (React.JSX.Style v));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some
           (React.JSX.String
              ("class", "className", (fst x ^ " " ^ "lola" : string)));
         Some (React.JSX.Style (snd x : ReactDOM.Style.t));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some (React.JSX.String ("class", "className", (fst x : string)));
         Some
           (React.JSX.Style
              (ReactDOM.Style.combine
                 (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
                 (snd x)
                : ReactDOM.Style.t));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some
           (React.JSX.String
              ("class", "className", (fst x ^ " " ^ "lola" : string)));
         Some
           (React.JSX.Style
              (ReactDOM.Style.combine
                 (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
                 (snd x)
                : ReactDOM.Style.t));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some
           (React.JSX.String
              ( "class",
                "className",
                (match match x with None -> None | Some x -> Some (fst x) with
                 | None -> "lola"
                 | Some x -> x ^ " " ^ "lola"
                  : string) ));
         (match
            (match x with None -> None | Some x -> Some (snd x)
              : ReactDOM.Style.t option)
          with
         | None -> None
         | Some v -> Some (React.JSX.Style v));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         (match
            (match x with None -> None | Some x -> Some (fst x) : string option)
          with
         | None -> None
         | Some v -> Some (React.JSX.String ("class", "className", v)));
         Some
           (React.JSX.Style
              (match match x with None -> None | Some x -> Some (snd x) with
               | None -> ReactDOM.Style.make ~backgroundColor:"gainsboro" ()
               | Some x ->
                   ReactDOM.Style.combine
                     (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
                     x
                : ReactDOM.Style.t));
       ])
    []
  ;;
  
  React.createElement "div"
    (Stdlib.List.filter_map Stdlib.Fun.id
       [
         Some
           (React.JSX.String
              ( "class",
                "className",
                (match match x with None -> None | Some x -> Some (fst x) with
                 | None -> "lola"
                 | Some x -> x ^ " " ^ "lola"
                  : string) ));
         Some
           (React.JSX.Style
              (match match x with None -> None | Some x -> Some (snd x) with
               | None -> ReactDOM.Style.make ~backgroundColor:"gainsboro" ()
               | Some x ->
                   ReactDOM.Style.combine
                     (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
                     x
                : ReactDOM.Style.t));
       ])
    []
