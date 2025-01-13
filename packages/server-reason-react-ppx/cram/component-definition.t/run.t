Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module React_component_with_props = struct
    let make ?key:(_ : string option) ~lola () =
      React.Upper_case_component
        (fun () -> React.createElement "div" [] [ React.string lola ])
  end
  
  let react_component_with_props =
    React_component_with_props.make ~lola:"flores" ()
  
  module Forward_Ref = struct
    let make ?key:(_ : string option) ~children ~buttonRef () =
      React.Upper_case_component
        (fun () ->
          React.createElement "button"
            (Stdlib.List.filter_map Fun.id
               [
                 Some (React.JSX.Ref (buttonRef : React.domRef));
                 Some
                   (React.JSX.String
                      ("class", "className", ("FancyButton" : string)));
               ])
            [ children ])
  end
  
  module Onclick_handler_button = struct
    let make ?key:(_ : string option) ~name ?isDisabled () =
      React.Upper_case_component
        (fun () ->
          let onClick event = Js.log event in
          React.createElement "button"
            (Stdlib.List.filter_map Fun.id
               [
                 Some (React.JSX.String ("name", "name", (name : string)));
                 Some
                   (React.JSX.Event
                      ( "onClick",
                        React.JSX.Mouse (onClick : React.Event.Mouse.t -> unit) ));
                 Some
                   (React.JSX.Bool ("disabled", "disabled", (isDisabled : bool)));
               ])
            [])
  end
  
  module Children_as_string = struct
    let make ?key:(_ : string option) ?(name = "joe") () =
      React.Upper_case_component
        (fun () ->
          React.createElement "div" []
            [ Printf.sprintf "`name` is %s" name |> React.string ])
  end
  
  let () = Dream.run ()
  let l = 33
  
  module Uppercase_with_SSR_components = struct
    let make ?key:(_ : string option) ~children ~moreProps () =
      React.Upper_case_component
        (fun () ->
          React.createElement "html" []
            [
              React.createElement "head" []
                [
                  React.createElement "title" []
                    [ React.string ("SSR React " ^ moreProps) ];
                ];
              React.createElement "body" []
                [
                  React.createElement "div"
                    (Stdlib.List.filter_map Fun.id
                       [ Some (React.JSX.String ("id", "id", ("root" : string))) ])
                    [ children ];
                  React.createElement "script"
                    (Stdlib.List.filter_map Fun.id
                       [
                         Some
                           (React.JSX.String
                              ("src", "src", ("/static/client.js" : string)));
                       ])
                    [];
                ];
            ])
  end
  
  module Upper_with_aria = struct
    let make ?key:(_ : string option) ~children () =
      React.Upper_case_component
        (fun () ->
          React.createElement "div"
            (Stdlib.List.filter_map Fun.id
               [
                 Some
                   (React.JSX.String
                      ( "aria-hidden",
                        "aria-hidden",
                        string_of_bool ("true" : bool) ));
               ])
            [ children ])
  end
  
  module Form_with_method = struct
    let make ?key:(_ : string option) ~children () =
      React.Upper_case_component
        (fun () ->
          React.createElement "form"
            (Stdlib.List.filter_map Fun.id
               [ Some (React.JSX.String ("method", "method", ("GET" : string))) ])
            [ children ])
  end
  
  let a = Uppercase.make ~children:(React.createElement "div" [] []) ()
  
  module Async_component = struct
    let make ?key:(_ : string option) ~children () =
      React.Async_component
        (fun () ->
          React.createElement "form"
            (Stdlib.List.filter_map Fun.id
               [ Some (React.JSX.String ("method", "method", ("GET" : string))) ])
            [ children ])
  end
  
  let a = Async_component.make ~children:(React.createElement "div" [] []) ()
  
  module Sequence = struct
    let make ?key:(_ : string option) ~lola () =
      React.Upper_case_component
        (fun () ->
          let state, setState = React.useState lola in
          React.useEffect (fun () ->
              setState lola;
              None);
          React.createElement "div" [] [ React.string state ])
  end
  
  module Use_context = struct
    let make ?key:(_ : string option) () =
      React.Upper_case_component
        (fun () ->
          let captured = React.useContext Context.value in
          React.createElement "div" [] [ React.string captured ])
  end