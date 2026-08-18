let events = ref([]);

let reset = () => events := [];
let record = event => events := [event, ...events^];
let events = () => List.rev(events^);

let headers = values =>
  switch (RouterRuntime.Headers.make(values)) {
  | Ok(headers) => headers
  | Error(_) => invalid_arg("invalid fixture headers")
  };

module RootLayout = {
  [@react.component]
  let make = (~page as _, ~searchText as _, ~children) => {
    record("root-layout");
    children;
  };
};

module RootLoading = {
  [@react.component]
  let make = (~page as _, ~searchText as _) => React.string("loading");
};

module RootMetadata = {
  let make = (~page as _, ~searchText as _, ()) => {
    record("root-metadata");
    Lwt.return(RouterRuntime.Metadata.make(~title="Root", ()));
  };
};

module RootHeaders = {
  let make = (~page as _, ~searchText as _, ()) => {
    record("root-headers");
    Lwt.return(headers([("Vary", "Accept")]));
  };
};

module RootBoundary = {
  [@react.component]
  let make = (~page as _, ~searchText as _, ~error as _) => {
    record("root-error");
    React.string("root-error");
  };
};

module AppError = {
  let status = _ => RouterRuntime.Status.Forbidden;
  let makeProps = RootBoundary.makeProps;
  let make = RootBoundary.make;
};

module InvalidSearch = {
  [@react.component]
  let make = (~error as _) => {
    record("invalid-search");
    React.string("invalid-search");
  };
};

module RootNotFound = {
  [@react.component]
  let make = (~page as _, ~searchText as _, ~error as _) => {
    record("root-not-found");
    React.string("root-not-found");
  };
};

module WorkspaceLayout = {
  [@react.component]
  let make =
      (
        ~workspaceId as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~workspace as _,
        ~children,
      ) => {
    record("workspace-layout");
    children;
  };
};

module WorkspaceMetadata = {
  let make =
      (
        ~workspaceId as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~workspace as _,
        (),
      ) => {
    record("workspace-metadata");
    Lwt.return(RouterRuntime.Metadata.make(~description="Workspace", ()));
  };
};

module WorkspaceHeaders = {
  let make =
      (
        ~workspaceId as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~workspace as _,
        (),
      ) => {
    record("workspace-headers");
    Lwt.return(headers([("Cache-Control", "private")]));
  };
};

module WorkspaceBoundary = {
  [@react.component]
  let make =
      (
        ~workspaceId as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~error as _,
      ) => {
    record("workspace-error");
    React.string("workspace-error");
  };
};

module WorkspaceNotFound = {
  [@react.component]
  let make =
      (
        ~workspaceId as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~error as _,
      ) => {
    record("workspace-not-found");
    React.string("workspace-not-found");
  };
};

module NoteMetadata = {
  let make =
      (
        ~workspaceId as _,
        ~id as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~workspace as _,
        ~noteAccess as _,
        (),
      ) => {
    record("note-metadata");
    Lwt.return(RouterRuntime.Metadata.make(~title="Note", ()));
  };
};

module NoteHeaders = {
  let make =
      (
        ~workspaceId as _,
        ~id as _,
        ~page as _,
        ~searchText as _,
        ~filter as _,
        ~workspace as _,
        ~noteAccess as _,
        (),
      ) => {
    record("note-headers");
    Lwt.return(headers([("X-Route", "note")]));
  };
};
