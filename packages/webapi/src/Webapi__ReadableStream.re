module type Reader = {
  type t;
  type closed;

  /* [@mel.send] external closed: t => Js.Promise.t(closed) = "closed"; */
  /* [@mel.send] external cancel: t => Js.Promise.t(unit) = "cancel"; */
  /* [@mel.send.pipe: t] external cancelWith: string => Js.Promise.t(string) = "cancel"; */
  [@mel.send] external releaseLock: t => unit = "releaseLock";
};

module rec DefaultReader: {
  include Reader;
  /* [@mel.send] external read: t => Js.Promise.t(Fetch__Iterator.Next.t(string)) = "read"; */
} = DefaultReader;

module rec BYOBReader: {
  include Reader;
  // [@mel.send.pipe: t] external read: view => Js.Promise.t(Fetch__Iterator.Next.t(string)) = "read";
} = BYOBReader;

type t = Fetch.readableStream;

[@mel.get] external locked: t => bool = "locked";
/* [@mel.send] external cancel: t => Js.Promise.t(unit) = "cancel"; */
/* [@mel.send.pipe: t] external cancelWith: string => Js.Promise.t(string) = "cancel"; */
[@mel.send] external getReader: t => DefaultReader.t = "getReader";
[@mel.send]
external getReaderBYOB:
  (t, [@mel.as {json|{"mode": "byob"}|json}] _) => BYOBReader.t =
  "getReader";
[@mel.send] external tee: t => (t, t) = "tee";
