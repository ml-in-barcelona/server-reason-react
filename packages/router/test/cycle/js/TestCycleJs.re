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
