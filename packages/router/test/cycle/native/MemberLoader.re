let shouldNotFound = ref(false);

let reset = () => shouldNotFound := false;
let notFound = () => shouldNotFound := true;

let load =
    (~teamId, ~page as _, ~searchText as _, ())
    : Lwt.t(RouterRuntime.Loader.result(string, string)) =>
  if (shouldNotFound^) {
    Lwt.return(RouterRuntime.Loader.NotFound);
  } else {
    Lwt.return(
      RouterRuntime.Loader.Data("member@" ++ WorkspaceId.to_string(teamId)),
    );
  };
