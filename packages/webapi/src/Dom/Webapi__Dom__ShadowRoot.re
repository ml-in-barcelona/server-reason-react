type t = Dom.shadowRoot;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__NonElementParentNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__DocumentOrShadowRoot.Impl({
  ();
});
include Webapi__Dom__ParentNode.Impl({
  type nonrec t = t;
});

[@mel.get] external shadowRootMode: t => string = "shadowRootMode";
let shadowRootMode: t => Webapi__Dom__Types.shadowRootMode =
  self => Webapi__Dom__Types.decodeShadowRootMode(shadowRootMode(self));
[@mel.get] external host: t => Dom.element = "host";
