val renderToString : React.element -> string
val renderToStaticMarkup : React.element -> string
val querySelector : string -> Webapi.Dom.element option
val render : React.element -> Webapi.Dom.element -> unit
val createPortal : React.element -> Webapi.Dom.element -> React.element
val hydrate : React.element -> Webapi.Dom.element -> unit

module Style = ReactDOMStyle
