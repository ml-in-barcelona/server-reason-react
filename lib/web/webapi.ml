module Dom = struct
  type window
  type document
  type element
  type eventTarget

  module MouseEvent = struct
    let target event = event#target
    let stopPropagation () = ()
  end

  module Element = struct
    let closest event : element = event#target
    let contains (_target : element) (_parent : element) = false
  end

  module EventTarget = struct
    external unsafeAsDocument : eventTarget -> document = "%identity"
    external unsafeAsElement : eventTarget -> element = "%identity"
    external unsafeAsWindow : eventTarget -> window = "%identity"
  end

  module Document = struct
    let addMouseDownEventListener _handler (_document : document) = ()
  end
end
