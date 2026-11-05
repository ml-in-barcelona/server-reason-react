Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
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
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          (match
             (match x with None -> None | Some x -> Some (CSS.className x)
               : string option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_char __buf ' ';
              Buffer.add_string __buf "class";
              Buffer.add_string __buf "=\"";
              ReactDOM.escape_to_buffer __buf (v : string);
              Buffer.add_char __buf '"');
          (match
             (match x with None -> None | Some x -> Some (CSS.styles x)
               : ReactDOM.Style.t option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_string __buf " style=\"";
              ReactDOM.escape_to_buffer __buf
                (ReactDOM.Style.to_string (v : ReactDOM.Style.t));
              Buffer.add_char __buf '"');
          Buffer.add_string __buf "></div>";
          ());
      original =
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Stdlib.Fun.id
               [
                 (match
                    (match x with
                     | None -> None
                     | Some x -> Some (CSS.className x)
                      : string option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.String ("class", "className", v)));
                 (match
                    (match x with None -> None | Some x -> Some (CSS.styles x)
                      : ReactDOM.Style.t option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.Style v));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf
            (CSS.className x ^ " " ^ "lola" : string);
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
                      ( "class",
                        "className",
                        (CSS.className x ^ " " ^ "lola" : string) ));
                 Some (React.JSX.Style (CSS.styles x : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
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
            (ReactDOM.Style.to_string
               (ReactDOM.Style.combine
                  (("background-color", "backgroundColor", "gainsboro")
                   :: ([] : (string * string * string) list)
                    : ReactDOM.Style.t)
                  (CSS.styles x)
                 : ReactDOM.Style.t));
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
                 Some
                   (React.JSX.Style
                      (ReactDOM.Style.combine
                         (("background-color", "backgroundColor", "gainsboro")
                          :: ([] : (string * string * string) list)
                           : ReactDOM.Style.t)
                         (CSS.styles x)
                        : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf
            (CSS.className x ^ " " ^ "lola" : string);
          Buffer.add_char __buf '"';
          Buffer.add_string __buf " style=\"";
          ReactDOM.escape_to_buffer __buf
            (ReactDOM.Style.to_string
               (ReactDOM.Style.combine
                  (("background-color", "backgroundColor", "gainsboro")
                   :: ([] : (string * string * string) list)
                    : ReactDOM.Style.t)
                  (CSS.styles x)
                 : ReactDOM.Style.t));
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
                      ( "class",
                        "className",
                        (CSS.className x ^ " " ^ "lola" : string) ));
                 Some
                   (React.JSX.Style
                      (ReactDOM.Style.combine
                         (("background-color", "backgroundColor", "gainsboro")
                          :: ([] : (string * string * string) list)
                           : ReactDOM.Style.t)
                         (CSS.styles x)
                        : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf
            (let __existing = "lola" in
             match
               match x with None -> None | Some x -> Some (CSS.className x)
             with
             | None -> __existing
             | Some __incoming -> __incoming ^ " " ^ __existing
              : string);
          Buffer.add_char __buf '"';
          (match
             (match x with None -> None | Some x -> Some (CSS.styles x)
               : ReactDOM.Style.t option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_string __buf " style=\"";
              ReactDOM.escape_to_buffer __buf
                (ReactDOM.Style.to_string (v : ReactDOM.Style.t));
              Buffer.add_char __buf '"');
          Buffer.add_string __buf "></div>";
          ());
      original =
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Stdlib.Fun.id
               [
                 Some
                   (React.JSX.String
                      ( "class",
                        "className",
                        (let __existing = "lola" in
                         match
                           match x with
                           | None -> None
                           | Some x -> Some (CSS.className x)
                         with
                         | None -> __existing
                         | Some __incoming -> __incoming ^ " " ^ __existing
                          : string) ));
                 (match
                    (match x with None -> None | Some x -> Some (CSS.styles x)
                      : ReactDOM.Style.t option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.Style v));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          (match
             (match x with None -> None | Some x -> Some (CSS.className x)
               : string option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_char __buf ' ';
              Buffer.add_string __buf "class";
              Buffer.add_string __buf "=\"";
              ReactDOM.escape_to_buffer __buf (v : string);
              Buffer.add_char __buf '"');
          Buffer.add_string __buf " style=\"";
          ReactDOM.escape_to_buffer __buf
            (ReactDOM.Style.to_string
               (let __existing =
                  (("background-color", "backgroundColor", "gainsboro")
                   :: ([] : (string * string * string) list)
                    : ReactDOM.Style.t)
                in
                match
                  match x with None -> None | Some x -> Some (CSS.styles x)
                with
                | None -> __existing
                | Some __incoming -> ReactDOM.Style.combine __existing __incoming
                 : ReactDOM.Style.t));
          Buffer.add_char __buf '"';
          Buffer.add_string __buf "></div>";
          ());
      original =
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Stdlib.Fun.id
               [
                 (match
                    (match x with
                     | None -> None
                     | Some x -> Some (CSS.className x)
                      : string option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.String ("class", "className", v)));
                 Some
                   (React.JSX.Style
                      (let __existing =
                         (("background-color", "backgroundColor", "gainsboro")
                          :: ([] : (string * string * string) list)
                           : ReactDOM.Style.t)
                       in
                       match
                         match x with
                         | None -> None
                         | Some x -> Some (CSS.styles x)
                       with
                       | None -> __existing
                       | Some __incoming ->
                           ReactDOM.Style.combine __existing __incoming
                        : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf
            (let __existing = "lola" in
             match
               match x with None -> None | Some x -> Some (CSS.className x)
             with
             | None -> __existing
             | Some __incoming -> __incoming ^ " " ^ __existing
              : string);
          Buffer.add_char __buf '"';
          Buffer.add_string __buf " style=\"";
          ReactDOM.escape_to_buffer __buf
            (ReactDOM.Style.to_string
               (let __existing =
                  (("background-color", "backgroundColor", "gainsboro")
                   :: ([] : (string * string * string) list)
                    : ReactDOM.Style.t)
                in
                match
                  match x with None -> None | Some x -> Some (CSS.styles x)
                with
                | None -> __existing
                | Some __incoming -> ReactDOM.Style.combine __existing __incoming
                 : ReactDOM.Style.t));
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
                      ( "class",
                        "className",
                        (let __existing = "lola" in
                         match
                           match x with
                           | None -> None
                           | Some x -> Some (CSS.className x)
                         with
                         | None -> __existing
                         | Some __incoming -> __incoming ^ " " ^ __existing
                          : string) ));
                 Some
                   (React.JSX.Style
                      (let __existing =
                         (("background-color", "backgroundColor", "gainsboro")
                          :: ([] : (string * string * string) list)
                           : ReactDOM.Style.t)
                       in
                       match
                         match x with
                         | None -> None
                         | Some x -> Some (CSS.styles x)
                       with
                       | None -> __existing
                       | Some __incoming ->
                           ReactDOM.Style.combine __existing __incoming
                        : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          Buffer.add_char __buf ' ';
          Buffer.add_string __buf "class";
          Buffer.add_string __buf "=\"";
          ReactDOM.escape_to_buffer __buf
            (let __incoming = CSS.className x in
             match className with
             | None -> __incoming
             | Some __existing -> __incoming ^ " " ^ __existing
              : string);
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
                      ( "class",
                        "className",
                        (let __incoming = CSS.className x in
                         match className with
                         | None -> __incoming
                         | Some __existing -> __incoming ^ " " ^ __existing
                          : string) ));
                 Some (React.JSX.Style (CSS.styles x : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
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
            (ReactDOM.Style.to_string
               (let __incoming = CSS.styles x in
                match style with
                | None -> __incoming
                | Some __existing -> ReactDOM.Style.combine __existing __incoming
                 : ReactDOM.Style.t));
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
                 Some
                   (React.JSX.Style
                      (let __incoming = CSS.styles x in
                       match style with
                       | None -> __incoming
                       | Some __existing ->
                           ReactDOM.Style.combine __existing __incoming
                        : ReactDOM.Style.t));
               ])
            []);
    }
  ;;
  
  React.Writer
    {
      emit =
        (fun __buf ~separators:_ ->
          Buffer.add_string __buf "<div";
          (match
             (match
                ( (match x with None -> None | Some x -> Some (CSS.className x)),
                  className )
              with
              | None, None -> None
              | Some __incoming, None -> Some __incoming
              | None, Some __existing -> Some __existing
              | Some __incoming, Some __existing ->
                  Some (__incoming ^ " " ^ __existing)
               : string option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_char __buf ' ';
              Buffer.add_string __buf "class";
              Buffer.add_string __buf "=\"";
              ReactDOM.escape_to_buffer __buf (v : string);
              Buffer.add_char __buf '"');
          (match
             (match x with None -> None | Some x -> Some (CSS.styles x)
               : ReactDOM.Style.t option)
           with
          | None -> ()
          | Some v ->
              Buffer.add_string __buf " style=\"";
              ReactDOM.escape_to_buffer __buf
                (ReactDOM.Style.to_string (v : ReactDOM.Style.t));
              Buffer.add_char __buf '"');
          Buffer.add_string __buf "></div>";
          ());
      original =
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Stdlib.Fun.id
               [
                 (match
                    (match
                       ( (match x with
                         | None -> None
                         | Some x -> Some (CSS.className x)),
                         className )
                     with
                     | None, None -> None
                     | Some __incoming, None -> Some __incoming
                     | None, Some __existing -> Some __existing
                     | Some __incoming, Some __existing ->
                         Some (__incoming ^ " " ^ __existing)
                      : string option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.String ("class", "className", v)));
                 (match
                    (match x with None -> None | Some x -> Some (CSS.styles x)
                      : ReactDOM.Style.t option)
                  with
                 | None -> None
                 | Some v -> Some (React.JSX.Style v));
               ])
            []);
    }
  ;;
  
  Foo.Bar.make (Foo.Bar.makeProps ~styles:x ());;
  Foo.Bar.make (Foo.Bar.makeProps ?styles:x ())

In Melange mode (-js), ~styles is only expanded on lowercase (DOM) tags.
Module-qualified components like Foo.Bar keep ~styles as a regular prop (not expanded).
  $ rm -f output.ml temp.ml
  $ ../ppx.sh --output ml -js input.re
  div ~className:(CSS.className x) ~style:(CSS.styles x) ~children:[] () [@JSX];;
  
  div
    ?className:(match x with None -> None | Some x -> Some (CSS.className x))
    ?style:(match x with None -> None | Some x -> Some (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  div
    ~className:(CSS.className x ^ " " ^ "lola")
    ~style:(CSS.styles x) ~children:[] () [@JSX]
  ;;
  
  div ~className:(CSS.className x)
    ~style:
      (ReactDOM.Style.combine
         (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
         (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  div
    ~className:(CSS.className x ^ " " ^ "lola")
    ~style:
      (ReactDOM.Style.combine
         (ReactDOM.Style.make ~backgroundColor:"gainsboro" ())
         (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  div
    ~className:
      (let __existing = "lola" in
       match match x with None -> None | Some x -> Some (CSS.className x) with
       | None -> __existing
       | Some __incoming -> __incoming ^ " " ^ __existing)
    ?style:(match x with None -> None | Some x -> Some (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  div
    ?className:(match x with None -> None | Some x -> Some (CSS.className x))
    ~style:
      (let __existing = ReactDOM.Style.make ~backgroundColor:"gainsboro" () in
       match match x with None -> None | Some x -> Some (CSS.styles x) with
       | None -> __existing
       | Some __incoming -> ReactDOM.Style.combine __existing __incoming)
    ~children:[] () [@JSX]
  ;;
  
  div
    ~className:
      (let __existing = "lola" in
       match match x with None -> None | Some x -> Some (CSS.className x) with
       | None -> __existing
       | Some __incoming -> __incoming ^ " " ^ __existing)
    ~style:
      (let __existing = ReactDOM.Style.make ~backgroundColor:"gainsboro" () in
       match match x with None -> None | Some x -> Some (CSS.styles x) with
       | None -> __existing
       | Some __incoming -> ReactDOM.Style.combine __existing __incoming)
    ~children:[] () [@JSX]
  ;;
  
  div
    ~className:
      (let __incoming = CSS.className x in
       match className with
       | None -> __incoming
       | Some __existing -> __incoming ^ " " ^ __existing)
    ~style:(CSS.styles x) ~children:[] () [@JSX]
  ;;
  
  div ~className:(CSS.className x)
    ~style:
      (let __incoming = CSS.styles x in
       match style with
       | None -> __incoming
       | Some __existing -> ReactDOM.Style.combine __existing __incoming)
    ~children:[] () [@JSX]
  ;;
  
  div
    ?className:
      (match
         ( (match x with None -> None | Some x -> Some (CSS.className x)),
           className )
       with
      | None, None -> None
      | Some __incoming, None -> Some __incoming
      | None, Some __existing -> Some __existing
      | Some __incoming, Some __existing -> Some (__incoming ^ " " ^ __existing))
    ?style:(match x with None -> None | Some x -> Some (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  Foo.Bar.createElement ~styles:x ~children:[] () [@JSX];;
  Foo.Bar.createElement ?styles:x ~children:[] () [@JSX]
