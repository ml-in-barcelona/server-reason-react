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
