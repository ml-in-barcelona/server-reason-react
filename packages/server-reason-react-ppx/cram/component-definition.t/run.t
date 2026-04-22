Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module React_component_with_props = struct
    include struct
      let makeProps ~(lola : 'lola) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"lola" ~js_name:"lola"
            ~present:true lola
        in
        let __js_obj =
          object
            method lola = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < lola : 'lola > Js.t)
  
      let make ?key:(_ : string option) ~lola () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div>";
                      ReactDOM.escape_to_buffer b lola;
                      Buffer.add_string b "</div>";
                      ());
                  original =
                    (fun () -> React.createElement "div" [] [ React.string lola ]);
                } )
  
      let make ?(key : string option) (Props : < lola : 'lola > Js.t) =
        make ?key ~lola:Props#lola ()
    end
  end
  
  let react_component_with_props =
    React_component_with_props.make
      (React_component_with_props.makeProps ~lola:"flores" ())
  
  module Forward_Ref = struct
    include struct
      let makeProps ~(children : 'children) ~(buttonRef : 'buttonRef) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj_cell_1, __js_obj_entry_1 =
          Js.Obj.Internal.slot_ref ~method_name:"buttonRef" ~js_name:"buttonRef"
            ~present:true buttonRef
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
            method buttonRef = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj
           [ __js_obj_entry_0; __js_obj_entry_1 ]
          : < children : 'children ; buttonRef : 'buttonRef > Js.t)
  
      let make ?key:(_ : string option) ~children =
       (fun ~buttonRef () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<button class=\"FancyButton\">";
                      ReactDOM.write_to_buffer b children;
                      Buffer.add_string b "</button>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "button"
                        (Stdlib.List.filter_map Stdlib.Fun.id
                           [
                             Some
                               (React.JSX.String
                                  ("class", "className", ("FancyButton" : string)));
                             Some (React.JSX.Ref (buttonRef : React.domRef));
                           ])
                        [ children ]);
                } ))
        [@warning "-16"]
  
      let make ?(key : string option)
          (Props : < children : 'children ; buttonRef : 'buttonRef > Js.t) =
        make ?key ~children:Props#children ~buttonRef:Props#buttonRef ()
    end
  end
  
  module Onclick_handler_button = struct
    include struct
      let makeProps ~(name : 'name) ?(isDisabled : 'isDisabled option) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"name" ~js_name:"name"
            ~present:true name
        in
        let __js_obj_cell_1, __js_obj_entry_1 =
          Js.Obj.Internal.slot_ref ~method_name:"isDisabled" ~js_name:"isDisabled"
            ~present:(match isDisabled with None -> false | Some _ -> true)
            isDisabled
        in
        let __js_obj =
          object
            method name = !__js_obj_cell_0
            method isDisabled = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj
           [ __js_obj_entry_0; __js_obj_entry_1 ]
          : < name : 'name ; isDisabled : 'isDisabled option > Js.t)
  
      let make ?key:(_ : string option) ~name =
       (fun ?isDisabled () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              let onClick event = Js.log event in
              React.createElement "button"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     Some (React.JSX.String ("name", "name", (name : string)));
                     Some
                       (React.JSX.Event
                          ( "onClick",
                            React.JSX.Mouse
                              (onClick : React.Event.Mouse.t -> unit) ));
                     Some
                       (React.JSX.Bool
                          ("disabled", "disabled", (isDisabled : bool)));
                   ])
                [] ))
        [@warning "-16"]
  
      let make ?(key : string option)
          (Props : < name : 'name ; isDisabled : 'isDisabled option > Js.t) =
        make ?key ~name:Props#name ?isDisabled:Props#isDisabled ()
    end
  end
  
  module Children_as_string = struct
    include struct
      let makeProps ?(name : 'name option) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"name" ~js_name:"name"
            ~present:(match name with None -> false | Some _ -> true)
            name
        in
        let __js_obj =
          object
            method name = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < name : 'name option > Js.t)
  
      let make ?key:(_ : string option) ?(name = "joe") () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div>";
                      ReactDOM.write_to_buffer b
                        (Printf.sprintf "`name` is %s" name |> React.string);
                      Buffer.add_string b "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" []
                        [ Printf.sprintf "`name` is %s" name |> React.string ]);
                } )
  
      let make ?(key : string option) (Props : < name : 'name option > Js.t) =
        make ?key ?name:Props#name ()
    end
  end
  
  let () = Dream.run ()
  let l = 33
  
  module Uppercase_with_SSR_components = struct
    include struct
      let makeProps ~(children : 'children) ~(moreProps : 'moreProps) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj_cell_1, __js_obj_entry_1 =
          Js.Obj.Internal.slot_ref ~method_name:"moreProps" ~js_name:"moreProps"
            ~present:true moreProps
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
            method moreProps = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj
           [ __js_obj_entry_0; __js_obj_entry_1 ]
          : < children : 'children ; moreProps : 'moreProps > Js.t)
  
      let make ?key:(_ : string option) ~children =
       (fun ~moreProps () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<!DOCTYPE html>";
                      Buffer.add_string b "<html>";
                      ReactDOM.write_to_buffer b
                        (React.Writer
                           {
                             emit =
                               (fun b ->
                                 Buffer.add_string b "<head>";
                                 ReactDOM.write_to_buffer b
                                   (React.Writer
                                      {
                                        emit =
                                          (fun b ->
                                            Buffer.add_string b "<title>";
                                            ReactDOM.escape_to_buffer b
                                              ("SSR React " ^ moreProps);
                                            Buffer.add_string b "</title>";
                                            ());
                                        original =
                                          (fun () ->
                                            React.createElement "title" []
                                              [
                                                React.string
                                                  ("SSR React " ^ moreProps);
                                              ]);
                                      });
                                 Buffer.add_string b "</head>";
                                 ());
                             original =
                               (fun () ->
                                 React.createElement "head" []
                                   [
                                     React.Writer
                                       {
                                         emit =
                                           (fun b ->
                                             Buffer.add_string b "<title>";
                                             ReactDOM.escape_to_buffer b
                                               ("SSR React " ^ moreProps);
                                             Buffer.add_string b "</title>";
                                             ());
                                         original =
                                           (fun () ->
                                             React.createElement "title" []
                                               [
                                                 React.string
                                                   ("SSR React " ^ moreProps);
                                               ]);
                                       };
                                   ]);
                           });
                      ReactDOM.write_to_buffer b
                        (React.Writer
                           {
                             emit =
                               (fun b ->
                                 Buffer.add_string b "<body>";
                                 ReactDOM.write_to_buffer b
                                   (React.Writer
                                      {
                                        emit =
                                          (fun b ->
                                            Buffer.add_string b
                                              "<div id=\"root\">";
                                            ReactDOM.write_to_buffer b children;
                                            Buffer.add_string b "</div>";
                                            ());
                                        original =
                                          (fun () ->
                                            React.createElement "div"
                                              (Stdlib.List.filter_map
                                                 Stdlib.Fun.id
                                                 [
                                                   Some
                                                     (React.JSX.String
                                                        ( "id",
                                                          "id",
                                                          ("root" : string) ));
                                                 ])
                                              [ children ]);
                                      });
                                 ReactDOM.write_to_buffer b
                                   (React.Static
                                      {
                                        prerendered =
                                          "<script \
                                           src=\"/static/client.js\"></script>";
                                        original =
                                          React.createElement "script"
                                            (Stdlib.List.filter_map Stdlib.Fun.id
                                               [
                                                 Some
                                                   (React.JSX.String
                                                      ( "src",
                                                        "src",
                                                        ("/static/client.js"
                                                          : string) ));
                                               ])
                                            [];
                                      });
                                 Buffer.add_string b "</body>";
                                 ());
                             original =
                               (fun () ->
                                 React.createElement "body" []
                                   [
                                     React.Writer
                                       {
                                         emit =
                                           (fun b ->
                                             Buffer.add_string b
                                               "<div id=\"root\">";
                                             ReactDOM.write_to_buffer b children;
                                             Buffer.add_string b "</div>";
                                             ());
                                         original =
                                           (fun () ->
                                             React.createElement "div"
                                               (Stdlib.List.filter_map
                                                  Stdlib.Fun.id
                                                  [
                                                    Some
                                                      (React.JSX.String
                                                         ( "id",
                                                           "id",
                                                           ("root" : string) ));
                                                  ])
                                               [ children ]);
                                       };
                                     React.Static
                                       {
                                         prerendered =
                                           "<script \
                                            src=\"/static/client.js\"></script>";
                                         original =
                                           React.createElement "script"
                                             (Stdlib.List.filter_map Stdlib.Fun.id
                                                [
                                                  Some
                                                    (React.JSX.String
                                                       ( "src",
                                                         "src",
                                                         ("/static/client.js"
                                                           : string) ));
                                                ])
                                             [];
                                       };
                                   ]);
                           });
                      Buffer.add_string b "</html>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "html" []
                        [
                          React.Writer
                            {
                              emit =
                                (fun b ->
                                  Buffer.add_string b "<head>";
                                  ReactDOM.write_to_buffer b
                                    (React.Writer
                                       {
                                         emit =
                                           (fun b ->
                                             Buffer.add_string b "<title>";
                                             ReactDOM.escape_to_buffer b
                                               ("SSR React " ^ moreProps);
                                             Buffer.add_string b "</title>";
                                             ());
                                         original =
                                           (fun () ->
                                             React.createElement "title" []
                                               [
                                                 React.string
                                                   ("SSR React " ^ moreProps);
                                               ]);
                                       });
                                  Buffer.add_string b "</head>";
                                  ());
                              original =
                                (fun () ->
                                  React.createElement "head" []
                                    [
                                      React.Writer
                                        {
                                          emit =
                                            (fun b ->
                                              Buffer.add_string b "<title>";
                                              ReactDOM.escape_to_buffer b
                                                ("SSR React " ^ moreProps);
                                              Buffer.add_string b "</title>";
                                              ());
                                          original =
                                            (fun () ->
                                              React.createElement "title" []
                                                [
                                                  React.string
                                                    ("SSR React " ^ moreProps);
                                                ]);
                                        };
                                    ]);
                            };
                          React.Writer
                            {
                              emit =
                                (fun b ->
                                  Buffer.add_string b "<body>";
                                  ReactDOM.write_to_buffer b
                                    (React.Writer
                                       {
                                         emit =
                                           (fun b ->
                                             Buffer.add_string b
                                               "<div id=\"root\">";
                                             ReactDOM.write_to_buffer b children;
                                             Buffer.add_string b "</div>";
                                             ());
                                         original =
                                           (fun () ->
                                             React.createElement "div"
                                               (Stdlib.List.filter_map
                                                  Stdlib.Fun.id
                                                  [
                                                    Some
                                                      (React.JSX.String
                                                         ( "id",
                                                           "id",
                                                           ("root" : string) ));
                                                  ])
                                               [ children ]);
                                       });
                                  ReactDOM.write_to_buffer b
                                    (React.Static
                                       {
                                         prerendered =
                                           "<script \
                                            src=\"/static/client.js\"></script>";
                                         original =
                                           React.createElement "script"
                                             (Stdlib.List.filter_map Stdlib.Fun.id
                                                [
                                                  Some
                                                    (React.JSX.String
                                                       ( "src",
                                                         "src",
                                                         ("/static/client.js"
                                                           : string) ));
                                                ])
                                             [];
                                       });
                                  Buffer.add_string b "</body>";
                                  ());
                              original =
                                (fun () ->
                                  React.createElement "body" []
                                    [
                                      React.Writer
                                        {
                                          emit =
                                            (fun b ->
                                              Buffer.add_string b
                                                "<div id=\"root\">";
                                              ReactDOM.write_to_buffer b children;
                                              Buffer.add_string b "</div>";
                                              ());
                                          original =
                                            (fun () ->
                                              React.createElement "div"
                                                (Stdlib.List.filter_map
                                                   Stdlib.Fun.id
                                                   [
                                                     Some
                                                       (React.JSX.String
                                                          ( "id",
                                                            "id",
                                                            ("root" : string) ));
                                                   ])
                                                [ children ]);
                                        };
                                      React.Static
                                        {
                                          prerendered =
                                            "<script \
                                             src=\"/static/client.js\"></script>";
                                          original =
                                            React.createElement "script"
                                              (Stdlib.List.filter_map
                                                 Stdlib.Fun.id
                                                 [
                                                   Some
                                                     (React.JSX.String
                                                        ( "src",
                                                          "src",
                                                          ("/static/client.js"
                                                            : string) ));
                                                 ])
                                              [];
                                        };
                                    ]);
                            };
                        ]);
                } ))
        [@warning "-16"]
  
      let make ?(key : string option)
          (Props : < children : 'children ; moreProps : 'moreProps > Js.t) =
        make ?key ~children:Props#children ~moreProps:Props#moreProps ()
    end
  end
  
  module Upper_with_aria = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div aria-hidden=\"true\">";
                      ReactDOM.write_to_buffer b children;
                      Buffer.add_string b "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div"
                        (Stdlib.List.filter_map Stdlib.Fun.id
                           [
                             Some
                               (React.JSX.String
                                  ( "aria-hidden",
                                    "aria-hidden",
                                    Stdlib.Bool.to_string ("true" : bool) ));
                           ])
                        [ children ]);
                } )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Form_with_method = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<form method=\"GET\">";
                      ReactDOM.write_to_buffer b children;
                      Buffer.add_string b "</form>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "form"
                        (Stdlib.List.filter_map Stdlib.Fun.id
                           [
                             Some
                               (React.JSX.String
                                  ("method", "method", ("GET" : string)));
                           ])
                        [ children ]);
                } )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Form_with_method = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.createElement "form"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     (match
                        (`String ""
                          : [ `String of string
                            | `Function of 'a Runtime.server_function ])
                      with
                     | `String s ->
                         Some
                           (React.JSX.String ("action", "action", (s : string)))
                     | `Function f ->
                         Some
                           (React.JSX.Action
                              ( "action",
                                "action",
                                (f : 'a Runtime.server_function) )));
                   ])
                [ children ] )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Form_with_action_function = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.createElement "form"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     (match
                        (`Function
                           {
                             id = "123";
                             call = (fun () -> Js.Promise.resolve "Hello");
                           }
                          : [ `String of string
                            | `Function of 'a Runtime.server_function ])
                      with
                     | `String s ->
                         Some
                           (React.JSX.String ("action", "action", (s : string)))
                     | `Function f ->
                         Some
                           (React.JSX.Action
                              ( "action",
                                "action",
                                (f : 'a Runtime.server_function) )));
                   ])
                [ children ] )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Form_with_action_string = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.createElement "form"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     (match
                        (`String ""
                          : [ `String of string
                            | `Function of 'a Runtime.server_function ])
                      with
                     | `String s ->
                         Some
                           (React.JSX.String ("action", "action", (s : string)))
                     | `Function f ->
                         Some
                           (React.JSX.Action
                              ( "action",
                                "action",
                                (f : 'a Runtime.server_function) )));
                   ])
                [ children ] )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Button_with_formAction_string = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.createElement "button"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     (match
                        (`String ""
                          : [ `String of string
                            | `Function of 'a Runtime.server_function ])
                      with
                     | `String s ->
                         Some
                           (React.JSX.String
                              ("formaction", "formAction", (s : string)))
                     | `Function f ->
                         Some
                           (React.JSX.Action
                              ( "formaction",
                                "formAction",
                                (f : 'a Runtime.server_function) )));
                   ])
                [ children ] )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  module Button_with_formAction_function = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.createElement "button"
                (Stdlib.List.filter_map Stdlib.Fun.id
                   [
                     (match
                        (`Function
                           {
                             id = "123";
                             call = (fun () -> Js.Promise.resolve "Hello");
                           }
                          : [ `String of string
                            | `Function of 'a Runtime.server_function ])
                      with
                     | `String s ->
                         Some
                           (React.JSX.String
                              ("formaction", "formAction", (s : string)))
                     | `Function f ->
                         Some
                           (React.JSX.Action
                              ( "formaction",
                                "formAction",
                                (f : 'a Runtime.server_function) )));
                   ])
                [ children ] )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  let a =
    Uppercase.make
      (Uppercase.makeProps
         ~children:
           (React.Static
              {
                prerendered = "<div></div>";
                original = React.createElement "div" [] [];
              })
         ())
  
  module Async_component = struct
    include struct
      let makeProps ~(children : 'children) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
            ~present:true children
        in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Async_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div class=\"async-component\">";
                      ReactDOM.write_to_buffer b children;
                      Buffer.add_string b "</div>";
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
                                    ("async-component" : string) ));
                           ])
                        [ children ]);
                } )
  
      let make ?(key : string option) (Props : < children : 'children > Js.t) =
        make ?key ~children:Props#children ()
    end
  end
  
  let a =
    Async_component.make
      (Async_component.makeProps
         ~children:
           (React.Static
              {
                prerendered = "<div></div>";
                original = React.createElement "div" [] [];
              })
         ())
  
  module Sequence = struct
    include struct
      let makeProps ~(lola : 'lola) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"lola" ~js_name:"lola"
            ~present:true lola
        in
        let __js_obj =
          object
            method lola = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < lola : 'lola > Js.t)
  
      let make ?key:(_ : string option) ~lola () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              let state, setState = React.useState lola in
              React.useEffect (fun () ->
                  setState lola;
                  None);
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div>";
                      ReactDOM.escape_to_buffer b state;
                      Buffer.add_string b "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" [] [ React.string state ]);
                } )
  
      let make ?(key : string option) (Props : < lola : 'lola > Js.t) =
        make ?key ~lola:Props#lola ()
    end
  end
  
  module Use_context = struct
    include struct
      let makeProps () =
        let __js_obj = object end in
        (Js.Obj.Internal.register_abstract __js_obj [] : < > Js.t)
  
      let make ?key:(_ : string option) () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              let captured = React.useContext Context.value in
              React.Writer
                {
                  emit =
                    (fun b ->
                      Buffer.add_string b "<div>";
                      ReactDOM.escape_to_buffer b captured;
                      Buffer.add_string b "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" [] [ React.string captured ]);
                } )
  
      let make ?(key : string option) (_Props : < > Js.t) = make ?key ()
    end
  end
