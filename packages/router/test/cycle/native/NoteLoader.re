let shouldFail = ref(false);
let fail = () => shouldFail := true;
let reset = () => shouldFail := false;

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
  Lwt.return(RouterRuntime.Loader.Data(id));
};
