open Webapi.Blob;

let test_size = blob => blob |> size |> ignore;

let test_slice = blob => test_size(slice(~start=0, blob));

let test_stream = blob => blob |> stream;

let test_text = blob =>
  blob
  |> text
  |> Js.Promise.then_(string => string |> Js.log |> Js.Promise.resolve);

let test_type = blob => blob |> type_ |> Js.log;
