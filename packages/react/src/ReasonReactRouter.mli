val push : string -> unit
(** update the url with the string path. Example: `push("/book/1")`, `push("/books#title")` *)

val replace : string -> unit
(** update the url with the string path. modifies the current history entry instead of creating a new one. Example:
    `replace("/book/1")`, `replace("/books#title")` *)

type watcherID

type url = {
  (* path takes window.location.path, like "/book/title/edit" and turns it into `["book", "title", "edit"]` *)
  path : string list;
  (* the url's hash, if any. The # symbol is stripped out for you *)
  hash : string;
  (* the url's query params, if any. The ? symbol is stripped out for you *)
  search : string;
}

val watchUrl : (url -> unit) -> watcherID
(** start watching for URL changes. Returns a subscription token. Upon url change, calls the callback and passes it the
    url record *)

val unwatchUrl : watcherID -> unit
(** stop watching for URL changes *)

val dangerouslyGetInitialUrl : ?serverUrlString:string -> unit -> url
(** this is marked as "dangerous" because you technically shouldn't be accessing the URL outside of watchUrl's callback
    you'd read a potentially stale url, instead of the fresh one inside watchUrl.

    But this helper is sometimes needed, if you'd like to initialize a page whose display/state depends on the URL,
    instead of reading from it in watchUrl's callback, which you'd probably have put inside didMount (aka too late, the
    page's already rendered).

    So, the correct (and idiomatic) usage of this helper is to only use it in a component that's also subscribed to
    watchUrl. Please see https://github.com/reasonml-community/reason-react-example/blob/master/src/todomvc/TodoItem.re
    for an example.

    On the server, [serverUrlString] is parsed like {!ServerUrl} parses its [url] prop. Without it, the function returns
    the URL that the closest enclosing {!ServerUrl} provides, or an empty URL when there is none. *)

val useUrl : ?serverUrl:url -> unit -> url
(** hook for watching url changes. * serverUrl is used for ssr. it allows you to specify the url without relying on
    browser apis existing/working as expected

    On the server, without [serverUrl], it returns the URL that the closest enclosing {!ServerUrl} provides, or an empty
    URL when there is none. *)

module ServerUrl : sig
  (** Server-only provider of the request URL for {!useUrl} and {!dangerouslyGetInitialUrl}.

      [url] is a request target such as ["/books/1/?sort=asc#top"]. It is split like the browser router splits
      [window.location]: [path] holds the non-empty segments between ['/'] (["books"; "1"]), [search] is the text after
      the first ['?'] without the ['?'] (["sort=asc"]), and [hash] is the text after the first ['#'] without the ['#']
      (["top"]). Segments are not percent-decoded. The closest enclosing provider wins.

      {[
        ReactDOM.renderToStream
          (ReasonReactRouter.ServerUrl.make
             (ReasonReactRouter.ServerUrl.makeProps ~url:request_target ~children:app ()))
      ]}

      With the JSX ppx: [<ReasonReactRouter.ServerUrl url=request_target> app </ReasonReactRouter.ServerUrl>]. *)

  val makeProps : url:string -> children:React.element -> unit -> < url : string ; children : React.element > Js.t
  val make : (< url : string ; children : React.element > Js.t, React.element) React.componentLike
end
