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
        let __js_obj_cell_0 = Stdlib.ref mockup in
        let __js_obj_present_0 =
          match mockup with None -> false | Some _ -> true
        in
        let __js_obj =
          object
            method mockup = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"mockup"
                 ~js_name:"mockup" ~present:__js_obj_present_0 __js_obj_cell_0;
             ])
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
        let __js_obj_cell_0 = Stdlib.ref myProp in
        let __js_obj_present_0 =
          match myProp with None -> false | Some _ -> true
        in
        let __js_obj =
          object
            method myProp = !__js_obj_cell_0
          end
        in
        (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"myProp"
                 ~js_name:"myProp" ~present:__js_obj_present_0 __js_obj_cell_0;
             ])
          : < myProp : bool option option > Js.t)
  
      let make ?key:(_ : string option) ?(myProp : bool option option) () =
        React.Upper_case_component (Stdlib.__FUNCTION__, fun () -> React.null)
  
      let make ?(key : string option)
          (Props : < myProp : bool option option > Js.t) =
        make ?key ?myProp:Props#myProp ()
    end
  end
