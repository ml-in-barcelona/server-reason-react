module type Reader = {
  type t;
  type closed;

  [@mel.send] external releaseLock: t => unit = "releaseLock";
};

module rec DefaultReader: {
  include Reader;
} = DefaultReader;

module rec BYOBReader: {
  include Reader;
} = BYOBReader;

type t = Fetch.readableStream;

[@mel.get] external locked: t => bool = "locked";
[@mel.send] external cancel: t => Js.Promise.t(unit) = "cancel";
[@mel.send.pipe: t]
external cancelWith: string => Js.Promise.t(string) = "cancel";
[@mel.send] external getReader: t => DefaultReader.t = "getReader";
[@mel.send]
external getReaderBYOB:
  (t, [@mel.as {json|{"mode": "byob"}|json}] _) => BYOBReader.t =
  "getReader";
[@mel.send] external tee: t => (t, t) = "tee";
