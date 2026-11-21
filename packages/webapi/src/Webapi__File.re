type t = Fetch.file;

[@text "{1 Blob superclass}"];

include Webapi__Blob.Impl({
  type nonrec t = t;
});

[@text "{1 File class}"];

[@mel.get] external lastModified: t => float = "lastModified";

[@mel.get] external name: t => string = "name";

[@mel.get] external preview: t => string = "preview";
