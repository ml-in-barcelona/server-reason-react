let hash _location = ""

(* TODO: Maybe this should be implemented? *)
let path ?serverUrlString:_ () = []

(* TODO: Maybe this should be implemented? *)
let search ?serverUrlString:_ () = ""
let push (_path : string) = ()
let replace (_path : string) = ()

type url = { path : string list; hash : string; search : string }
type watcherID = unit -> unit

let url ?serverUrlString () =
  {
    path = path ?serverUrlString ();
    hash = hash ();
    search = search ?serverUrlString ();
  }

let dangerouslyGetInitialUrl = url
let watchUrl _callback () = ()
let unwatchUrl _watcherID = ()
let useUrl ?serverUrl:_ () = url ()
