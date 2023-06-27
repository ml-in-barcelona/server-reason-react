type 'a synthetic

module MakeEventWithType (Type : sig
  type t
end) =
struct
  let bubbles : Type.t -> bool = fun _ -> false
  let cancelable : Type.t -> bool = fun _ -> false
  let currentTarget : Type.t -> < .. > Js.t = fun _ -> object end
  let defaultPrevented : Type.t -> bool = fun _ -> false
  let eventPhase : Type.t -> int = fun _ -> 0
  let isTrusted : Type.t -> bool = fun _ -> false
  let nativeEvent : Type.t -> < .. > Js.t = fun _ -> object end
  let preventDefault : Type.t -> unit = fun _ -> ()
  let isDefaultPrevented : Type.t -> bool = fun _ -> false
  let stopPropagation : Type.t -> unit = fun _ -> ()
  let isPropagationStopped : Type.t -> bool = fun _ -> false
  let target : Type.t -> < .. > Js.t = fun _ -> object end
  let timeStamp : Type.t -> float = fun _ -> 0.
  let type_ : Type.t -> string = fun _ -> ""
  let persist : Type.t -> unit = fun _ -> ()
end

module Synthetic = struct
  type tag
  type t = tag synthetic

  let bubbles : 'a synthetic -> bool = fun _ -> false
  let cancelable : 'a synthetic -> bool = fun _ -> false
  let currentTarget : 'a synthetic -> < .. > Js.t = fun _ -> object end
  let defaultPrevented : 'a synthetic -> bool = fun _ -> false
  let eventPhase : 'a synthetic -> int = fun _ -> 0
  let isTrusted : 'a synthetic -> bool = fun _ -> false
  let nativeEvent : 'a synthetic -> < .. > Js.t = fun _ -> object end
  let preventDefault : 'a synthetic -> unit = fun _ -> ()
  let isDefaultPrevented : 'a synthetic -> bool = fun _ -> false
  let stopPropagation : 'a synthetic -> unit = fun _ -> ()
  let isPropagationStopped : 'a synthetic -> bool = fun _ -> false
  let target : 'a synthetic -> < .. > Js.t = fun _ -> object end
  let timeStamp : 'a synthetic -> float = fun _ -> 0.
  let type_ : 'a synthetic -> string = fun _ -> ""
  let persist : 'a synthetic -> unit = fun _ -> ()
end

(* let toSyntheticEvent : 'a synthetic -> Synthetic.t = i -> i *)

module Clipboard = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let clipboardData : t -> < .. > Js.t = fun _ -> object end
end

module Composition = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let data : t -> string = fun _ -> ""
end

module Keyboard = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let altKey : t -> bool = fun _ -> false
  let charCode : t -> int = fun _ -> 0
  let ctrlKey : t -> bool = fun _ -> false
  let getModifierState : t -> string -> bool = fun _ _ -> false
  let key : t -> string = fun _ -> ""
  let keyCode : t -> int = fun _ -> 0
  let locale : t -> string = fun _ -> ""
  let location : t -> int = fun _ -> 0
  let metaKey : t -> bool = fun _ -> false
  let repeat : t -> bool = fun _ -> false
  let shiftKey : t -> bool = fun _ -> false
  let which : t -> int = fun _ -> 0
end

module Focus = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let relatedTarget : t -> < .. > Js.t option = fun _ -> None
end

module Form = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)
end

module Mouse = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let altKey : t -> bool = fun _ -> false
  let button : t -> int = fun _ -> 0
  let buttons : t -> int = fun _ -> 0
  let clientX : t -> int = fun _ -> 0
  let clientY : t -> int = fun _ -> 0
  let ctrlKey : t -> bool = fun _ -> false
  let getModifierState : t -> string -> bool = fun _ _ -> false
  let metaKey : t -> bool = fun _ -> false
  let movementX : t -> int = fun _ -> 0
  let movementY : t -> int = fun _ -> 0
  let pageX : t -> int = fun _ -> 0
  let pageY : t -> int = fun _ -> 0
  let relatedTarget : t -> < .. > Js.t option = fun _ -> None
  let screenX : t -> int = fun _ -> 0
  let screenY : t -> int = fun _ -> 0
  let shiftKey : t -> bool = fun _ -> false
end

module Pointer = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let detail : t -> int = fun _ -> 0

  (* let view : t -> Dom.window = fun _ -> object end *)
  let screenX : t -> int = fun _ -> 0
  let screenY : t -> int = fun _ -> 0
  let clientX : t -> int = fun _ -> 0
  let clientY : t -> int = fun _ -> 0
  let pageX : t -> int = fun _ -> 0
  let pageY : t -> int = fun _ -> 0
  let movementX : t -> int = fun _ -> 0
  let movementY : t -> int = fun _ -> 0
  let ctrlKey : t -> bool = fun _ -> false
  let shiftKey : t -> bool = fun _ -> false
  let altKey : t -> bool = fun _ -> false
  let metaKey : t -> bool = fun _ -> false
  let getModifierState : t -> string -> bool = fun _ _ -> false
  let button : t -> int = fun _ -> 0
  let buttons : t -> int = fun _ -> 0
  let relatedTarget : t -> < .. > Js.t option = fun _ -> None

  (* let pointerId : t -> Dom.eventPointerId *)
  let width : t -> float = fun _ -> 0.
  let height : t -> float = fun _ -> 0.
  let pressure : t -> float = fun _ -> 0.
  let tangentialPressure : t -> float = fun _ -> 0.
  let tiltX : t -> int = fun _ -> 0
  let tiltY : t -> int = fun _ -> 0
  let twist : t -> int = fun _ -> 0
  let pointerType : t -> string = fun _ -> ""
  let isPrimary : t -> bool = fun _ -> false
end

module Selection = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)
end

module Touch = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let altKey : t -> bool = fun _ -> false
  let changedTouches : t -> < .. > Js.t = fun _ -> object end
  let ctrlKey : t -> bool = fun _ -> false
  let getModifierState : t -> string -> bool = fun _ _ -> false
  let metaKey : t -> bool = fun _ -> false
  let shiftKey : t -> bool = fun _ -> false
  let targetTouches : t -> < .. > Js.t = fun _ -> object end
  let touches : t -> < .. > Js.t = fun _ -> object end
end

module UI = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let detail : t -> int = fun _ -> 0
  (* let view : t -> Dom.window *)
end

module Wheel = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let deltaMode : t -> int = fun _ -> 0
  let deltaX : t -> float = fun _ -> 0.
  let deltaY : t -> float = fun _ -> 0.
  let deltaZ : t -> float = fun _ -> 0.
end

module Media = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)
end

module Image = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)
end

module Animation = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let animationName : t -> string = fun _ -> ""
  let pseudoElement : t -> string = fun _ -> ""
  let elapsedTime : t -> float = fun _ -> 0.
end

module Transition = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let propertyName : t -> string = fun _ -> ""
  let pseudoElement : t -> string = fun _ -> ""
  let elapsedTime : t -> float = fun _ -> 0.
end

module Drag = struct
  type tag
  type t = tag synthetic

  include MakeEventWithType (struct
    type nonrec t = t [@@nonrec]
  end)

  let altKey : t -> bool = fun _ -> false
  let button : t -> int = fun _ -> 0
  let buttons : t -> int = fun _ -> 0
  let clientX : t -> int = fun _ -> 0
  let clientY : t -> int = fun _ -> 0
  let ctrlKey : t -> bool = fun _ -> false
  let getModifierState : t -> string -> bool = fun _ _ -> false
  let metaKey : t -> bool = fun _ -> false
  let movementX : t -> int = fun _ -> 0
  let movementY : t -> int = fun _ -> 0
  let pageX : t -> int = fun _ -> 0
  let pageY : t -> int = fun _ -> 0
  let relatedTarget : t -> < .. > Js.t option = fun _ -> None
  let screenX : t -> int = fun _ -> 0
  let screenY : t -> int = fun _ -> 0
  let shiftKey : t -> bool = fun _ -> false
  let dataTransfer : t -> < .. > Js.t option = fun _ -> None
end
