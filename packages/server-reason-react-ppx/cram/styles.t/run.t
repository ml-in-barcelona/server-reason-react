Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
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
  ;;
  
  (fun __jsx_value__003_ __jsx_value__004_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            (match (__jsx_value__003_ : string option) with
            | None -> ()
            | Some v ->
                Buffer.add_char __buf ' ';
                Buffer.add_string __buf "class";
                Buffer.add_string __buf "=\"";
                ReactDOM.escape_to_buffer __buf (v : string);
                Buffer.add_char __buf '"');
            (match (__jsx_value__004_ : ReactDOM.Style.t option) with
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
                   (match (__jsx_value__003_ : string option) with
                   | None -> None
                   | Some v -> Some (React.JSX.String ("class", "className", v)));
                   (match (__jsx_value__004_ : ReactDOM.Style.t option) with
                   | None -> None
                   | Some v -> Some (React.JSX.Style v));
                 ])
              []);
      })
    (match x with None -> None | Some x -> Some (CSS.className x))
    (match x with None -> None | Some x -> Some (CSS.styles x))
  ;;
  
  (fun __jsx_value__005_ __jsx_value__006_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__005_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__006_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__005_ : string)));
                   Some (React.JSX.Style (__jsx_value__006_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (CSS.className
       (CSS.merge (CSS.make "lola" []) (CSS.make (CSS.className x) [])))
    (CSS.styles x)
  ;;
  
  (fun __jsx_value__007_ __jsx_value__008_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__007_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__008_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__007_ : string)));
                   Some (React.JSX.Style (__jsx_value__008_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (CSS.className x)
    (ReactDOM.Style.combine
       (("background-color", "backgroundColor", "gainsboro")
        :: ([] : (string * string * string) list)
         : ReactDOM.Style.t)
       (CSS.styles x))
  ;;
  
  (fun __jsx_value__009_ __jsx_value__010_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__009_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__010_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__009_ : string)));
                   Some (React.JSX.Style (__jsx_value__010_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (CSS.className
       (CSS.merge (CSS.make "lola" []) (CSS.make (CSS.className x) [])))
    (ReactDOM.Style.combine
       (("background-color", "backgroundColor", "gainsboro")
        :: ([] : (string * string * string) list)
         : ReactDOM.Style.t)
       (CSS.styles x))
  ;;
  
  (fun __jsx_value__011_ __jsx_value__012_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__011_ : string);
            Buffer.add_char __buf '"';
            (match (__jsx_value__012_ : ReactDOM.Style.t option) with
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
                        ("class", "className", (__jsx_value__011_ : string)));
                   (match (__jsx_value__012_ : ReactDOM.Style.t option) with
                   | None -> None
                   | Some v -> Some (React.JSX.Style v));
                 ])
              []);
      })
    (let __existing = "lola" in
     match match x with None -> None | Some x -> Some (CSS.className x) with
     | None -> __existing
     | Some __incoming ->
         CSS.className
           (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
    (match x with None -> None | Some x -> Some (CSS.styles x))
  ;;
  
  (fun __jsx_value__013_ __jsx_value__014_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            (match (__jsx_value__013_ : string option) with
            | None -> ()
            | Some v ->
                Buffer.add_char __buf ' ';
                Buffer.add_string __buf "class";
                Buffer.add_string __buf "=\"";
                ReactDOM.escape_to_buffer __buf (v : string);
                Buffer.add_char __buf '"');
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__014_ : ReactDOM.Style.t));
            Buffer.add_char __buf '"';
            Buffer.add_string __buf "></div>";
            ());
        original =
          (fun () ->
            React.createElement "div"
              (Stdlib.List.filter_map Stdlib.Fun.id
                 [
                   (match (__jsx_value__013_ : string option) with
                   | None -> None
                   | Some v -> Some (React.JSX.String ("class", "className", v)));
                   Some (React.JSX.Style (__jsx_value__014_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (match x with None -> None | Some x -> Some (CSS.className x))
    (let __existing =
       (("background-color", "backgroundColor", "gainsboro")
        :: ([] : (string * string * string) list)
         : ReactDOM.Style.t)
     in
     match match x with None -> None | Some x -> Some (CSS.styles x) with
     | None -> __existing
     | Some __incoming -> ReactDOM.Style.combine __existing __incoming)
  ;;
  
  (fun __jsx_value__015_ __jsx_value__016_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__015_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__016_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__015_ : string)));
                   Some (React.JSX.Style (__jsx_value__016_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (let __existing = "lola" in
     match match x with None -> None | Some x -> Some (CSS.className x) with
     | None -> __existing
     | Some __incoming ->
         CSS.className
           (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
    (let __existing =
       (("background-color", "backgroundColor", "gainsboro")
        :: ([] : (string * string * string) list)
         : ReactDOM.Style.t)
     in
     match match x with None -> None | Some x -> Some (CSS.styles x) with
     | None -> __existing
     | Some __incoming -> ReactDOM.Style.combine __existing __incoming)
  ;;
  
  (fun __jsx_value__017_ __jsx_value__018_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__017_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__018_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__017_ : string)));
                   Some (React.JSX.Style (__jsx_value__018_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (let __incoming = CSS.className x in
     match className with
     | None -> __incoming
     | Some __existing ->
         CSS.className
           (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
    (CSS.styles x)
  ;;
  
  (fun __jsx_value__019_ __jsx_value__020_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            Buffer.add_char __buf ' ';
            Buffer.add_string __buf "class";
            Buffer.add_string __buf "=\"";
            ReactDOM.escape_to_buffer __buf (__jsx_value__019_ : string);
            Buffer.add_char __buf '"';
            Buffer.add_string __buf " style=\"";
            ReactDOM.escape_to_buffer __buf
              (ReactDOM.Style.to_string (__jsx_value__020_ : ReactDOM.Style.t));
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
                        ("class", "className", (__jsx_value__019_ : string)));
                   Some (React.JSX.Style (__jsx_value__020_ : ReactDOM.Style.t));
                 ])
              []);
      })
    (CSS.className x)
    (let __incoming = CSS.styles x in
     match style with
     | None -> __incoming
     | Some __existing -> ReactDOM.Style.combine __existing __incoming)
  ;;
  
  (fun __jsx_value__021_ __jsx_value__022_ ->
    React.Writer
      {
        emit =
          (fun __buf ~separators:_ ->
            Buffer.add_string __buf "<div";
            (match (__jsx_value__021_ : string option) with
            | None -> ()
            | Some v ->
                Buffer.add_char __buf ' ';
                Buffer.add_string __buf "class";
                Buffer.add_string __buf "=\"";
                ReactDOM.escape_to_buffer __buf (v : string);
                Buffer.add_char __buf '"');
            (match (__jsx_value__022_ : ReactDOM.Style.t option) with
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
                   (match (__jsx_value__021_ : string option) with
                   | None -> None
                   | Some v -> Some (React.JSX.String ("class", "className", v)));
                   (match (__jsx_value__022_ : ReactDOM.Style.t option) with
                   | None -> None
                   | Some v -> Some (React.JSX.Style v));
                 ])
              []);
      })
    (match
       ( (match x with None -> None | Some x -> Some (CSS.className x)),
         className )
     with
    | None, None -> None
    | Some __incoming, None -> Some __incoming
    | None, Some __existing -> Some __existing
    | Some __incoming, Some __existing ->
        Some
          (CSS.className
             (CSS.merge (CSS.make __existing []) (CSS.make __incoming []))))
    (match x with None -> None | Some x -> Some (CSS.styles x))
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
    ~className:
      (CSS.className
         (CSS.merge (CSS.make "lola" []) (CSS.make (CSS.className x) [])))
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
    ~className:
      (CSS.className
         (CSS.merge (CSS.make "lola" []) (CSS.make (CSS.className x) [])))
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
       | Some __incoming ->
           CSS.className
             (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
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
       | Some __incoming ->
           CSS.className
             (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
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
       | Some __existing ->
           CSS.className
             (CSS.merge (CSS.make __existing []) (CSS.make __incoming [])))
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
      | Some __incoming, Some __existing ->
          Some
            (CSS.className
               (CSS.merge (CSS.make __existing []) (CSS.make __incoming []))))
    ?style:(match x with None -> None | Some x -> Some (CSS.styles x))
    ~children:[] () [@JSX]
  ;;
  
  Foo.Bar.createElement ~styles:x ~children:[] () [@JSX];;
  Foo.Bar.createElement ?styles:x ~children:[] () [@JSX]
