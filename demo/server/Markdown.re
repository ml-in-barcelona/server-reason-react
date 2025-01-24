module List = {
  include List;
  let rec [@tailcall] take =
    (lst, n) =>
      switch (lst, n) {
      | ([], _) => []
      | (_, 0) => []
      | ([x, ...xs], n) => [x, ...take(xs, n - 1)]
      };
};

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
    Str.global_replace(Str.regexp("\\*\\([^*]*\\)\\*"), "\\1", without_bold);
  Str.global_replace(Str.regexp("#+ \\|`\\|>"), "", without_italic);
};

let summarize = (text, ~words as n) => {
  let words = Str.split(Str.regexp("[ \n\r\t]+"), text);
  let truncated = List.take(words, n);
  let dots =
    if (List.length(words) > n) {
      "...";
    } else {
      "";
    };
  String.concat(" ", truncated) ++ dots;
};
