Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  File "temp.ml", line 1:
  Warning: Ocamlformat disabled because [--enable-outside-detected-project] is not set and no [.ocamlformat] was found within the project (root: ../../../../../../../.sandbox)
  module React_component_with_props =
    struct
      let make ?key  =
        ((fun ~lola ->
            fun () ->
              React.createElement "div"
                ((([||] |> Array.to_list) |> (List.filter_map (fun a -> a))) |>
                   Array.of_list) [React.string lola])
        [@warning "-16"][@warning "-16"])
    end
  let react_component_with_props =
    React.Upper_case_component
      (fun () -> React_component_with_props.make ~lola:"flores" ())
  module Upper_case_with_fragment_as_root =
    struct
      let make ?key  =
        ((fun ?(name= "") ->
            fun () ->
              React.fragment
                ~children:(React.list
                             [React.createElement "div"
                                ((([||] |> Array.to_list) |>
                                    (List.filter_map (fun a -> a)))
                                   |> Array.of_list)
                                [React.string ("First " ^ name)];
                             React.Upper_case_component
                               ((fun () ->
                                   Hello.make ~one:"1"
                                     ~children:(React.string ("2nd " ^ name))
                                     ()))]) ())
        [@warning "-16"][@warning "-16"])
    end
  module Forward_Ref =
    struct
      let make ?key  =
        ((fun ~children ->
            ((fun ~buttonRef ->
                fun () ->
                  React.createElement "button"
                    ((([|(Some (React.JSX.Ref buttonRef));(Some
                                                             (React.JSX.String
                                                                ("class",
                                                                  ("FancyButton" : 
                                                                  string))))|]
                         |> Array.to_list)
                        |> (List.filter_map (fun a -> a)))
                       |> Array.of_list) [children])
            [@warning "-16"][@warning "-16"]))
        [@warning "-16"])
    end
  module Onclick_handler_button =
    struct
      let make ?key  =
        ((fun ~name ->
            ((fun ?isDisabled ->
                fun () ->
                  let onClick event = Js.log event in
                  React.createElement "button"
                    ((([|(Some (React.JSX.String ("name", (name : string))));(
                         Some
                           (React.JSX.Event
                              ("onClick",
                                (React.JSX.Event.Mouse
                                   (onClick : ReactEvent.Mouse.t -> unit)))));(
                         Some
                           (React.JSX.Bool ("disabled", (isDisabled : bool))))|]
                         |> Array.to_list)
                        |> (List.filter_map (fun a -> a)))
                       |> Array.of_list) [])
            [@warning "-16"][@warning "-16"]))
        [@warning "-16"])
    end
  module Children_as_string =
    struct
      let make ?key  =
        ((fun ?(name= "joe") ->
            fun () ->
              React.createElement "div"
                ((([||] |> Array.to_list) |> (List.filter_map (fun a -> a))) |>
                   Array.of_list)
                [(Printf.sprintf "`name` is %s" name) |> React.string])
        [@warning "-16"][@warning "-16"])
    end
  let () = Dream.run ()
  let l = 33
  module Uppercase_with_SSR_components =
    struct
      let make ?key  =
        ((fun ~children ->
            ((fun ~moreProps ->
                fun () ->
                  React.createElement "html"
                    ((([||] |> Array.to_list) |> (List.filter_map (fun a -> a)))
                       |> Array.of_list)
                    [React.createElement "head"
                       ((([||] |> Array.to_list) |>
                           (List.filter_map (fun a -> a)))
                          |> Array.of_list)
                       [React.createElement "title"
                          ((([||] |> Array.to_list) |>
                              (List.filter_map (fun a -> a)))
                             |> Array.of_list)
                          [React.string ("SSR React " ^ moreProps)]];
                    React.createElement "body"
                      ((([||] |> Array.to_list) |>
                          (List.filter_map (fun a -> a)))
                         |> Array.of_list)
                      [React.createElement "div"
                         ((([|(Some
                                 (React.JSX.String ("id", ("root" : string))))|]
                              |> Array.to_list)
                             |> (List.filter_map (fun a -> a)))
                            |> Array.of_list) [children];
                      React.createElement "script"
                        ((([|(Some
                                (React.JSX.String
                                   ("src", ("/static/client.js" : string))))|]
                             |> Array.to_list)
                            |> (List.filter_map (fun a -> a)))
                           |> Array.of_list) []]])
            [@warning "-16"][@warning "-16"]))
        [@warning "-16"])
    end
  module Upper_with_aria =
    struct
      let make ?key  =
        ((fun ~children ->
            fun () ->
              React.createElement "div"
                ((([|(Some
                        (React.JSX.String
                           ("aria-hidden", (string_of_bool ("true" : bool)))))|]
                     |> Array.to_list)
                    |> (List.filter_map (fun a -> a)))
                   |> Array.of_list) [children])
        [@warning "-16"][@warning "-16"])
    end
