type attributeType =
  | String
  | Int
  | Bool
  | Style
  | Ref
  | InnerHtml

type eventType =
  | Clipboard
  | Composition
  | Keyboard
  | Focus
  | Form
  | Mouse
  | Selection
  | Touch
  | UI
  | Wheel
  | Media
  | Image
  | Animation
  | Transition
  | Pointer
  | Inline
  | Drag
(* _onclick *)

type attribute =
  { type_ : attributeType
  ; name : string
  ; jsxName : string
  }

type event =
  { type_ : eventType
  ; name : string
  }

type prop =
  | Attribute of attribute
  | Event of event

type errors =
  [ `ElementNotFound
  | `AttributeNotFound
  ]

val getJSXName : prop -> string
val findByName : string -> string -> (prop, errors) result
val isReactValidProp : string -> bool
val find_closest_name : string -> string
