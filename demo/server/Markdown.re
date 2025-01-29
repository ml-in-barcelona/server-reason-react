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

let convert_headings = text => {
  text
  |> Str.global_replace(Str.regexp("^#### \\(.*\\)$"), "<h4>\\1</h4>")
  |> Str.global_replace(Str.regexp("^### \\(.*\\)$"), "<h3>\\1</h3>")
  |> Str.global_replace(Str.regexp("^## \\(.*\\)$"), "<h2>\\1</h2>")
  |> Str.global_replace(Str.regexp("^# \\(.*\\)$"), "<h1>\\1</h1>");
};

let convert_emphasis = text => {
  text
  |> Str.global_replace(
       Str.regexp("\\*\\*\\([^*]*\\)\\*\\*"),
       "<strong>\\1</strong>",
     )
  |> Str.global_replace(
       Str.regexp("__\\([^_]*\\)__"),
       "<strong>\\1</strong>",
     )
  |> Str.global_replace(Str.regexp("\\*\\([^*]*\\)\\*"), "<em>\\1</em>")
  |> Str.global_replace(Str.regexp("_\\([^_]*\\)_"), "<em>\\1</em>");
};

let convert_code = text => {
  text
  |> Str.global_replace(
       Str.regexp("```\\([^`]*\\)```"),
       "<pre><code>\\1</code></pre>",
     )
  |> Str.global_replace(Str.regexp("`\\([^`]*\\)`"), "<code>\\1</code>");
};

let convert_links = text => {
  text
  |> Str.global_replace(
       Str.regexp("\\[\\([^]]*\\)\\](\\([^)]*\\))"),
       "<a href=\"\\2\">\\1</a>",
     );
};

let convert_lists = text => {
  let lines = String.split_on_char('\n', text);

  let process_line = line => {
    switch (line) {
    | line when Str.string_match(Str.regexp("^-\\s*\\(.*\\)$"), line, 0) =>
      "<li>" ++ Str.matched_group(1, line) ++ "</li>"
    | line when Str.string_match(Str.regexp("^\\+\\s*\\(.*\\)$"), line, 0) =>
      "<li>" ++ Str.matched_group(1, line) ++ "</li>"
    | line when Str.string_match(Str.regexp("^\\*\\s*\\(.*\\)$"), line, 0) =>
      "<li>" ++ Str.matched_group(1, line) ++ "</li>"
    | line
        when Str.string_match(Str.regexp("^\\d+\\.\\s*\\(.*\\)$"), line, 0) =>
      "<li>" ++ Str.matched_group(1, line) ++ "</li>"
    | _ => line
    };
  };

  let wrap_consecutive_items = lines => {
    let rec aux = (acc, current_list, lines) => {
      switch (current_list, lines) {
      | ([], []) => List.rev(acc)
      | ([hd, ...tl], []) =>
        List.rev([
          "<ul>" ++ String.concat("\n", List.rev([hd, ...tl])) ++ "</ul>",
          ...acc,
        ])
      | ([], [line, ...rest]) =>
        if (Str.string_match(Str.regexp("^<li>"), line, 0)) {
          aux(acc, [line], rest);
        } else {
          aux([line, ...acc], [], rest);
        }
      | ([hd, ...tl] as items, [line, ...rest]) =>
        if (Str.string_match(Str.regexp("^<li>"), line, 0)) {
          aux(acc, [line, ...current_list], rest);
        } else {
          aux(
            [
              line,
              "<ul>" ++ String.concat("\n", List.rev(items)) ++ "</ul>",
              ...acc,
            ],
            [],
            rest,
          );
        }
      };
    };
    aux([], [], lines);
  };

  lines
  |> List.map(process_line)
  |> wrap_consecutive_items
  |> String.concat("\n");
};

let wrap_lists = text => {
  text
  |> Str.global_replace(
       Str.regexp("<li>.*</li>\\(\n<li>.*</li>\\)*"),
       "<ul>\\0</ul>",
     );
};

let convert_blockquotes = text => {
  let lines = String.split_on_char('\n', text);

  let rec process_lines = (acc, in_quote, lines) => {
    switch (lines) {
    | [] when in_quote => List.rev(["</blockquote>", ...acc])
    | [] => List.rev(acc)
    | [line, ...rest] =>
      let trimmed = String.trim(line);
      if (Str.string_match(Str.regexp("^>\\s*\\(.*\\)$"), trimmed, 0)) {
        let content = Str.matched_group(1, trimmed);
        if (in_quote) {
          process_lines([content, ...acc], true, rest);
        } else {
          process_lines([content, "<blockquote>", ...acc], true, rest);
        };
      } else if (trimmed == "") {
        if (in_quote) {
          process_lines(["</blockquote>", ...acc], false, rest);
        } else {
          process_lines([line, ...acc], false, rest);
        };
      } else if (in_quote) {
        process_lines([line, ...acc], true, rest);
      } else {
        process_lines([line, ...acc], false, rest);
      };
    };
  };

  lines |> process_lines([], false) |> String.concat("\n");
};

let convert_paragraphs = text => {
  let lines = String.split_on_char('\n', text);

  let is_block_element = line =>
    Str.string_match(
      Str.regexp("^<\\(h[1-6]\\|ul\\|ol\\|blockquote\\|pre\\)>"),
      line,
      0,
    );

  let wrap_paragraphs = lines => {
    let rec aux = (acc, current_p, lines) => {
      switch (lines) {
      | [] when current_p != "" =>
        List.rev(["<p>" ++ current_p ++ "</p>", ...acc])
      | [] => List.rev(acc)
      | [line, ...rest] when is_block_element(line) =>
        if (current_p != "") {
          aux([line, "<p>" ++ current_p ++ "</p>", ...acc], "", rest);
        } else {
          aux([line, ...acc], "", rest);
        }
      | [line, ...rest] when String.trim(line) == "" =>
        if (current_p != "") {
          aux(["<p>" ++ current_p ++ "</p>", ...acc], "", rest);
        } else {
          aux(acc, "", rest);
        }
      | [line, ...rest] =>
        let sep =
          if (current_p == "") {
            "";
          } else {
            " ";
          };
        aux(acc, current_p ++ sep ++ String.trim(line), rest);
      };
    };
    aux([], "", lines);
  };

  lines |> wrap_paragraphs |> String.concat("\n");
};

let markdown_to_html = markdown => {
  markdown
  |> convert_headings
  |> convert_emphasis
  |> convert_code
  |> convert_links
  |> convert_lists
  |> wrap_lists
  |> convert_blockquotes
  |> convert_paragraphs
  |> String.trim;
};

let extract_text = markdown => {
  markdown
  |> Str.global_replace(Str.regexp("\\[([^]]*)\\]\\([^)]*\\)"), "\\1")
  |> Str.global_replace(Str.regexp("\\*\\*\\([^*]*\\)\\*\\*"), "\\1")
  |> Str.global_replace(Str.regexp("\\*\\([^*]*\\)\\*"), "\\1")
  |> Str.global_replace(Str.regexp("__\\([^_]*\\)__"), "\\1")
  |> Str.global_replace(Str.regexp("_\\([^_]*\\)_"), "\\1")
  |> Str.global_replace(Str.regexp("~~\\([^~]*\\)~~"), "\\1")
  |> Str.global_replace(Str.regexp("`\\([^`]*\\)`"), "\\1")
  |> Str.global_replace(Str.regexp("```[^`]*```"), "")
  |> Str.global_replace(Str.regexp("^#+ .*$"), "\n")
  |> Str.global_replace(Str.regexp("^#* .*$"), "\n")
  |> Str.global_replace(Str.regexp("> \\|>"), "")
  |> Str.global_replace(Str.regexp("\\[\\|\\]\\|\\(\\|\\)"), "")
  |> Str.global_replace(Str.regexp("-\\|\\+\\|\\*\\s+"), "")
  |> Str.global_replace(Str.regexp("^\\d+\\.\\s+"), "")
  |> Str.global_replace(Str.regexp("\\\\"), "")
  |> String.trim;
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
