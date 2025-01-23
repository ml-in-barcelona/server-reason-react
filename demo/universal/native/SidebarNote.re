module List = {
  include List;
  let rec take = (lst, n) =>
    switch (lst, n) {
    | ([], _) => []
    | (_, 0) => []
    | ([x, ...xs], n) => [x, ...take(xs, n - 1)]
    };
};

module Date = {
  let is_today = date => {
    let now = Unix.localtime(Unix.time());
    let d = Unix.localtime(date);
    now.tm_year == d.tm_year
    && now.tm_mon == d.tm_mon
    && now.tm_mday == d.tm_mday;
  };

  let format_time = date => {
    let t = Unix.localtime(date);
    let hour = t.tm_hour mod 12;
    let hour =
      if (hour == 0) {
        12;
      } else {
        hour;
      };
    let ampm =
      if (t.tm_hour >= 12) {
        "pm";
      } else {
        "am";
      };
    Printf.sprintf("%d:%02d %s", hour, t.tm_min, ampm);
  };

  let format_date = date => {
    let t = Unix.localtime(date);
    Printf.sprintf("%d/%d/%02d", t.tm_mon + 1, t.tm_mday, t.tm_year mod 100);
  };
};

module Markdown = {
  let extract_text = markdown => {
    // Simple markdown text extraction - strips basic markdown syntax
    let without_links =
      Str.global_replace(
        Str.regexp("\\[([^]]*)\\]\\([^)]*\\)"),
        "\\1",
        markdown,
      );
    let without_bold =
      Str.global_replace(
        Str.regexp("\\*\\*\\([^*]*\\)\\*\\*"),
        "\\1",
        without_links,
      );
    let without_italic =
      Str.global_replace(
        Str.regexp("\\*\\([^*]*\\)\\*"),
        "\\1",
        without_bold,
      );
    Str.global_replace(Str.regexp("#+ \\|`\\|>"), "", without_italic);
  };

  let summarize = (text, ~words as n) => {
    let words = Str.split(Str.regexp("[ \n\r\t]+"), text);
    let truncated = List.take(words, n);
    String.concat(" ", truncated)
    ++ (
      if (List.length(words) > n) {
        "...";
      } else {
        "";
      }
    );
  };
};

[@react.component]
let make = (~note: Note.t) => {
  let lastUpdatedAt =
    if (Date.is_today(note.updated_at)) {
      Date.format_time(note.updated_at);
    } else {
      Date.format_date(note.updated_at);
    };

  let summary =
    note.content |> Markdown.extract_text |> Markdown.summarize(~words=20);

  <SidebarNoteContent
    id={note.id}
    title={note.title}
    expandedChildren={
      <p className="sidebar-note-excerpt">
        {switch (String.trim(summary)) {
         | "" => <i> {React.string("(No content)")} </i>
         | s => React.string(s)
         }}
      </p>
    }>
    <header className="sidebar-note-header">
      <strong> {React.string(note.title)} </strong>
      <small> {React.string(lastUpdatedAt)} </small>
    </header>
  </SidebarNoteContent>;
};
