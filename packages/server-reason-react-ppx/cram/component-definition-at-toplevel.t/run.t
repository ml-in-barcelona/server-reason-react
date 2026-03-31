  $ ../ppx.sh --output ml input.re
  let unsafeWhenNotZero prop =
   fun value -> if value = 0 then [] else [ prop ^ "-" ^ Int.to_string value ]
  
  include struct
    let makeProps ?(children : 'children option) ?(top : 'top option)
        ?(left : 'left option) ?(right : 'right option) ?(bottom : 'bottom option)
        ?(all : 'all option) ?(key : string option) () =
      (Obj.magic
         (let __js_obj_cell_0, __js_obj_entry_0 =
            Js.Obj.Internal.slot_ref ~method_name:"children" ~js_name:"children"
              ~present:(match children with None -> false | Some _ -> true)
              children
          in
          let __js_obj_cell_1, __js_obj_entry_1 =
            Js.Obj.Internal.slot_ref ~method_name:"top" ~js_name:"top"
              ~present:(match top with None -> false | Some _ -> true)
              top
          in
          let __js_obj_cell_2, __js_obj_entry_2 =
            Js.Obj.Internal.slot_ref ~method_name:"left" ~js_name:"left"
              ~present:(match left with None -> false | Some _ -> true)
              left
          in
          let __js_obj_cell_3, __js_obj_entry_3 =
            Js.Obj.Internal.slot_ref ~method_name:"right" ~js_name:"right"
              ~present:(match right with None -> false | Some _ -> true)
              right
          in
          let __js_obj_cell_4, __js_obj_entry_4 =
            Js.Obj.Internal.slot_ref ~method_name:"bottom" ~js_name:"bottom"
              ~present:(match bottom with None -> false | Some _ -> true)
              bottom
          in
          let __js_obj_cell_5, __js_obj_entry_5 =
            Js.Obj.Internal.slot_ref ~method_name:"all" ~js_name:"all"
              ~present:(match all with None -> false | Some _ -> true)
              all
          in
          let __js_obj_cell_6, __js_obj_entry_6 =
            Js.Obj.Internal.slot_ref ~method_name:"key" ~js_name:"key"
              ~present:(match key with None -> false | Some _ -> true)
              key
          in
          let __js_obj =
            object
              method children = !__js_obj_cell_0
              method top = !__js_obj_cell_1
              method left = !__js_obj_cell_2
              method right = !__js_obj_cell_3
              method bottom = !__js_obj_cell_4
              method all = !__js_obj_cell_5
              method key = !__js_obj_cell_6
            end
          in
          Js.Obj.Internal.register_structural __js_obj
            [
              __js_obj_entry_0;
              __js_obj_entry_1;
              __js_obj_entry_2;
              __js_obj_entry_3;
              __js_obj_entry_4;
              __js_obj_entry_5;
              __js_obj_entry_6;
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
                  ] ))
          [@warning "-16"]
  
    let make
        (Props :
          < children : 'children option
          ; top : 'top option
          ; left : 'left option
          ; right : 'right option
          ; bottom : 'bottom option
          ; all : 'all option >
          Js.t) =
      make ?key:(Obj.magic Props : < key : string option >)#key
        ?children:Props#children ?top:Props#top ?left:Props#left
        ?right:Props#right ?bottom:Props#bottom ?all:Props#all ()
  end
