Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module React_component_with_props = struct
    let make ?key =
     fun [@warning "-16"] ~lola () ->
      React.createElement "div" [] [ React.string lola ]
  end
  
  let react_component_with_props =
    React.Upper_case_component
      (fun () -> React_component_with_props.make ~lola:"flores" ())
  
  module Forward_Ref = struct
    let make ?key ~children =
     fun [@warning "-16"] ~buttonRef () ->
      React.createElement "button"
        (List.filter_map Fun.id
           [
             Some (React.JSX.Ref (buttonRef : React.domRef));
             Some (React.JSX.String ("class", ("FancyButton" : string)));
           ])
        [ children ]
  end
  
  module Onclick_handler_button = struct
    let make ?key ~name =
     fun [@warning "-16"] ?isDisabled () ->
      let onClick event = Js.log event in
      React.createElement "button"
        (List.filter_map Fun.id
           [
             Some (React.JSX.String ("name", (name : string)));
             Some
               (React.JSX.Event
                  ( "onClick",
                    React.JSX.Mouse (onClick : React.Event.Mouse.t -> unit) ));
             Some (React.JSX.Bool ("disabled", (isDisabled : bool)));
           ])
        []
  end
  
  module Children_as_string = struct
    let make ?key =
     fun [@warning "-16"] ?(name = "joe") () ->
      React.createElement "div" []
        [ Printf.sprintf "`name` is %s" name |> React.string ]
  end
  
  let () = Dream.run ()
  let l = 33
  
  module Uppercase_with_SSR_components = struct
    let make ?key ~children =
     fun [@warning "-16"] ~moreProps () ->
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
                (List.filter_map Fun.id
                   [ Some (React.JSX.String ("id", ("root" : string))) ])
                [ children ];
              React.createElement "script"
                (List.filter_map Fun.id
                   [
                     Some
                       (React.JSX.String ("src", ("/static/client.js" : string)));
                   ])
                [];
            ];
        ]
  end
  
  module Upper_with_aria = struct
    let make ?key =
     fun [@warning "-16"] ~children () ->
      React.createElement "div"
        (List.filter_map Fun.id
           [
             Some
               (React.JSX.String ("aria-hidden", string_of_bool ("true" : bool)));
           ])
        [ children ]
  end
  
  module Form_with_method = struct
    let make ?key =
     fun [@warning "-16"] ~children () ->
      React.createElement "form"
        (List.filter_map Fun.id
           [ Some (React.JSX.String ("method", ("GET" : string))) ])
        [ children ]
  end
