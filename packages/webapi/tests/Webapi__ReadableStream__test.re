open Webapi.ReadableStream;

module DefaultReader__test = {
  open! DefaultReader;

  let test_releaseLock = reader => releaseLock(reader);
};

let test_locked = stream => locked(stream);

let test_cancel = stream => cancel(stream);

let test_cancelWith = stream => cancelWith("reason", stream);

let test_getReader = stream => getReader(stream);

let test_getReaderBYOB = stream => getReaderBYOB(stream);

let test_tee = stream => {
  let (stream1, stream2) = tee(stream);

  stream1 |> cancel |> ignore;
  stream2 |> cancel |> ignore;
};
