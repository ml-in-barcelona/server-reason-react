  $ ../ppx.sh --output ml input.re
  module Greeting : sig
    val make : ?mockup:string -> React.element
  end = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ?(mockup : string option) () ->
      React.createElement "button"
        ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
        [ React.string "Hello!" ]
  end
  
  module MyPropIsOptionOptionBoolLetWithValSig : sig
    val make : ?myProp:bool option -> React.element
  end = struct
    let make ?key =
     fun [@warning "-16"] [@warning "-16"] ?(myProp : bool option option) () ->
      React.null
  end
