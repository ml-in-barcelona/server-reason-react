(* Adapted from reason-react: https://reasonml.github.io/reason-react/docs/en/router *)

val push : string -> unit
(** update the url with the string path. Example: `push("/book/1")`, `push("/books#title")` *)

val replace : string -> unit
(** update the url with the string path. modifies the current history entry instead of creating a new one. Example: `replace("/book/1")`, `replace("/books#title")` *)

type watcher_id

type url =
  { (* path takes window.location.path, like "/book/title/edit" and turns it into `["book", "title", "edit"]` *)
    path : string list
  ; (* the url's hash, if any. The # symbol is stripped out for you *)
    hash : string
  ; (* the url's query params, if any. The ? symbol is stripped out for you *)
    search : string
  }

val watch_url : (url -> unit) -> watcher_id
(** start watching for URL changes. Returns a subscription token. Upon url change, calls the callback and passes it the url record *)

val unwatch_url : watcher_id -> unit
(** stop watching for URL changes *)

val dangerously_get_initial_url : unit -> url
(** this is marked as "dangerous" because you technically shouldn't be accessing the URL outside of watchUrl's callback;
      you'd read a potentially stale url, instead of the fresh one inside watchUrl.
      But this helper is sometimes needed, if you'd like to initialize a page whose display/state depends on the URL,
      instead of reading from it in watchUrl's callback, which you'd probably have put inside didMount (aka too late,
      the page's already rendered).
      So, the correct (and idiomatic) usage of this helper is to only use it in a component that's also subscribed to
      watchUrl. Please see https://github.com/reasonml-community/reason-react-example/blob/master/src/todomvc/TodoItem.re
      for an example.
      *)

val use_url : ?server_url:url -> unit -> url
(** hook for watching url changes.
 * serverUrl is used for ssr. it allows you to specify the url without relying on browser apis existing/working as expected
 *)
