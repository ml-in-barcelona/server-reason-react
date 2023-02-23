val renderToString : React.Element.t -> string
val renderToStaticMarkup : React.Element.t -> string
val querySelector : string -> Webapi.Dom.element option
val render : React.Element.t -> Webapi.Dom.element -> unit
val createPortal : React.Element.t -> Webapi.Dom.element -> React.Element.t
val hydrate : React.Element.t -> Webapi.Dom.element -> unit

module Style = ReactDOMStyle
