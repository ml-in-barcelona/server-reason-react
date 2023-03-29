type docType =
  | HTML5
  | HTML4
  | HTML4_frameset
  | HTML4_transactional

val renderToString : ?docType:docType -> React.Element.t -> string
val renderToStaticMarkup : ?docType:docType -> React.Element.t -> string
val querySelector : string -> Webapi.Dom.element option
val render : React.Element.t -> Webapi.Dom.element -> unit
val createPortal : React.Element.t -> Webapi.Dom.element -> React.Element.t
val hydrate : React.Element.t -> Webapi.Dom.element -> unit

module Style = ReactDOMStyle
