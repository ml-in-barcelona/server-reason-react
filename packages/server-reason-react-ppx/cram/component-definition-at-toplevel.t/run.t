  $ ../ppx.sh --output ml input.re
  let unsafeWhenNotZero prop =
   fun value -> if value = 0 then [] else [ prop ^ "-" ^ Int.to_string value ]
  
  include struct
    let makeProps ?(children : 'children option) ?(top : 'top option)
        ?(left : 'left option) ?(right : 'right option) ?(bottom : 'bottom option)
        ?(all : 'all option) () =
      let __js_obj_cell_0 = Stdlib.ref children in
      let __js_obj_present_0 =
        match children with None -> false | Some _ -> true
      in
      let __js_obj_cell_1 = Stdlib.ref top in
      let __js_obj_present_1 = match top with None -> false | Some _ -> true in
      let __js_obj_cell_2 = Stdlib.ref left in
      let __js_obj_present_2 = match left with None -> false | Some _ -> true in
      let __js_obj_cell_3 = Stdlib.ref right in
      let __js_obj_present_3 =
        match right with None -> false | Some _ -> true
      in
      let __js_obj_cell_4 = Stdlib.ref bottom in
      let __js_obj_present_4 =
        match bottom with None -> false | Some _ -> true
      in
      let __js_obj_cell_5 = Stdlib.ref all in
      let __js_obj_present_5 = match all with None -> false | Some _ -> true in
      let __js_obj =
        object
          method children = !__js_obj_cell_0
          method top = !__js_obj_cell_1
          method left = !__js_obj_cell_2
          method right = !__js_obj_cell_3
          method bottom = !__js_obj_cell_4
          method all = !__js_obj_cell_5
        end
      in
      (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
           [
             Js.Obj.Internal.deferred_entry ~method_name:"children"
               ~js_name:"children" ~present:__js_obj_present_0 __js_obj_cell_0;
             Js.Obj.Internal.deferred_entry ~method_name:"top" ~js_name:"top"
               ~present:__js_obj_present_1 __js_obj_cell_1;
             Js.Obj.Internal.deferred_entry ~method_name:"left" ~js_name:"left"
               ~present:__js_obj_present_2 __js_obj_cell_2;
             Js.Obj.Internal.deferred_entry ~method_name:"right" ~js_name:"right"
               ~present:__js_obj_present_3 __js_obj_cell_3;
             Js.Obj.Internal.deferred_entry ~method_name:"bottom"
               ~js_name:"bottom" ~present:__js_obj_present_4 __js_obj_cell_4;
             Js.Obj.Internal.deferred_entry ~method_name:"all" ~js_name:"all"
               ~present:__js_obj_present_5 __js_obj_cell_5;
           ])
        : < children : 'children option
          ; top : 'top option
          ; left : 'left option
          ; right : 'right option
          ; bottom : 'bottom option
          ; all : 'all option >
          Js.t)
  
    let make ?key:(_ : string option) ?children =
     fun ?(top = 0) ->
      fun ?(left = 0) ->
       fun ?(right = 0) ->
        fun ?(bottom = 0) ->
         (fun ?(all = 0) () ->
          React.Upper_case_component
            ( Stdlib.__FUNCTION__,
              fun () ->
                let className =
                  Cx.make
                    (List.flatten
                       [
                         unsafeWhenNotZero "mt" top;
                         unsafeWhenNotZero "mb" bottom;
                         unsafeWhenNotZero "ml" left;
                         unsafeWhenNotZero "mr" right;
                         unsafeWhenNotZero "m" all;
                       ])
                in
                React.Writer
                  {
                    emit =
                      (fun b ->
                        Buffer.add_string b "<div";
                        Buffer.add_char b ' ';
                        Buffer.add_string b "class";
                        Buffer.add_string b "=\"";
                        ReactDOM.escape_to_buffer b (className : string);
                        Buffer.add_char b '"';
                        Buffer.add_string b ">";
                        ReactDOM.write_to_buffer b
                          (match children with
                          | None -> React.null
                          | ((Some c) [@explicit_arity]) -> c);
                        Buffer.add_string b "</div>";
                        ());
                    original =
                      (fun () ->
                        React.createElement "div"
                          (Stdlib.List.filter_map Stdlib.Fun.id
                             [
                               Some
                                 (React.JSX.String
                                    ("class", "className", (className : string)));
                             ])
                          [
                            (match children with
                            | None -> React.null
                            | ((Some c) [@explicit_arity]) -> c);
                          ]);
                  } ))
          [@warning "-16"]
  
    let make ?(key : string option)
        (Props :
          < children : 'children option
          ; top : 'top option
          ; left : 'left option
          ; right : 'right option
          ; bottom : 'bottom option
          ; all : 'all option >
          Js.t) =
      make ?key ?children:Props#children ?top:Props#top ?left:Props#left
        ?right:Props#right ?bottom:Props#bottom ?all:Props#all ()
  end
