val renderToString : React.Element.t -> string
val renderToStaticMarkup : React.Element.t -> string
val querySelector : string -> 'b option
val render : React.Element.t -> 'b -> unit

module Style = ReactDOMStyle
