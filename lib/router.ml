(* Adapted from reason-react: https://reasonml.github.io/reason-react/docs/en/router *)

module Browser =
[%js:
type history
type window

val window_to_js : window -> Ojs.t

type location

val history : history option [@@js.global "history"]
val window : window option [@@js.global "window"]
val location : window -> location [@@js.get]
val pathname : location -> string [@@js.get]
val hash : location -> string [@@js.get]
val search : location -> string [@@js.get]

val push_state : history -> Ojs.t -> string -> href:string -> unit
  [@@js.call "pushState"]

val replace_state : history -> Ojs.t -> string -> href:string -> unit
  [@@js.call "replaceState"]]

module Event =
[%js:
type t

val event : t [@@js.global "Event"]
val make_event_ie11_compatible : string -> t [@@js.new "Event"]
val create_event_non_ie8 : string -> t [@@js.global "document.createEvent"]

val init_event_non_ie8 : t -> string -> bool -> bool -> unit
  [@@js.call "initEvent"]

(* The cb is t => unit, but access is restricted for now *)
val add_event_listener : Browser.window -> string -> (unit -> unit) -> unit
  [@@js.call "addEventListener"]

val remove_event_listener : Browser.window -> string -> (unit -> unit) -> unit
  [@@js.call "removeEventListener"]

val dispatch_event : Browser.window -> t -> unit [@@js.call "dispatchEvent"]]

let safe_make_event eventName =
  if
    let open Js_of_ocaml in
    Js.typeof (Js.Unsafe.inject Event.event) = Js.string "function"
  then Event.make_event_ie11_compatible eventName
  else
    let event = Event.create_event_non_ie8 "Event" in
    Event.init_event_non_ie8 event eventName true true;
    Event.event

let slice_to_end s =
  match s = "" with true -> "" | false -> String.sub s 1 (String.length s - 1)

(* if we ever roll our own parser in the future, make sure you test all url combinations
   e.g. foo.com/?#bar
*)
(* URLSearchParams doesn't work on IE11, edge16, etc. *)
(* The library doesn't provide search for now. Users can roll their own solution/data structure.*)
let path () =
  match Browser.window with
  | None -> []
  | Some w -> (
      match
        let open Browser in
        w |> location |> pathname
      with
      | "" | "/" -> []
      | raw ->
          let raw = slice_to_end raw in
          let raw =
            let n = String.length raw in
            match n > 0 && raw.[n - 1] = '/' with
            | true -> String.sub raw 0 (n - 1)
            | false -> raw
          in
          raw |> String.split_on_char '/')

let hash () =
  match Browser.window with
  | None -> ""
  | Some w -> (
      match
        let open Browser in
        w |> location |> hash
      with
      | "" | "#" -> ""
      | raw ->
          (* remove the preceeding #, which every hash seems to have. *)
          slice_to_end raw)

let search () =
  match Browser.window with
  | None -> ""
  | Some w -> (
      match
        let open Browser in
        w |> location |> search
      with
      | "" | "?" -> ""
      | raw ->
          (* remove the preceeding ?, which every search seems to have. *)
          slice_to_end raw)

let push path =
  match
    let open Browser in
    (history, window)
  with
  | None, _ | _, None -> ()
  | Some history, Some window ->
      Browser.push_state history Ojs.null "" ~href:path;
      Event.dispatch_event window (safe_make_event "popstate")

let replace path =
  match
    let open Browser in
    (history, window)
  with
  | None, _ | _, None -> ()
  | Some history, Some window ->
      Browser.replace_state history Ojs.null "" ~href:path;
      Event.dispatch_event window (safe_make_event "popstate")

type url =
  { path : string list
  ; hash : string
  ; search : string
  }

let url_not_equal a b =
  let rec list_not_equal xs ys =
    match (xs, ys) with
    | [], [] -> false
    | [], _ :: _ | _ :: _, [] -> true
    | x :: xs, y :: ys -> if x != y then true else list_not_equal xs ys
  in
  a.hash != b.hash || a.search != b.search || list_not_equal a.path b.path

type watcher_id = unit -> unit

let url () = { path = path (); hash = hash (); search = search () }

(* alias exposed publicly *)
let dangerously_get_initial_url = url

let watch_url callback =
  match Browser.window with
  | None -> fun () -> ()
  | Some window ->
      let watcher_id () = callback (url ()) in
      Event.add_event_listener window "popstate" watcher_id;
      watcher_id

let unwatch_url watcher_id =
  match Browser.window with
  | None -> ()
  | Some window -> Event.remove_event_listener window "popstate" watcher_id

let use_url ?server_url () =
  let url, set_url =
    Core.use_state (fun () ->
        match server_url with
        | Some url -> url
        | None -> dangerously_get_initial_url ())
  in
  Core.use_effect_once (fun () ->
      let watcher_id = watch_url (fun url -> set_url (fun _ -> url)) in
      (* check for updates that may have occured between the initial state and the subscribe above *)
      let new_url = dangerously_get_initial_url () in
      if url_not_equal new_url url then set_url (fun _ -> new_url);
      Some (fun () -> unwatch_url watcher_id));
  url
