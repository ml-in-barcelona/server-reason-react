let events = ref([]);
let shouldNotFound = ref(false);
let shouldRedirect = ref(false);
let shouldError = ref(false);

let reset = () => {
  events := [];
  shouldNotFound := false;
  shouldRedirect := false;
  shouldError := false;
};
let notFound = () => shouldNotFound := true;
let redirect = () => shouldRedirect := true;
let error = () => shouldError := true;
let record = event => events := [event, ...events^];
let events = () => List.rev(events^);

let load =
    (~workspaceId, ~page, ~searchText as _, ~filter as _, ())
    : Lwt.t(RouterRuntime.Loader.result(string, string)) => {
  record("workspace");
  if (shouldError^) {
    Lwt.return(RouterRuntime.Loader.Error("denied"));
  } else if (shouldRedirect^) {
    Lwt.return(
      RouterRuntime.Loader.Redirect(
        RouterRuntime.destination(~path="/login"),
      ),
    );
  } else if (shouldNotFound^) {
    Lwt.return(RouterRuntime.Loader.NotFound);
  } else {
    Lwt.return(
      RouterRuntime.Loader.Data(
        WorkspaceId.to_string(workspaceId) ++ ":" ++ Int.to_string(page),
      ),
    );
  };
};
