type feed =
  | Top
  | New
  | Best
  | Ask
  | Show
  | Jobs;

type story = {
  id: int,
  title: string,
  url: option(string),
  author: string,
  points: int,
  createdAt: float,
  comments: int,
  text: option(string),
};

type comment = {
  id: int,
  author: string,
  text: string,
  createdAt: float,
  children: list(comment),
};

type storyPage = {
  story,
  comments: list(comment),
};

open Melange_json.Primitives;

[@deriving of_json]
[@json.allow_extra_fields]
type feedStoryDto = {
  [@json.key "objectID"]
  objectId: string,
  [@json.option]
  title: option(string),
  [@json.option]
  url: option(string),
  [@json.option]
  author: option(string),
  [@json.option]
  points: option(int),
  [@json.key "created_at_i"] [@json.option]
  createdAt: option(int),
  [@json.key "num_comments"] [@json.option]
  comments: option(int),
  [@json.key "story_text"] [@json.option]
  text: option(string),
};

[@deriving of_json]
[@json.allow_extra_fields]
type feedDto = {hits: list(feedStoryDto)};

[@deriving of_json]
[@json.allow_extra_fields]
type itemDto = {
  id: int,
  [@json.option]
  title: option(string),
  [@json.option]
  url: option(string),
  [@json.option]
  author: option(string),
  [@json.option]
  points: option(int),
  [@json.key "created_at_i"] [@json.option]
  createdAt: option(int),
  [@json.option]
  text: option(string),
  [@json.default []]
  children: list(itemDto),
};

type cacheEntry = {
  body: string,
  expiresAt: float,
};

let cache: Hashtbl.t(string, cacheEntry) = Hashtbl.create(64);

let plainText = html =>
  html |> Soup.parse |> Soup.texts |> String.concat(" ") |> String.trim;

let apiUri = (path, params) =>
  Uri.of_string("https://hn.algolia.com/api/v1/" ++ path)
  |> (uri => Uri.add_query_params'(uri, params));

let fetchText = (~ttl, uri) => {
  let key = Uri.to_string(uri);
  let now = Unix.time();
  switch (Hashtbl.find_opt(cache, key)) {
  | Some(entry) when entry.expiresAt > now => Lwt_result.return(entry.body)
  | stale =>
    switch%lwt (Cohttp_lwt_unix.Client.get(uri)) {
    | (response, body) =>
      let status =
        response |> Cohttp.Response.status |> Cohttp.Code.code_of_status;
      let%lwt body = Cohttp_lwt.Body.to_string(body);
      if (status >= 200 && status < 300) {
        Hashtbl.replace(
          cache,
          key,
          {
            body,
            expiresAt: now +. ttl,
          },
        );
        Lwt_result.return(body);
      } else {
        switch (stale) {
        | Some(entry) => Lwt_result.return(entry.body)
        | None =>
          Lwt_result.fail(
            "Hacker News API returned HTTP " ++ Int.to_string(status),
          )
        };
      };
    | exception error =>
      switch (stale) {
      | Some(entry) => Lwt_result.return(entry.body)
      | None => Lwt_result.fail(Printexc.to_string(error))
      }
    }
  };
};

let parseStory = (dto: feedStoryDto) =>
  switch (
    int_of_string_opt(dto.objectId),
    dto.title,
    dto.author,
    dto.createdAt,
  ) {
  | (Some(id), Some(title), Some(author), Some(createdAt)) =>
    Some({
      id,
      title,
      url: dto.url,
      author,
      points: dto.points |> Option.value(~default=0),
      createdAt: float_of_int(createdAt),
      comments: dto.comments |> Option.value(~default=0),
      text: dto.text |> Option.map(plainText),
    })
  | _ => None
  };

let feedRequest = (~feed, ~query) => {
  let common = [("hitsPerPage", "30")];
  switch (query) {
  | Some(query) when String.trim(query) != "" =>
    apiUri("search", [("query", query), ("tags", "story"), ...common])
  | _ =>
    switch (feed) {
    | Top => apiUri("search", [("tags", "front_page"), ...common])
    | New => apiUri("search_by_date", [("tags", "story"), ...common])
    | Best =>
      let now = int_of_float(Unix.time());
      let cutoff = now - now mod 3600 - 86400;
      apiUri(
        "search",
        [
          ("tags", "story"),
          ("numericFilters", "created_at_i>" ++ Int.to_string(cutoff)),
          ...common,
        ],
      );
    | Ask => apiUri("search", [("tags", "ask_hn"), ...common])
    | Show => apiUri("search", [("tags", "show_hn"), ...common])
    | Jobs => apiUri("search_by_date", [("tags", "job"), ...common])
    }
  };
};

let fetchFeed = (~feed, ~query) => {
  let uri = feedRequest(~feed, ~query);
  switch%lwt (fetchText(~ttl=60., uri)) {
  | Error(error) => Lwt_result.fail(error)
  | Ok(body) =>
    switch (body |> Melange_json.of_string |> feedDto_of_json) {
    | { hits } => Lwt_result.return(List.filter_map(parseStory, hits))
    | exception error =>
      Lwt_result.fail(
        "Hacker News API returned invalid JSON: " ++ Printexc.to_string(error),
      )
    }
  };
};

let parseStoryPage = (dto: itemDto) => {
  let remaining = ref(200);
  let rec parseComment = (dto: itemDto) =>
    if (remaining^ <= 0) {
      None;
    } else {
      remaining := remaining^ - 1;
      switch (dto.author, dto.text, dto.createdAt) {
      | (Some(author), Some(text), Some(createdAt)) =>
        let children = List.filter_map(parseComment, dto.children);
        Some({
          id: dto.id,
          author,
          text: plainText(text),
          createdAt: float_of_int(createdAt),
          children,
        });
      | _ => None
      };
    };

  switch (dto.title, dto.author, dto.createdAt) {
  | (Some(title), Some(author), Some(createdAt)) =>
    let comments = List.filter_map(parseComment, dto.children);
    Some({
      story: {
        id: dto.id,
        title,
        url: dto.url,
        author,
        points: dto.points |> Option.value(~default=0),
        createdAt: float_of_int(createdAt),
        comments: List.length(comments),
        text: dto.text |> Option.map(plainText),
      },
      comments,
    });
  | _ => None
  };
};

let fetchStory = id => {
  let uri = apiUri("items/" ++ Int.to_string(id), []);
  switch%lwt (fetchText(~ttl=300., uri)) {
  | Error(error) => Lwt_result.fail(error)
  | Ok(body) =>
    switch (
      body |> Melange_json.of_string |> itemDto_of_json |> parseStoryPage
    ) {
    | Some(story) => Lwt_result.return(story)
    | None => Lwt_result.fail("Hacker News story was not found")
    | exception error =>
      Lwt_result.fail(
        "Hacker News API returned invalid JSON: " ++ Printexc.to_string(error),
      )
    }
  };
};
