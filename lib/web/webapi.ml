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
  end

  module EventTarget = struct
    let contains (_target : element) = false

    external unsafeAsDocument : eventTarget -> document = "%identity"
    external unsafeAsElement : eventTarget -> element = "%identity"
    external unsafeAsWindow : eventTarget -> window = "%identity"
  end
end
