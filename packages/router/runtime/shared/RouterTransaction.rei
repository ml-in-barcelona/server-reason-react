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
  matches: list(RouterRuntime.Navigation.matched),
  layouts: list(RouterRuntime.Navigation.layout),
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
  navigationState: RouterRuntime.Navigation.state,
  committed: RouterRuntime.Navigation.committed,
  key: string,
  url: string,
  render: render('payload),
  restore: (RouterRuntime.Navigation.historyAction, string, string),
};

type error =
  | InvalidGraft
  | Canceled;

let prepare:
  (
    ~action: RouterRuntime.Navigation.historyAction,
    ~requestId: int,
    ~validatedRequestId: int,
    ~currentState: RouterRuntime.Navigation.state,
    ~currentCommitted: RouterRuntime.Navigation.committed,
    ~targetHash: string,
    ~historyKey: option(string),
    ~locationFromUrl:
      (~key: string, string) => RouterRuntime.Navigation.location,
    response('payload)
  ) =>
  result(prepared('payload), error);
