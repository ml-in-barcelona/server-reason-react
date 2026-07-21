Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module React_component_with_props = struct
    include struct
      let makeProps ~(lola : 'lola) () =
        let __js_obj_cell_0 = Stdlib.ref lola in
        let __js_obj =
          object
            method lola = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"lola" ~js_name:"lola"
                 ~present:true __js_obj_cell_0;
             ])
          : < lola : 'lola > Js.t)
  
      let make ?key:(_ : string option) ~lola () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:_ ->
                      Buffer.add_string __buf "<div>";
                      ReactDOM.escape_to_buffer __buf lola;
                      Buffer.add_string __buf "</div>";
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
  
  module Using_React_memo = struct
    include struct
      let makeProps ~(a : 'a) () =
        let __js_obj_cell_0 = Stdlib.ref a in
        let __js_obj =
          object
            method a = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"a" ~js_name:"a"
                 ~present:true __js_obj_cell_0;
             ])
          : < a : 'a > Js.t)
  
      let make ?key:(_ : string option) ~a () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<div>";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false
                           (Printf.sprintf "`a` is %s" a |> React.string)
                       in
                       ());
                      Buffer.add_string __buf "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" []
                        [ Printf.sprintf "`a` is %s" a |> React.string ]);
                } )
  
      let make ?(key : string option) (Props : < a : 'a > Js.t) =
        make ?key ~a:Props#a ()
    end
  end
  
  module Using_memo_custom_compare_Props = struct
    include struct
      let makeProps ~(a : 'a) () =
        let __js_obj_cell_0 = Stdlib.ref a in
        let __js_obj =
          object
            method a = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"a" ~js_name:"a"
                 ~present:true __js_obj_cell_0;
             ])
          : < a : 'a > Js.t)
  
      let make ?key:(_ : string option) ~a () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<div>";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false
                           (Printf.sprintf "`a` is %d" a |> React.string)
                       in
                       ());
                      Buffer.add_string __buf "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" []
                        [ Printf.sprintf "`a` is %d" a |> React.string ]);
                } )
  
      let make ?(key : string option) (Props : < a : 'a > Js.t) =
        make ?key ~a:Props#a ()
    end
  end
  
  module Forward_Ref = struct
    include struct
      let makeProps ~(children : 'children) ~(buttonRef : 'buttonRef) () =
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj_cell_1 = Stdlib.ref buttonRef in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
            method buttonRef = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
               Js.Obj.Internal.deferred_entry ~method_name:"buttonRef"
                 ~js_name:"buttonRef" ~present:true __js_obj_cell_1;
             ])
          : < children : 'children ; buttonRef : 'buttonRef > Js.t)
  
      let make ?key:(_ : string option) ~children =
       (fun ~buttonRef () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<button class=\"FancyButton\">";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false children
                       in
                       ());
                      Buffer.add_string __buf "</button>";
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
        let __js_obj_cell_0 = Stdlib.ref name in
        let __js_obj_cell_1 = Stdlib.ref isDisabled in
        let __js_obj_present_1 =
          match isDisabled with None -> false | Some _ -> true
        in
        let __js_obj =
          object
            method name = !__js_obj_cell_0
            method isDisabled = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"name" ~js_name:"name"
                 ~present:true __js_obj_cell_0;
               Js.Obj.Internal.deferred_entry ~method_name:"isDisabled"
                 ~js_name:"isDisabled" ~present:__js_obj_present_1 __js_obj_cell_1;
             ])
          : < name : 'name ; isDisabled : 'isDisabled option > Js.t)
  
      let make ?key:(_ : string option) ~name =
       (fun ?isDisabled () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              let onClick event = Js.log event in
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:_ ->
                      Buffer.add_string __buf "<button";
                      Buffer.add_char __buf ' ';
                      Buffer.add_string __buf "name";
                      Buffer.add_string __buf "=\"";
                      ReactDOM.escape_to_buffer __buf (name : string);
                      Buffer.add_char __buf '"';
                      if (isDisabled : bool) then (
                        Buffer.add_char __buf ' ';
                        Buffer.add_string __buf "disabled");
                      Buffer.add_string __buf "></button>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "button"
                        (Stdlib.List.filter_map Stdlib.Fun.id
                           [
                             Some
                               (React.JSX.String ("name", "name", (name : string)));
                             Some
                               (React.JSX.Event
                                  ( "onClick",
                                    React.JSX.Mouse
                                      (onClick : React.Event.Mouse.t -> unit) ));
                             Some
                               (React.JSX.Bool
                                  ("disabled", "disabled", (isDisabled : bool)));
                           ])
                        []);
                } ))
        [@warning "-16"]
  
      let make ?(key : string option)
          (Props : < name : 'name ; isDisabled : 'isDisabled option > Js.t) =
        make ?key ~name:Props#name ?isDisabled:Props#isDisabled ()
    end
  end
  
  module Children_as_string = struct
    include struct
      let makeProps ?(name : 'name option) () =
        let __js_obj_cell_0 = Stdlib.ref name in
        let __js_obj_present_0 =
          match name with None -> false | Some _ -> true
        in
        let __js_obj =
          object
            method name = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"name" ~js_name:"name"
                 ~present:__js_obj_present_0 __js_obj_cell_0;
             ])
          : < name : 'name option > Js.t)
  
      let make ?key:(_ : string option) ?(name = "joe") () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<div>";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false
                           (Printf.sprintf "`name` is %s" name |> React.string)
                       in
                       ());
                      Buffer.add_string __buf "</div>";
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj_cell_1 = Stdlib.ref moreProps in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
            method moreProps = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
               Js.Obj.Internal.deferred_entry ~method_name:"moreProps"
                 ~js_name:"moreProps" ~present:true __js_obj_cell_1;
             ])
          : < children : 'children ; moreProps : 'moreProps > Js.t)
  
      let make ?key:(_ : string option) ~children =
       (fun ~moreProps () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      let __prev_text = ref false in
                      Buffer.add_string __buf "<!DOCTYPE html>";
                      Buffer.add_string __buf "<html>";
                      __prev_text :=
                        ReactDOM.write_element_to_buffer __buf
                          ~separators:__separators ~prev_text:false
                          (React.Writer
                             {
                               emit =
                                 (fun __buf ~separators:__separators ->
                                   Buffer.add_string __buf "<head>";
                                   (let (_ : bool) =
                                      ReactDOM.write_element_to_buffer __buf
                                        ~separators:__separators ~prev_text:false
                                        (React.Writer
                                           {
                                             emit =
                                               (fun __buf ~separators:_ ->
                                                 Buffer.add_string __buf "<title>";
                                                 ReactDOM.escape_to_buffer __buf
                                                   ("SSR React " ^ moreProps);
                                                 Buffer.add_string __buf
                                                   "</title>";
                                                 ());
                                             original =
                                               (fun () ->
                                                 React.createElement "title" []
                                                   [
                                                     React.string
                                                       ("SSR React " ^ moreProps);
                                                   ]);
                                           })
                                    in
                                    ());
                                   Buffer.add_string __buf "</head>";
                                   ());
                               original =
                                 (fun () ->
                                   React.createElement "head" []
                                     [
                                       React.Writer
                                         {
                                           emit =
                                             (fun __buf ~separators:_ ->
                                               Buffer.add_string __buf "<title>";
                                               ReactDOM.escape_to_buffer __buf
                                                 ("SSR React " ^ moreProps);
                                               Buffer.add_string __buf "</title>";
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
                      __prev_text :=
                        ReactDOM.write_element_to_buffer __buf
                          ~separators:__separators ~prev_text:!__prev_text
                          (React.Writer
                             {
                               emit =
                                 (fun __buf ~separators:__separators ->
                                   let __prev_text = ref false in
                                   Buffer.add_string __buf "<body>";
                                   __prev_text :=
                                     ReactDOM.write_element_to_buffer __buf
                                       ~separators:__separators ~prev_text:false
                                       (React.Writer
                                          {
                                            emit =
                                              (fun __buf
                                                ~separators:__separators
                                              ->
                                                Buffer.add_string __buf
                                                  "<div id=\"root\">";
                                                (let (_ : bool) =
                                                   ReactDOM
                                                   .write_element_to_buffer __buf
                                                     ~separators:__separators
                                                     ~prev_text:false children
                                                 in
                                                 ());
                                                Buffer.add_string __buf "</div>";
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
                                   __prev_text :=
                                     ReactDOM.write_element_to_buffer __buf
                                       ~separators:__separators
                                       ~prev_text:!__prev_text
                                       (React.Static
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
                                          });
                                   Buffer.add_string __buf "</body>";
                                   ());
                               original =
                                 (fun () ->
                                   React.createElement "body" []
                                     [
                                       React.Writer
                                         {
                                           emit =
                                             (fun __buf
                                               ~separators:__separators
                                             ->
                                               Buffer.add_string __buf
                                                 "<div id=\"root\">";
                                               (let (_ : bool) =
                                                  ReactDOM.write_element_to_buffer
                                                    __buf ~separators:__separators
                                                    ~prev_text:false children
                                                in
                                                ());
                                               Buffer.add_string __buf "</div>";
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
                             });
                      Buffer.add_string __buf "</html>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "html" []
                        [
                          React.Writer
                            {
                              emit =
                                (fun __buf ~separators:__separators ->
                                  Buffer.add_string __buf "<head>";
                                  (let (_ : bool) =
                                     ReactDOM.write_element_to_buffer __buf
                                       ~separators:__separators ~prev_text:false
                                       (React.Writer
                                          {
                                            emit =
                                              (fun __buf ~separators:_ ->
                                                Buffer.add_string __buf "<title>";
                                                ReactDOM.escape_to_buffer __buf
                                                  ("SSR React " ^ moreProps);
                                                Buffer.add_string __buf "</title>";
                                                ());
                                            original =
                                              (fun () ->
                                                React.createElement "title" []
                                                  [
                                                    React.string
                                                      ("SSR React " ^ moreProps);
                                                  ]);
                                          })
                                   in
                                   ());
                                  Buffer.add_string __buf "</head>";
                                  ());
                              original =
                                (fun () ->
                                  React.createElement "head" []
                                    [
                                      React.Writer
                                        {
                                          emit =
                                            (fun __buf ~separators:_ ->
                                              Buffer.add_string __buf "<title>";
                                              ReactDOM.escape_to_buffer __buf
                                                ("SSR React " ^ moreProps);
                                              Buffer.add_string __buf "</title>";
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
                                (fun __buf ~separators:__separators ->
                                  let __prev_text = ref false in
                                  Buffer.add_string __buf "<body>";
                                  __prev_text :=
                                    ReactDOM.write_element_to_buffer __buf
                                      ~separators:__separators ~prev_text:false
                                      (React.Writer
                                         {
                                           emit =
                                             (fun __buf
                                               ~separators:__separators
                                             ->
                                               Buffer.add_string __buf
                                                 "<div id=\"root\">";
                                               (let (_ : bool) =
                                                  ReactDOM.write_element_to_buffer
                                                    __buf ~separators:__separators
                                                    ~prev_text:false children
                                                in
                                                ());
                                               Buffer.add_string __buf "</div>";
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
                                  __prev_text :=
                                    ReactDOM.write_element_to_buffer __buf
                                      ~separators:__separators
                                      ~prev_text:!__prev_text
                                      (React.Static
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
                                         });
                                  Buffer.add_string __buf "</body>";
                                  ());
                              original =
                                (fun () ->
                                  React.createElement "body" []
                                    [
                                      React.Writer
                                        {
                                          emit =
                                            (fun __buf ~separators:__separators ->
                                              Buffer.add_string __buf
                                                "<div id=\"root\">";
                                              (let (_ : bool) =
                                                 ReactDOM.write_element_to_buffer
                                                   __buf ~separators:__separators
                                                   ~prev_text:false children
                                               in
                                               ());
                                              Buffer.add_string __buf "</div>";
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<div aria-hidden=\"true\">";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false children
                       in
                       ());
                      Buffer.add_string __buf "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div"
                        (Stdlib.List.filter_map Stdlib.Fun.id
                           [
                             Some
                               (React.JSX.BooleanishString
                                  ("aria-hidden", "aria-hidden", ("true" : bool)));
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<form method=\"GET\">";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false children
                       in
                       ());
                      Buffer.add_string __buf "</form>";
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref children in
        let __js_obj =
          object
            method children = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"children"
                 ~js_name:"children" ~present:true __js_obj_cell_0;
             ])
          : < children : 'children > Js.t)
  
      let make ?key:(_ : string option) ~children () =
        React.Async_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:__separators ->
                      Buffer.add_string __buf "<div class=\"async-component\">";
                      (let (_ : bool) =
                         ReactDOM.write_element_to_buffer __buf
                           ~separators:__separators ~prev_text:false children
                       in
                       ());
                      Buffer.add_string __buf "</div>";
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
        let __js_obj_cell_0 = Stdlib.ref lola in
        let __js_obj =
          object
            method lola = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"lola" ~js_name:"lola"
                 ~present:true __js_obj_cell_0;
             ])
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
                    (fun __buf ~separators:_ ->
                      Buffer.add_string __buf "<div>";
                      ReactDOM.escape_to_buffer __buf state;
                      Buffer.add_string __buf "</div>";
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
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () -> [])
          : < > Js.t)
  
      let make ?key:(_ : string option) () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              let captured = React.useContext Context.value in
              React.Writer
                {
                  emit =
                    (fun __buf ~separators:_ ->
                      Buffer.add_string __buf "<div>";
                      ReactDOM.escape_to_buffer __buf captured;
                      Buffer.add_string __buf "</div>";
                      ());
                  original =
                    (fun () ->
                      React.createElement "div" [] [ React.string captured ]);
                } )
  
      let make ?(key : string option) (_Props : < > Js.t) = make ?key ()
    end
  end
