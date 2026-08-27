let shouldFail = ref(false);
let shouldNotFound = ref(false);
let fail = () => shouldFail := true;
let notFound = () => shouldNotFound := true;
let reset = () => {
  shouldFail := false;
  shouldNotFound := false;
};

let load =
    (
      ~workspaceId as _,
      ~id,
      ~page as _,
      ~searchText as _,
      ~filter as _,
      ~workspace,
      (),
    )
    : Lwt.t(RouterRuntime.Loader.result(int, string)) => {
  if (shouldFail^) {
    raise(Failure("private loader failure"));
  };
  WorkspaceLoader.record("note:" ++ workspace);
  if (shouldNotFound^) {
    Lwt.return(RouterRuntime.Loader.NotFound);
  } else {
    Lwt.return(RouterRuntime.Loader.Data(id));
  };
};
