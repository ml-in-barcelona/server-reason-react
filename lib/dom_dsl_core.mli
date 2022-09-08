module Prop : sig
  type t

  val any : string -> _ -> t
  val string : string -> string -> t
  val bool : string -> bool -> t
  val int : string -> int -> t
  val float_ : string -> float -> t
  val event : string -> (_ Event.synthetic -> unit) -> t
  val maybe : ('a -> t) -> 'a option -> t
  val key : string -> t
  val ref_ : Dom.dom_ref -> t
end

module Element : sig
  val h : string -> Prop.t array -> Core.element list -> Core.element
end

module Common : sig
  module Context : sig
    module Provider : sig
      val make :
        'a Core.Context.t -> value:'a -> Core.element list -> Core.element
    end
  end

  val fragment : Core.element list -> Core.element
  val none : Core.element
  val string : string -> Core.element
  val int : int -> Core.element
  val float : float -> Core.element
  val maybe : ('a -> Core.element) -> 'a option -> Core.element
end
