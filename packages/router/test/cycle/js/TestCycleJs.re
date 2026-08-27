let () =
  if (Client.noteHref
      != "/fixture/workspaces/7/notes/42?filter=active%2F%C3%BC") {
    failwith("generated Melange href did not use the typed parameter");
  };
if (Client.quoteHref != "/fixture/workspaces/7/notes/42?filter=it's") {
  failwith("generated Melange href did not match encodeURIComponent");
};
if (Client.assetHref != "/fixture/assets/img/caf%C3%A9/a%2Bb") {
  failwith("generated Melange catch-all href did not encode segments");
};
if (Client.scalarHref("caf" ++ Js.String.fromCharCode(233) ++ "+@")
    != "/fixture/scalar/caf%C3%A9%2B%40") {
  failwith("generated Melange custom scalar href did not encode the value");
};
try(
  {
    ignore(Client.scalarHref("a/b"));
    failwith("generated Melange custom scalar href accepted a slash");
  }
) {
| Invalid_argument(_) => ()
};
let unicodeHref =
  RouterRuntime.destinationFromPattern(
    ~pattern=RouterRuntime.pattern("/café/東京"),
    ~parameters=[],
    ~search=[],
  )
  |> RouterRuntime.href;
if (unicodeHref != "/caf%C3%A9/%E6%9D%B1%E4%BA%AC") {
  failwith("Melange static paths did not use UTF-8 encoding");
};
let scalarPattern = RouterRuntime.pattern("/notes/:id<string>");
let scalarHref = value =>
  RouterRuntime.destinationFromPattern(
    ~pattern=scalarPattern,
    ~parameters=[("id", value)],
    ~search=[],
  )
  |> RouterRuntime.href;
if (scalarHref("!$&'()*+,:;=@_~-")
    != "/notes/!%24%26'()*%2B%2C%3A%3B%3D%40_~-") {
  failwith("Melange scalar paths did not encode URI punctuation");
};
let rejectedScalar = value =>
  try(
    {
      ignore(scalarHref(value));
      false;
    }
  ) {
  | _ => true
  };
[
  "",
  ".",
  "..",
  "a/b",
  Js.String.fromCharCode(0),
  Js.String.fromCharCode(31),
  Js.String.fromCharCode(127),
  Js.String.fromCharCode(0xD800),
]
|> List.iter(value =>
     if (!rejectedScalar(value)) {
       failwith("Melange scalar destination accepted an invalid segment");
     }
   );

let location =
  RouterRuntime.Navigation.{
    pathname: "/from",
    search: "",
    hash: "",
    key: "initial",
  };
let committed =
  RouterRuntime.Navigation.{
    location,
    matches: [],
    layouts: [
      {
        id: "root",
        instanceKey: "root",
      },
    ],
    revision: "r1",
  };
let (loading, requestId) =
  RouterRuntime.Navigation.start(
    RouterRuntime.Navigation.make(committed),
    ~to_={
      ...location,
      pathname: "/to",
    },
    ~action=RouterRuntime.Navigation.Push,
  );
let response =
  RouterTransaction.{
    baseRevision: "r1",
    canonicalUrl: "/to",
    targetRevision: "r2",
    matches: [],
    layouts: [
      {
        id: "root",
        instanceKey: "root",
      },
    ],
    content: Replace(React.string("next")),
  };
switch (
  RouterTransaction.prepare(
    ~action=RouterRuntime.Navigation.Push,
    ~requestId,
    ~validatedRequestId=requestId,
    ~currentState=loading,
    ~currentCommitted=committed,
    ~targetHash="",
    ~historyKey=None,
    ~locationFromUrl=
      (~key, _url) =>
        {
          ...location,
          pathname: "/to",
          key,
        },
    response,
  )
) {
| Ok(prepared) =>
  if (prepared.committed.revision != "r2"
      || prepared.key != "navigation-"
      ++ string_of_int(requestId)) {
    failwith("router transaction did not commit the normalized response");
  }
| Error(_) =>
  failwith("router transaction unexpectedly rejected a full response")
};

let (patchLoading, patchRequestId) =
  RouterRuntime.Navigation.start(
    RouterRuntime.Navigation.make(committed),
    ~to_={
      ...location,
      pathname: "/to",
    },
    ~action=RouterRuntime.Navigation.Replace,
  );
let patch =
  RouterTransaction.{
    ...response,
    content:
      Graft({
        graftAt: "root",
        payload: React.string("patch"),
      }),
  };
switch (
  RouterTransaction.prepare(
    ~action=RouterRuntime.Navigation.Replace,
    ~requestId=patchRequestId,
    ~validatedRequestId=patchRequestId,
    ~currentState=patchLoading,
    ~currentCommitted=committed,
    ~targetHash="",
    ~historyKey=None,
    ~locationFromUrl=
      (~key, _url) =>
        {
          ...location,
          pathname: "/to",
          key,
        },
    patch,
  )
) {
| Ok({ render: RouterTransaction.GraftPayload({ graftAt: "root", _ }), _ }) =>
  ()
| Ok(_) => failwith("router transaction did not preserve the patch operation")
| Error(_) =>
  failwith("router transaction unexpectedly rejected a valid patch")
};

let invalidPatch =
  RouterTransaction.{
    ...patch,
    content:
      Graft({
        graftAt: "missing",
        payload: React.string("patch"),
      }),
  };
switch (
  RouterTransaction.prepare(
    ~action=RouterRuntime.Navigation.Replace,
    ~requestId=patchRequestId,
    ~validatedRequestId=patchRequestId,
    ~currentState=patchLoading,
    ~currentCommitted=committed,
    ~targetHash="",
    ~historyKey=None,
    ~locationFromUrl=
      (~key, _url) =>
        {
          ...location,
          pathname: "/to",
          key,
        },
    invalidPatch,
  )
) {
| Error(RouterTransaction.InvalidGraft) => ()
| Ok(_)
| Error(_) => failwith("router transaction accepted an invalid patch graft")
};
