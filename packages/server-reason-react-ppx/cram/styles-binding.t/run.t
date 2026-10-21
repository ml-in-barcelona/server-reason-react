In Melange mode, an `external make` declared with a `~styles` arg is rewritten
into an internal FFI external (with `~className` / `~style` instead) plus a
wrapper `let make` that keeps the ergonomic `~styles` API.
  $ ../ppx.sh --output ml -js input.re
  module Optional = struct
    include struct
      external make__styles_ffi :
        ?className:string ->
        ?style:ReactDOM.Style.t ->
        children:React.element ->
        React.element = "default"
      [@@mel.module "some-lib"]
  
      let make ?styles ~children =
        make__styles_ffi
          ?className:(match styles with None -> None | Some s -> Some (fst s))
          ?style:(match styles with None -> None | Some s -> Some (snd s))
          ~children
      [@@react.component]
    end
  end
  
  module Required = struct
    include struct
      external make__styles_ffi :
        ?className:string ->
        ?style:ReactDOM.Style.t ->
        children:React.element ->
        React.element = "default"
      [@@mel.module "some-lib"]
  
      let make ~styles ~children =
        make__styles_ffi
          ?className:(Some (fst styles))
          ?style:(Some (snd styles))
          ~children
      [@@react.component]
    end
  end
  
  module Extra = struct
    include struct
      external make__styles_ffi :
        ?className:string ->
        ?style:ReactDOM.Style.t ->
        ?onClick:(ReactEvent.Mouse.t -> unit) ->
        id:string ->
        children:React.element ->
        React.element = "default"
      [@@mel.module "some-lib"]
  
      let make ?styles ?onClick ~id ~children =
        make__styles_ffi
          ?className:(match styles with None -> None | Some s -> Some (fst s))
          ?style:(match styles with None -> None | Some s -> Some (snd s))
          ?onClick ~id ~children
      [@@react.component]
    end
  end
  
  module NoStyles = struct
    external make : ?className:string -> children:React.element -> React.element
      = "default"
    [@@mel.module "some-lib"] [@@react.component]
  end
  
  module ConflictClassName = struct
    [%%ocaml.error
    "server-reason-react: external bindings cannot declare both ~styles and \
     ~className. Use only ~styles to keep the ergonomic API."]
  end
  
  module ConflictStyle = struct
    [%%ocaml.error
    "server-reason-react: external bindings cannot declare both ~styles and \
     ~style. Use only ~styles to keep the ergonomic API."]
  end
