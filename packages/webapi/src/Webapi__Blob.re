module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external size: T.t => float = "size";

  [@mel.send.pipe: T.t]
  external slice: (~start: int=?, ~end_: int=?, ~contentType: string=?) => T.t =
    "slice";

  [@mel.send] external stream: T.t => Webapi__ReadableStream.t = "stream";

  [@mel.send] external text: T.t => Js.Promise.t(string) = "text";

  [@mel.get] external type_: T.t => string = "type";

  [@deprecated "Use [type_] instead"] [@mel.get]
  external _type: T.t => string = "type";
};

type t = Fetch.blob;

include Impl({
  type nonrec t = t;
});
