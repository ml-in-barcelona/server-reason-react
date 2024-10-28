let make () =
  let stream, push_to_stream = Lwt_stream.create () in
  let push v = push_to_stream (Some v) in
  let close () = push_to_stream None in
  (stream, push, close)

let to_list stream = Lwt_stream.to_list stream
let subscribe ~fn stream = Lwt_stream.iter_s fn stream
