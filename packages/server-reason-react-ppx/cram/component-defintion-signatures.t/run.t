  $ ../ppx.sh --output ml input.re
  module Greeting : sig
    val make : ?key:string option -> ?mockup:string -> unit -> React.element
  end = struct
    let make ?key:(_ : string option) ?(mockup : string option) () =
      React.Upper_case_component
        ( __FUNCTION__,
          fun () ->
            React.createElementWithKey ~key:None "button" []
              [ React.string "Hello!" ] )
  end
  
  module MyPropIsOptionOptionBoolLetWithValSig : sig
    val make : ?key:string option -> ?myProp:bool option -> unit -> React.element
  end = struct
    let make ?key:(_ : string option) ?(myProp : bool option option) () =
      React.Upper_case_component (__FUNCTION__, fun () -> React.null)
  end
