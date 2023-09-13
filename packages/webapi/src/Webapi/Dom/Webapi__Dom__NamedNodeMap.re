type t = Dom.namedNodeMap;

[@mel.get] external length: t => int = "length";

[@mel.send.pipe: t] [@mel.return nullable]
external item: int => option(Dom.attr) = "item";
[@mel.send.pipe: t] [@mel.return nullable]
external getNamedItem: string => option(Dom.attr) = "getNamedItem";
[@mel.send.pipe: t] [@mel.return nullable]
external getNamedItemNS: (string, string) => option(Dom.attr) =
  "getNamedItemNS";
[@mel.send.pipe: t] external setNamedItem: Dom.attr => unit = "setNamedItem";
[@mel.send.pipe: t]
external setNamedItemNS: Dom.attr => unit = "setNamedItemNS";
[@mel.send.pipe: t]
external removeNamedItem: string => Dom.attr = "removeNamedItem";
[@mel.send.pipe: t]
external removeNamedItemNS: (string, string) => Dom.attr = "removeNamedItemNS";

[@mel.scope ("Array", "prototype", "slice")]
external toArray: t => array(Dom.attr) = "call";
