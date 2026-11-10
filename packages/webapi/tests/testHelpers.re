let unsafelyUnwrapOption =
  fun
  | Some(v) => v
  | None => raise(Invalid_argument("Passed `None` to unsafelyUnwrapOption"));

let window: Dom.window = failwith("window is not available on native");
let document: Dom.document = failwith("document is not available on native");
let history: Dom.history = failwith("history is not available on native");
let location: Dom.location = failwith("location is not available on native");
