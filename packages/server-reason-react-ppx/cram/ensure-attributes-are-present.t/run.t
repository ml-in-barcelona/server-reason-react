  $ ../ppx.sh --output ml input.re
  include struct
    let makeProps ?(key : string option) () =
      (Obj.magic
         (let __js_obj_cell_0, __js_obj_entry_0 =
            Js.Obj.Internal.slot_ref ~method_name:"key" ~js_name:"key"
              ~present:(match key with None -> false | Some _ -> true)
              key
          in
          let __js_obj =
            object
              method key = !__js_obj_cell_0
            end
          in
          Js.Obj.Internal.register_structural __js_obj [ __js_obj_entry_0 ])
        : < > Js.t)
  
    let make ?key:(_ : string option) () =
      React.Upper_case_component
        ( Stdlib.__FUNCTION__,
          fun () ->
            React.Static
              {
                prerendered = "<div>lol</div>";
                original = React.createElement "div" [] [ React.string "lol" ];
              } )
    [@@platform js]
  
    let make (Props : < > Js.t) =
      make ?key:(Obj.magic Props : < key : string option >)#key ()
  end
