Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module type X_int = sig
    val x : int
  end
  
  module Func (M : X_int) = struct
    let x = M.x + 1
  
    include struct
      let makeProps ~(a : 'a) ~(b : 'b) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"a" ~js_name:"a" ~present:true a
        in
        let __js_obj_cell_1, __js_obj_entry_1 =
          Js.Obj.Internal.slot_ref ~method_name:"b" ~js_name:"b" ~present:true b
        in
        let __js_obj =
          object
            method a = !__js_obj_cell_0
            method b = !__js_obj_cell_1
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj
           [ __js_obj_entry_0; __js_obj_entry_1 ]
          : < a : 'a ; b : 'b > Js.t)
  
      let make ?key:(_ : string option) ~a =
       (fun ~b () ->
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              print_endline "This function should be named `Test$Func`" M.x;
              React.Static
                {
                  prerendered = "<div></div>";
                  original = React.createElement "div" [] [];
                } ))
        [@warning "-16"]
  
      let make ?(key : string option) (Props : < a : 'a ; b : 'b > Js.t) =
        make ?key ~a:Props#a ~b:Props#b ()
    end
  end
