module Impl = (T: {
                 type t;
               }) => {
  /* [@mel.send] external arrayBuffer: T.t => Js.Promise.t(Js.Typed_array.ArrayBuffer.t) =
     "arrayBuffer"; */

  [@mel.get] external size: T.t => float = "size";

  [@mel.send.pipe: T.t]
  external slice: (~start: int=?, ~end_: int=?, ~contentType: string=?) => T.t =
    "slice";

  /** @since 0.19.0 */
  [@mel.send]
  external stream: T.t => Webapi__ReadableStream.t = "stream";

  /* [@mel.send] external text: T.t => Js.Promise.t(string) = "text"; */

  [@mel.get] external type_: T.t => string = "type";

  /** Deprecated, use [type_] instead. */
  [@deprecated "Use [type_] instead"] [@mel.get]
  external _type: T.t => string = "type";
};

type t = Fetch.blob;

include Impl({
  type nonrec t = t;
});

// [@mel.new] external make: ... = "Blob";
