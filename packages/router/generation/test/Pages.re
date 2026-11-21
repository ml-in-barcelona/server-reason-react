module AppError = {
  let status = (_: string) => RouterRuntime.Status.InternalServerError;
  [@react.component]
  let make = (~error: RouterRuntime.Error.t(string)) => {
    ignore(error);
    React.null;
  };
};

module Docs = {
  [@react.component]
  let make = (~rest: list(string)) =>
    React.string("docs:" ++ String.concat("|", rest));
};

module DocsTopic = {
  [@react.component]
  let make = (~topic: string) => React.string("topic:" ++ topic);
};

module DocsApi = {
  [@react.component]
  let make = (~name: string) => React.string("api:" ++ name);
};

module AccountLoader = {
  let load = (~context: string, ()) =>
    Lwt.return(RouterRuntime.Loader.Data("viewer:" ++ context));
};

module AccountMetadata = {
  let make = (~context: string, ~accountLoader as _, ()) =>
    Lwt.return(
      RouterRuntime.Metadata.make(~title="account:" ++ context, ()),
    );
};

module AccountHeaders = {
  let make = (~context: string, ~accountLoader as _, ()) =>
    switch (RouterRuntime.Headers.make([("X-Viewer", context)])) {
    | Ok(headers) => Lwt.return(headers)
    | Error(_) => assert(false)
    };
};

module Account = {
  [@react.component]
  let make = (~accountLoader: string) => React.string(accountLoader);
};

let language = lang => Option.value(lang, ~default="-");

module Help = {
  [@react.component]
  let make = (~lang: option(string)) =>
    React.string("help:" ++ language(lang));
};

module HelpTopic = {
  [@react.component]
  let make = (~lang: option(string), ~topic: int) =>
    React.string(
      "help-topic:" ++ language(lang) ++ ":" ++ string_of_int(topic),
    );
};

module Note = {
  [@react.component]
  let make = (~id: int, ~search: Router.Note.search) =>
    React.string(
      "note:" ++ string_of_int(id) ++ ":" ++ language(search.tab),
    );
};

module Inspector = {
  [@react.component]
  let make = (~search: Router.Inspector.search) =>
    React.string(
      String.concat(
        "|",
        [
          search.target,
          language(search.error),
          search.input,
          String.concat(",", search.hash),
          language(Option.map(string_of_int, search.value)),
          language(search.pattern),
        ],
      ),
    );
};

module Support = {
  [@react.component]
  let make = (~search: Router.Support.search) =>
    React.string(
      String.concat(
        "|",
        [
          language(search.infoPage),
          string_of_int(search.resourcesProjectId),
          language(search.alpha),
          String.concat(",", search.zone),
        ],
      ),
    );
};

module Settings = {
  [@react.component]
  let make = () => React.string("Settings");
};

module SettingsBilling = {
  [@react.component]
  let make = () => React.string("SettingsBilling");
};

module SettingsTeam = {
  [@react.component]
  let make = () => React.string("SettingsTeam");
};

module SettingsMembers = {
  [@react.component]
  let make = () => React.string("SettingsMembers");
};

module SettingsError = {
  [@react.component]
  let make = (~error: RouterRuntime.Error.t(string)) => {
    ignore(error);
    React.string("settings-error");
  };
};

module ReportGates = {
  type gate = Lwt.u(RouterRuntime.Loader.result(string, string));
  let events: ref(list(string)) = ref([]);
  let report: ref(option(gate)) = ref(None);
  let stats: ref(option(gate)) = ref(None);
  let reset = () => {
    events := [];
    report := None;
    stats := None;
  };
  let wait = (name, gate) => {
    events := events^ @ [name ++ ":start"];
    let (promise, resolver) = Lwt.wait();
    gate := Some(resolver);
    Lwt.map(
      result => {
        events := events^ @ [name ++ ":done"];
        result;
      },
      promise,
    );
  };
  let resolve = (gate, result) =>
    switch (gate^) {
    | Some(resolver) => Lwt.wakeup_later(resolver, result)
    | None => failwith("loader has not started")
    };
};

module ReportLoader = {
  let load = (~context as _: string, ~reportId as _: string, ()) =>
    ReportGates.wait("report", ReportGates.report);
};

module ReportStatsLoader = {
  let load = (~context as _: string, ~reportId as _: string, ()) =>
    ReportGates.wait("stats", ReportGates.stats);
};

module Report = {
  [@react.component]
  let make =
      (~reportId: string, ~reportLoader: string, ~reportStatsLoader: string) =>
    React.string(reportId ++ ":" ++ reportLoader ++ ":" ++ reportStatsLoader);
};

module ReportError = {
  [@react.component]
  let make = (~reportId as _: string, ~error: RouterRuntime.Error.t(string)) =>
    switch (error) {
    | RouterRuntime.Error.Application(error) =>
      React.string("report-error:" ++ error)
    | _ => React.string("report-error")
    };
};
