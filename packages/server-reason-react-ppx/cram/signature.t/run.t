  $ ../ppx.sh --output ml input.re
  module Greeting : sig
    val make : ?mockup:string -> React.element
  end = struct
    let make ?key:_ =
     fun [@warning "-16"] ?(mockup : string option) () ->
      React.createElement "button" [] [ React.string "Hello!" ]
  end
  
  module MyPropIsOptionOptionBoolLetWithValSig : sig
    val make : ?myProp:bool option -> React.element
  end = struct
    let make ?key:_ =
     fun [@warning "-16"] ?(myProp : bool option option) () -> React.null
  end
