  $ ../ppx.sh --output ml input.re
  module Greeting : sig
    val make : ?mockup:string -> React.element
  end = struct
    let make ?key:(_ : string option) ?(mockup : string option) () =
      React.Upper_case_component
        (fun () ->
          React.createElementWithKey ~key:None "button" []
            [ React.string "Hello!" ])
  end
  
  module MyPropIsOptionOptionBoolLetWithValSig : sig
    val make : ?myProp:bool option -> React.element
  end = struct
    let make ?key:(_ : string option) ?(myProp : bool option option) () =
      React.Upper_case_component (fun () -> React.null)
  end
