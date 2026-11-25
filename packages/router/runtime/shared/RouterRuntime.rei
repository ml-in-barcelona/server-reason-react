/** Destinations, statuses, loader results, metadata and navigation types shared by the server and the browser.
    Generated [Router] re-exports the modules as [Router.Status], [Router.Loader], [Router.Error], [Router.Metadata],
    [Router.Headers] and [Router.Navigation]. Generated code also uses {!RouterEngine}, which is not a stable API. */

type destination = RouterTypes.destination;

/** How eagerly the client may prefetch a route, from least to most eager:
    [Off], [Intent], [Viewport], [Idle]. A route declares its level with
    [~prefetch]; the default is [Intent]. */
module PrefetchLevel: {
  type t = RouterTypes.PrefetchLevel.t = | Off | Intent | Viewport | Idle;

  /** The lower-case name, as sent in the [Router-Prefetch] header. */
  let toString: t => string;
  let fromString: string => option(t);

  /** Negative when [left] is less eager than [right]. */
  let compare: (t, t) => int;
};

let destination: (~path: string) => destination;
let href: destination => string;

/** [origin] followed by the href of [destination], for a link that leaves
    the page, such as in an email or a copied URL. [origin] is a scheme and
    host such as ["https://example.com"]; trailing slashes are dropped. A
    destination whose href does not start with [/], such as an absolute
    [unsafeDestination], is returned unchanged. */
let absoluteHref: (~origin: string, destination) => string;

/** Sets the fragment of [destination] to [hash], percent-encoded like a
    search value. An empty [hash] removes the fragment. Raises
    [Invalid_argument] for text [encodeURIComponent] cannot encode. */
let withHash: (destination, ~hash: string) => destination;

/** The prefetch level of the route [destination] points to. Generated
    destinations carry their route's level; other destinations are [Intent]. */
let prefetchLevel: destination => PrefetchLevel.t;

/** Sets the prefetch level. Generated destinations call it with the level of
    their route. */
let withPrefetch: (destination, PrefetchLevel.t) => destination;

module Status: {
  type t =
    RouterTypes.Status.t =
      | Ok
      | BadRequest
      | Unauthorized
      | Forbidden
      | NotFound
      | Gone
      | TooManyRequests
      | InternalServerError
      | ServiceUnavailable
      | TemporaryRedirect
      | PermanentRedirect;

  let toInt: t => int;
};

module Loader: {
  type result('data, 'error) =
    RouterTypes.Loader.result('data, 'error) =
      | Data('data)
      | Error('error)
      | NotFound
      | Redirect(destination)
      | PermanentRedirect(destination);
};

module Error: {
  type notFoundReason =
    RouterTypes.Error.notFoundReason =
      | NoMatchingRoute | LoaderNotFound | RenderNotFound;

  type t('applicationError) =
    RouterTypes.Error.t('applicationError) =
      | NotFound({reason: notFoundReason})
      | Application('applicationError)
      | InvalidPathParameter({name: string})
      | InvalidSearchParameter({name: string})
      | Internal({diagnosticId: string});
};

module Metadata: {
  type metaAttribute = RouterTypes.Metadata.metaAttribute = | Name | Property;

  type entry =
    RouterTypes.Metadata.entry =
      | Meta({
          key: string,
          attr: metaAttribute,
          name: string,
          content: string,
        })
      | Link({
          key: string,
          rel: string,
          href: string,
          attrs: list((string, string)),
        });

  let entryKey: entry => string;

  /** `<meta name=... content=...>`. The default key is `"meta:" ++ name`. */
  let meta: (~key: string=?, ~name: string, string) => entry;

  /** `<meta property=... content=...>`. The default key is `"property:" ++ property`. */
  let property: (~key: string=?, ~property: string, string) => entry;

  /** `<link rel=... href=... attrs>`. The default key is `"link:" ++ rel`. Pass an explicit key for a repeated rel
      such as several `alternate` links. `attrs` named `rel` or `href` are ignored when rendering. */
  let link:
    (
      ~key: string=?,
      ~rel: string,
      ~attrs: list((string, string))=?,
      string
    ) =>
    entry;

  type t =
    RouterTypes.Metadata.t = {
      title: option(string),
      description: option(string),
      entries: list(entry),
    };

  let make:
    (
      ~title: string=?,
      ~description: string=?,
      ~entries: list(entry)=?,
      unit
    ) =>
    t;
  let merge: (t, t) => t;
};

module Headers: {
  type t = RouterTypes.Headers.t;

  type error =
    RouterTypes.Headers.error =
      | ForbiddenHeader(string)
      | InvalidHeaderName(string)
      | InvalidHeaderValue(string);

  let make: list((string, string)) => result(t, error);
  let merge: (t, t) => t;
  let toList: t => list((string, string));
};

module Navigation: {
  [@deriving rsc]
  type location =
    RouterTypes.Navigation.location = {
      pathname: string,
      search: string,
      hash: string,
      key: string,
    };

  type historyAction =
    RouterTypes.Navigation.historyAction = | Push | Replace | Pop;

  [@deriving rsc]
  type matched =
    RouterTypes.Navigation.matched = {
      routeId: string,
      parameters: list((string, string)),
    };

  [@deriving rsc]
  type layout =
    RouterTypes.Navigation.layout = {
      id: string,
      instanceKey: string,
    };

  [@deriving rsc]
  type committed =
    RouterTypes.Navigation.committed = {
      location,
      matches: list(matched),
      layouts: list(layout),
      revision: string,
    };

  type failure =
    RouterTypes.Navigation.failure = {
      requestId: int,
      message: string,
    };

  type status =
    RouterTypes.Navigation.status =
      | Idle
      | Loading({
          requestId: int,
          fromRevision: string,
          to_: location,
          action: historyAction,
        })
      | Failed(failure);

  module Result: {
    type t =
      RouterTypes.Navigation.Result.t =
        | Committed(committed)
        | Redirected(string)
        | Canceled
        | Failed(string);
  };
};
