type t = Dom.documentType;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__ChildNode.Impl({
  type nonrec t = t;
});

[@mel.get] external name: t => string = "name";
[@mel.get] external publicId: t => string = "publicId";
[@mel.get] external systemId: t => string = "systemId";
