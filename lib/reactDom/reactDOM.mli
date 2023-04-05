type docType = HTML5 | HTML4 | HTML4_frameset | HTML4_transactional

val renderToString : ?docType:docType -> React.element -> string
val renderToStaticMarkup : ?docType:docType -> React.element -> string
val querySelector : string -> Webapi.Dom.element option
val render : React.element -> Webapi.Dom.element -> unit
val createPortal : React.element -> Webapi.Dom.element -> React.element
val hydrate : React.element -> Webapi.Dom.element -> unit

module Style = ReactDOMStyle
