[@@@warning "-32"]
open Melange_json.Primitives
type lola = {
  name: string }[@@deriving json]
include
  struct
    let makeProps ~initial:(initial : int) ~lola:(lola : lola)
      ~children:(children : React.element)
      ~maybe_children:(maybe_children : React.element option)
      ?key:(key : string option) () =
      (Obj.magic
         (let (__js_obj_cell_0, __js_obj_entry_0) =
            Js.Obj.Internal.slot_ref ~method_name:"initial"
              ~js_name:"initial" ~present:true initial in
          let (__js_obj_cell_1, __js_obj_entry_1) =
            Js.Obj.Internal.slot_ref ~method_name:"lola" ~js_name:"lola"
              ~present:true lola in
          let (__js_obj_cell_2, __js_obj_entry_2) =
            Js.Obj.Internal.slot_ref ~method_name:"children"
              ~js_name:"children" ~present:true children in
          let (__js_obj_cell_3, __js_obj_entry_3) =
            Js.Obj.Internal.slot_ref ~method_name:"maybe_children"
              ~js_name:"maybe_children" ~present:true maybe_children in
          let (__js_obj_cell_4, __js_obj_entry_4) =
            Js.Obj.Internal.slot_ref ~method_name:"key" ~js_name:"key"
              ~present:(match key with | None -> false | Some _ -> true) key in
          let __js_obj =
            object
              method initial = !__js_obj_cell_0
              method lola = !__js_obj_cell_1
              method children = !__js_obj_cell_2
              method maybe_children = !__js_obj_cell_3
              method key = !__js_obj_cell_4
            end in
          Js.Obj.Internal.register_structural __js_obj
            [__js_obj_entry_0;
            __js_obj_entry_1;
            __js_obj_entry_2;
            __js_obj_entry_3;
            __js_obj_entry_4]) : <
                                   initial: int  ;lola: lola  ;children: 
                                                                 React.element
                                                                  ;maybe_children: 
                                                                    React.element
                                                                    option  
                                   >  Js.t)
    let make ?key:(key : string option) ~initial:(initial : int) =
      fun ~lola:(lola : lola) ->
        fun ~children:(children : React.element) ->
          ((fun ~maybe_children:(maybe_children : React.element option) () ->
              React.Client_component
                {
                  key;
                  import_module = "output.ml";
                  import_name = "";
                  props =
                    [("initial",
                       (React.Model.Json (([%to_json : int]) initial)));
                    ("lola", (React.Model.Json (([%to_json : lola]) lola)));
                    ("children",
                      (React.Model.Element (children : React.element)));
                    ("maybe_children",
                      ((match maybe_children with
                        | Some prop ->
                            React.Model.Element (prop : React.element)
                        | None -> React.Model.Json `Null)))];
                  client =
                    (React.Upper_case_component
                       (Stdlib.__FUNCTION__,
                         (fun () ->
                            React.createElement "section" []
                              [React.createElement "h1" []
                                 [React.string lola.name];
                              React.createElement "p" [] [React.int initial];
                              React.createElement "div" [] [children];
                              (match maybe_children with
                               | ((Some children)[@explicit_arity ]) ->
                                   children
                               | None -> React.null)])))
                })
          [@warning "-16"])
    let make
      (Props :
        <
          initial: int  ;lola: lola  ;children: React.element  ;maybe_children: 
                                                                  React.element
                                                                    option  
          >  Js.t)
      =
      make ?key:((Obj.magic Props : < key: string option   > )#key)
        ~initial:(Props#initial) ~lola:(Props#lola)
        ~children:(Props#children) ~maybe_children:(Props#maybe_children) ()
  end
