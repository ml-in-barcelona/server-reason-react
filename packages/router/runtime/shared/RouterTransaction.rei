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
  matches: list(RouterTypes.Navigation.matched),
  layouts: list(RouterTypes.Navigation.layout),
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
  navigationState: RouterTypes.Navigation.state,
  committed: RouterTypes.Navigation.committed,
  key: string,
  url: string,
  render: render('payload),
  restore: (RouterTypes.Navigation.historyAction, string, string),
};

type error =
  | InvalidGraft
  | Canceled;

let prepare:
  (
    ~action: RouterTypes.Navigation.historyAction,
    ~requestId: int,
    ~validatedRequestId: int,
    ~currentState: RouterTypes.Navigation.state,
    ~currentCommitted: RouterTypes.Navigation.committed,
    ~targetHash: string,
    ~historyKey: option(string),
    ~locationFromUrl:
      (~key: string, string) => RouterTypes.Navigation.location,
    response('payload)
  ) =>
  result(prepared('payload), error);
