module Prop = struct
  type t = string * Js_of_ocaml.Js.Unsafe.any

  let any key value = (key, Js_of_ocaml.Js.Unsafe.inject value)
  let string key value = any key (Js_of_ocaml.Js.string value)
  let bool key value = any key (Js_of_ocaml.Js.bool value)
  let int key (value : int) = any key value
  let float_ key (value : float) = any key value

  let event key (f : _ Event.synthetic -> unit) =
    any key (Js_of_ocaml.Js.wrap_callback f)

  let maybe prop = function
    | Some value -> prop value
    | None -> any "" Js_of_ocaml.Js.undefined

  let key = string "key"
  let ref_ = (any "ref" : Dom.dom_ref -> t)
end

module Element = struct
  let h name props children =
    Dom.create_element name ~props:(Js_of_ocaml.Js.Unsafe.obj props) children
end

module Common = struct
  module Context = struct
    module Provider = struct
      let make context ~value children =
        Core.Context.Provider.make context ~value ~children ()
    end
  end

  let fragment children = Core.Fragment.make ~children ()
  let none = fragment []
  let string = Core.string
  let int = Core.int
  let float = Core.float
  let maybe f = function Some value -> f value | None -> none
end
