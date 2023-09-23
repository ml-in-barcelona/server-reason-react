Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module React_component_with_props = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ~lola () ->
      React.createElement "div"
        ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
        [ React.string lola ]
  end
  
  let react_component_with_props =
    React.Upper_case_component
      (fun () -> React_component_with_props.make ~lola:"flores" ())
  
  module Upper_case_with_fragment_as_root = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ?(name = "") () ->
      React.fragment
        ~children:
          (React.list
             [
               React.createElement "div"
                 ([||] |> Array.to_list
                 |> List.filter_map (fun a -> a)
                 |> Array.of_list)
                 [ React.string ("First " ^ name) ];
               React.Upper_case_component
                 (fun () ->
                   Hello.make ~one:"1" ~children:(React.string ("2nd " ^ name)) ());
             ])
        ()
  end
  
  module Forward_Ref = struct
    let make ?key =
     fun [@warning "-16"] ~children ->
      fun [@warning "-16"] [@warning "-16"] ~buttonRef () ->
       React.createElement "button"
         ([|
            Some (React.JSX.Ref buttonRef);
            Some (React.JSX.String ("class", ("FancyButton" : string)));
          |]
         |> Array.to_list
         |> List.filter_map (fun a -> a)
         |> Array.of_list)
         [ children ]
  end
  
  module Onclick_handler_button = struct
    let make ?key =
     fun [@warning "-16"] ~name ->
      fun [@warning "-16"] [@warning "-16"] ?isDisabled () ->
       let onClick event = Js.log event in
       React.createElement "button"
         ([|
            Some (React.JSX.String ("name", (name : string)));
            Some
              (React.JSX.Event
                 ( "onClick",
                   React.JSX.Event.Mouse (onClick : ReactEvent.Mouse.t -> unit) ));
            Some (React.JSX.Bool ("disabled", (isDisabled : bool)));
          |]
         |> Array.to_list
         |> List.filter_map (fun a -> a)
         |> Array.of_list)
         []
  end
  
  module Children_as_string = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ?(name = "joe") () ->
      React.createElement "div"
        ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
        [ Printf.sprintf "`name` is %s" name |> React.string ]
  end
  
  let () = Dream.run ()
  let l = 33
  
  module Uppercase_with_SSR_components = struct
    let make ?key =
     fun [@warning "-16"] ~children ->
      fun [@warning "-16"] [@warning "-16"] ~moreProps () ->
       React.createElement "html"
         ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
         [
           React.createElement "head"
             ([||] |> Array.to_list
             |> List.filter_map (fun a -> a)
             |> Array.of_list)
             [
               React.createElement "title"
                 ([||] |> Array.to_list
                 |> List.filter_map (fun a -> a)
                 |> Array.of_list)
                 [ React.string ("SSR React " ^ moreProps) ];
             ];
           React.createElement "body"
             ([||] |> Array.to_list
             |> List.filter_map (fun a -> a)
             |> Array.of_list)
             [
               React.createElement "div"
                 ([| Some (React.JSX.String ("id", ("root" : string))) |]
                 |> Array.to_list
                 |> List.filter_map (fun a -> a)
                 |> Array.of_list)
                 [ children ];
               React.createElement "script"
                 ([|
                    Some
                      (React.JSX.String ("src", ("/static/client.js" : string)));
                  |]
                 |> Array.to_list
                 |> List.filter_map (fun a -> a)
                 |> Array.of_list)
                 [];
             ];
         ]
  end
  
  module Upper_with_aria = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ~children () ->
      React.createElement "div"
        ([|
           Some (React.JSX.String ("aria-hidden", string_of_bool ("true" : bool)));
         |]
        |> Array.to_list
        |> List.filter_map (fun a -> a)
        |> Array.of_list)
        [ children ]
  end
