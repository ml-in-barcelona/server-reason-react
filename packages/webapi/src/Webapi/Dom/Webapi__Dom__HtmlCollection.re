type t = Dom.htmlCollection;

[@mel.scope ("Array", "prototype", "slice")]
external toArray: t => array(Dom.element) = "call";

[@mel.get] external length: t => int = "length";
[@mel.send.pipe: t] [@mel.return nullable]
external item: int => option(Dom.element) = "item";
[@mel.send.pipe: t] [@mel.return nullable]
external namedItem: string => option(Dom.element) = "namedItem";
