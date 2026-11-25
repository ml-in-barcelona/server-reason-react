let events = ref([]);
let layoutEvents = ref([]);

let reset = () => {
  events := [];
  layoutEvents := [];
};
let record = event => events := [event, ...events^];
let events = () => List.rev(events^);

let recordLayout = event => layoutEvents := [event, ...layoutEvents^];
let layouts = () => layoutEvents^;

let headers = values =>
  switch (RouterRuntime.Headers.make(values)) {
  | Ok(headers) => headers
  | Error(_) => invalid_arg("invalid fixture headers")
  };

module RootLayoutView = {
  [@react.component]
  let make = (~search as _, ~children) => children;
};

module RootLayout = {
  let makeProps = RootLayoutView.makeProps;
  let make = props => {
    recordLayout("root-layout");
    RootLayoutView.make(props);
  };
};

module RootLoading = {
  [@react.component]
  let make = (~search as _) => React.string("loading");
};

module RootMetadata = {
  let make = (~search as _, ()) => {
    record("root-metadata");
    Lwt.return(RouterRuntime.Metadata.make(~title="Root", ()));
  };
};

module RootHeaders = {
  let make = (~search as _, ()) => {
    record("root-headers");
    Lwt.return(headers([("Vary", "Accept")]));
  };
};

module RootBoundaryView = {
  [@react.component]
  let make = (~search as _, ~error as _) => {
    React.string("root-error");
  };
};

module RootBoundary = {
  let makeProps = RootBoundaryView.makeProps;
  let make = props => {
    record("root-error");
    RootBoundaryView.make(props);
  };
};

module AppError = {
  let status = _ => RouterRuntime.Status.Forbidden;
  let makeProps = RootBoundary.makeProps;
  let make = RootBoundary.make;
};

module InvalidSearchView = {
  [@react.component]
  let make = (~error as _) => {
    React.string("invalid-search");
  };
};

module InvalidSearch = {
  let makeProps = InvalidSearchView.makeProps;
  let make = props => {
    record("invalid-search");
    InvalidSearchView.make(props);
  };
};

module RootNotFound = {
  [@react.component]
  let make = (~search as _, ~error as _) => {
    record("root-not-found");
    React.string("root-not-found");
  };
};

module WorkspaceLayoutView = {
  [@react.component]
  let make = (~workspaceId as _, ~search as _, ~workspace as _, ~children) => children;
};

module WorkspaceLayout = {
  let makeProps = WorkspaceLayoutView.makeProps;
  let make = props => {
    recordLayout("workspace-layout");
    WorkspaceLayoutView.make(props);
  };
};

module WorkspaceMetadata = {
  let make = (~workspaceId as _, ~search as _, ~workspace as _, ()) => {
    record("workspace-metadata");
    Lwt.return(RouterRuntime.Metadata.make(~description="Workspace", ()));
  };
};

module WorkspaceHeaders = {
  let make = (~workspaceId as _, ~search as _, ~workspace as _, ()) => {
    record("workspace-headers");
    Lwt.return(headers([("Cache-Control", "private")]));
  };
};

module WorkspaceBoundaryView = {
  [@react.component]
  let make = (~workspaceId as _, ~search as _, ~error as _) =>
    React.string("workspace-error");
};

module WorkspaceBoundary = {
  let makeProps = WorkspaceBoundaryView.makeProps;
  let make = props => {
    record("workspace-error");
    WorkspaceBoundaryView.make(props);
  };
};

module WorkspaceNotFound = {
  [@react.component]
  let make = (~workspaceId as _, ~search as _, ~error as _) => {
    record("workspace-not-found");
    React.string("workspace-not-found");
  };
};

module ActiveRouteProbe = {
  [@react.component]
  let make = () =>
    switch (Router.useRoute()) {
    | Some(Router.Workspaces) => React.string("workspaces")
    | Some(_)
    | None => React.string("unexpected")
    };
};

module SearchProbe = {
  [@react.component]
  let make = () => {
    switch (Router.SearchResults.useSearch()) {
    | (Some(search), _updateSearch) =>
      React.string(
        String.concat(
          "|",
          [
            Int.to_string(search.page),
            Option.value(search.searchText, ~default="-"),
            Option.value(search.filter, ~default="-"),
            NoteId.to_string(search.view),
          ],
        ),
      )
    | (None, _updateSearch) => React.string("missing view")
    };
  };
};

module NoteMetadata = {
  let make =
      (
        ~workspaceId as _,
        ~id as _,
        ~search as _,
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
        ~search as _,
        ~workspace as _,
        ~noteAccess as _,
        (),
      ) => {
    record("note-headers");
    Lwt.return(headers([("X-Route", "note")]));
  };
};

module TeamLayoutView = {
  [@react.component]
  let make = (~teamId as _, ~search as _, ~children) => children;
};

module TeamLayout = {
  let makeProps = TeamLayoutView.makeProps;
  let make = props => {
    recordLayout("team-layout");
    TeamLayoutView.make(props);
  };
};

module TeamBoundaryView = {
  [@react.component]
  let make = (~teamId as _, ~search as _, ~error as _) =>
    React.string("team-error");
};

module TeamBoundary = {
  let makeProps = TeamBoundaryView.makeProps;
  let make = props => {
    record("team-error");
    TeamBoundaryView.make(props);
  };
};

module TeamNotFound = {
  [@react.component]
  let make = (~teamId as _, ~search as _, ~error as _) => {
    record("team-not-found");
    React.string("team-not-found");
  };
};
