module React_component_with_props =
  struct
    let make ~lola = ((div ~children:[React.string lola] ())[@JSX ])[@@react.component
                                                                    ]
  end
let react_component_with_props =
  ((React_component_with_props.createElement ~lola:"flores" ~children:[] ())
  [@JSX ])
module Forward_Ref =
  struct
    let make =
      React.forwardRef
        (fun ~children ->
           fun ~buttonRef ->
             ((button ~ref:buttonRef ~className:"FancyButton"
                 ~children:[children] ())
             [@JSX ]))[@@react.component ]
  end
module Onclick_handler_button =
  struct
    let make ~name =
      fun ?isDisabled ->
        let onClick event = Js.log event in
        ((button ~name ~onClick ~disabled:isDisabled ~children:[] ())
          [@JSX ])[@@react.component ]
  end
module Children_as_string =
  struct
    let make ?(name= "joe") =
      ((div ~children:[(Printf.sprintf "`name` is %s" name) |> React.string]
          ())
      [@JSX ])[@@react.component ]
  end
let () = Dream.run ()
let l = 33
module Uppercase_with_SSR_components =
  struct
    let make ~children =
      fun ~moreProps ->
        ((html
            ~children:[((head
                           ~children:[((title
                                          ~children:[React.string
                                                       ("SSR React " ^
                                                          moreProps)] ())
                                     [@JSX ])] ())
                      [@JSX ]);
                      ((body
                          ~children:[((div ~id:"root" ~children:[children] ())
                                    [@JSX ]);
                                    ((script ~src:"/static/client.js"
                                        ~children:[] ())
                                    [@JSX ])] ())
                      [@JSX ])] ())
        [@JSX ])[@@react.component ]
  end
module Upper_with_aria =
  struct
    let make ~children = ((div ~ariaHidden:"true" ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
module Form_with_method =
  struct
    let make ~children = ((form ~method_:"GET" ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
module Form_with_method =
  struct
    let make ~children = ((form ~action:(`String "") ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
module Form_with_action_function =
  struct
    let make ~children =
      ((form
          ~action:(`Function
                     {
                       id = "123";
                       call = (fun () -> Js.Promise.resolve "Hello")
                     }) ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
module Form_with_action_string =
  struct
    let make ~children = ((form ~action:(`String "") ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
module Button_with_formAction_string =
  struct
    let make ~children =
      ((button ~formAction:(`String "") ~children:[children] ())[@JSX ])
      [@@react.component ]
  end
module Button_with_formAction_function =
  struct
    let make ~children =
      ((button
          ~formAction:(`Function
                         {
                           id = "123";
                           call = (fun () -> Js.Promise.resolve "Hello")
                         }) ~children:[children] ())
      [@JSX ])[@@react.component ]
  end
let a =
  ((Uppercase.createElement ~children:[((div ~children:[] ())[@JSX ])] ())
  [@JSX ])
module Async_component =
  struct
    let make ~children =
      ((div ~className:"async-component" ~children:[children] ())[@JSX ])
      [@@react.async.component ]
  end
let a =
  ((Async_component.createElement ~children:[((div ~children:[] ())[@JSX ])]
      ())
  [@JSX ])
module Sequence =
  struct
    let make ~lola =
      let (state, setState) = React.useState lola in
      React.useEffect (fun () -> setState lola; None);
      ((div ~children:[React.string state] ())
      [@JSX ])[@@react.component ]
  end
module Use_context =
  struct
    let make () =
      let captured = React.useContext Context.value in
      ((div ~children:[React.string captured] ())[@JSX ])[@@react.component ]
  end