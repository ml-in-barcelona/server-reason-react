module Navigation = RouterRuntime.Navigation;

type content('payload) =
  | Replace('payload)
  | Graft({
      graftAt: string,
      payload: 'payload,
    });

type response('payload) = {
  baseRevision: string,
  canonicalUrl: string,
  targetRevision: string,
  matches: list(Navigation.matched),
  layouts: list(Navigation.layout),
  content: content('payload),
};

type render('payload) =
  | ReplacePayload('payload)
  | GraftPayload({
      serial: int,
      graftAt: string,
      targetLayouts: list(string),
      payload: 'payload,
    });

type prepared('payload) = {
  navigationState: Navigation.state,
  committed: Navigation.committed,
  key: string,
  url: string,
  render: render('payload),
  restore: (Navigation.historyAction, string, string),
};

type error =
  | InvalidGraft
  | Canceled;

let prepare =
    (
      ~action,
      ~requestId,
      ~validatedRequestId,
      ~currentState: Navigation.state,
      ~currentCommitted: Navigation.committed,
      ~targetHash,
      ~historyKey,
      ~locationFromUrl,
      response: response('payload),
    ) => {
  let rec sharedThrough =
          (
            graftAt,
            current: list(Navigation.layout),
            target: list(Navigation.layout),
          ) =>
    switch (current, target) {
    | ([current, ...currentLayouts], [target, ...targetLayouts])
        when
          String.equal(current.id, target.id)
          && String.equal(current.instanceKey, target.instanceKey) =>
      String.equal(target.instanceKey, graftAt)
      || sharedThrough(graftAt, currentLayouts, targetLayouts)
    | _ => false
    };
  let graftAllowed =
    switch (response.content) {
    | Replace(_) => true
    | Graft({ graftAt, _ }) =>
      sharedThrough(graftAt, currentCommitted.layouts, response.layouts)
    };
  if (!graftAllowed) {
    Error(InvalidGraft);
  } else {
    let key =
      switch (action) {
      | Navigation.Push => "navigation-" ++ string_of_int(requestId)
      | Navigation.Replace => currentCommitted.location.key
      | Navigation.Pop =>
        switch (historyKey) {
        | Some(key) => key
        | None => currentCommitted.location.key
        }
      };
    let canonicalLocation: Navigation.location =
      locationFromUrl(~key, response.canonicalUrl);
    let location: Navigation.location = {
      ...canonicalLocation,
      hash:
        String.equal(canonicalLocation.hash, "")
          ? targetHash : canonicalLocation.hash,
    };
    let url = location.pathname ++ location.search ++ location.hash;
    let committed =
      Navigation.{
        location,
        matches: response.matches,
        layouts: response.layouts,
        revision: response.targetRevision,
      };
    switch (
      Navigation.commit(
        currentState,
        ~requestId=validatedRequestId,
        ~baseRevision=response.baseRevision,
        ~next=committed,
      )
    ) {
    | Error(_) => Error(Canceled)
    | Ok(navigationState) =>
      let render =
        switch (response.content) {
        | Replace(payload) => ReplacePayload(payload)
        | Graft({ graftAt, payload }) =>
          GraftPayload({
            serial: requestId,
            graftAt,
            targetLayouts:
              List.map(
                (layout: Navigation.layout) => layout.instanceKey,
                response.layouts,
              ),
            payload,
          })
        };
      Ok({
        navigationState,
        committed,
        key,
        url,
        render,
        restore: (action, location.hash, key),
      });
    };
  };
};
