type t = Dom.attr;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});

[@mel.get] external namespaceURI: t => string = "namespaceURI";
[@mel.get] external prefix: t => string = "prefix";
[@mel.get] external localName: t => string = "localName";
[@mel.get] external name: t => string = "name";
[@mel.get] external value: t => string = "value";
[@mel.get] [@mel.return nullable]
external ownerElement: t => option(Dom.element) = "ownerElement";
[@mel.get] external specified: t => bool = "specified"; /* useless; always returns true (exact wording from spec) */
