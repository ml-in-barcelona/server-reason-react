Constrained literals keep their annotations without becoming captured parameters.
Constrained dynamic values still need a capture.

  $ ../ppx.sh --output ml input.re
  type roundness = Full | None
  
  let make value =
    (fun __jsx_value__001_ ->
      React.Writer
        {
          emit =
            (fun __buf ~separators:_ ->
              Buffer.add_string __buf "<div title=\"hello\" tabindex=\"1\"";
              (match ((None : string option) : string option) with
              | None -> ()
              | Some v ->
                  Buffer.add_char __buf ' ';
                  Buffer.add_string __buf "id";
                  Buffer.add_string __buf "=\"";
                  ReactDOM.escape_to_buffer __buf (v : string);
                  Buffer.add_char __buf '"');
              Buffer.add_char __buf ' ';
              Buffer.add_string __buf "data-state";
              Buffer.add_string __buf "=\"";
              ReactDOM.escape_to_buffer __buf (__jsx_value__001_ : string);
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
                          ( "title",
                            "title",
                            ((("hello" : string) : string) : string) ));
                     Some
                       (React.JSX.Int ("tabindex", "tabIndex", ((1 : int) : int)));
                     Some
                       (React.JSX.Bool
                          ("hidden", "hidden", ((false : bool) : bool)));
                     (match ((None : string option) : string option) with
                     | None -> None
                     | Some v -> Some (React.JSX.String ("id", "id", v)));
                     Some
                       (React.JSX.String
                          ( "data-state",
                            "data-state",
                            (__jsx_value__001_ : string) ));
                   ])
                []);
        })
      (value : string)
  ;;
  
  print_endline (ReactDOM.renderToStaticMarkup (make "value"))

  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executables
  >  (names input invalid)
  >  (flags (:standard -w -32-34-37))
  >  (libraries server-reason-react.react server-reason-react.reactDom)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/)))
  > EOF

  $ dune exec ./input.exe
  <div title="hello" tabindex="1" data-state="value"></div>

The original annotation must still be checked.

  $ dune build invalid.exe > /dev/null 2>&1
  [1]
