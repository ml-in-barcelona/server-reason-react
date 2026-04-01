  $ ../ppx.sh --output ml input.re
  module Greeting : sig
    include sig
      val makeProps : ?mockup:string -> unit -> < mockup : string option > Js.t
  
      val make :
        (< mockup : string option > Js.t, React.element) React.componentLike
    end
  end = struct
    include struct
      let makeProps ?(mockup : string option) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"mockup" ~js_name:"mockup"
            ~present:(match mockup with None -> false | Some _ -> true)
            mockup
        in
        let __js_obj =
          object
            method mockup = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < mockup : string option > Js.t)
  
      let make ?key:(_ : string option) ?(mockup : string option) () =
        React.Upper_case_component
          ( Stdlib.__FUNCTION__,
            fun () ->
              React.Static
                {
                  prerendered = "<button>Hello!</button>";
                  original =
                    React.createElement "button" [] [ React.string "Hello!" ];
                } )
  
      let make ?(key : string option) (Props : < mockup : string option > Js.t) =
        make ?key ?mockup:Props#mockup ()
    end
  end
  
  module MyPropIsOptionOptionBoolLetWithValSig : sig
    include sig
      val makeProps : ?myProp:bool option -> unit -> < myProp : bool option > Js.t
  
      val make :
        (< myProp : bool option > Js.t, React.element) React.componentLike
    end
  end = struct
    include struct
      let makeProps ?(myProp : bool option option) () =
        let __js_obj_cell_0, __js_obj_entry_0 =
          Js.Obj.Internal.slot_ref ~method_name:"myProp" ~js_name:"myProp"
            ~present:(match myProp with None -> false | Some _ -> true)
            myProp
        in
        let __js_obj =
          object
            method myProp = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_abstract __js_obj [ __js_obj_entry_0 ]
          : < myProp : bool option option > Js.t)
  
      let make ?key:(_ : string option) ?(myProp : bool option option) () =
        React.Upper_case_component (Stdlib.__FUNCTION__, fun () -> React.null)
  
      let make ?(key : string option)
          (Props : < myProp : bool option option > Js.t) =
        make ?key ?myProp:Props#myProp ()
    end
  end
