module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external data: T.t => string = "data";
  [@mel.get] external length: T.t => int = "length";

  [@mel.send.pipe: T.t]
  external substringData: (~offset: int, ~count: int) => string =
    "substringData";
  [@mel.send.pipe: T.t] external appendData: string => unit = "appendData";
  [@mel.send.pipe: T.t]
  external insertData: (~offset: int, string) => unit = "insertData";
  [@mel.send.pipe: T.t]
  external deleteData: (~offset: int, ~count: int) => unit = "deleteData";
  [@mel.send.pipe: T.t]
  external replaceData: (~offset: int, ~count: int, string) => unit =
    "replaceData";
};

type t = Dom.characterData;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__NonDocumentTypeChildNode.Impl({
  type nonrec t = t;
});
include Webapi__Dom__ChildNode.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
