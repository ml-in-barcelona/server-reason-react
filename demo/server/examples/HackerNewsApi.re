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

type cacheEntry = {
  body: string,
  expiresAt: float,
};

let cache: Hashtbl.t(string, cacheEntry) = Hashtbl.create(64);

let member = (name, json) => Yojson.Safe.Util.member(name, json);

let stringMember = (name, json) =>
  switch (member(name, json)) {
  | `String(value) => Some(value)
  | _ => None
  };

let intMember = (name, json) =>
  switch (member(name, json)) {
  | `Int(value) => Some(value)
  | `Intlit(value) => int_of_string_opt(value)
  | _ => None
  };

let floatMember = (name, json) =>
  intMember(name, json) |> Option.map(float_of_int);

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

let parseStory = json =>
  switch (
    Option.bind(stringMember("objectID", json), int_of_string_opt),
    stringMember("title", json),
    stringMember("author", json),
    floatMember("created_at_i", json),
  ) {
  | (Some(id), Some(title), Some(author), Some(createdAt)) =>
    Some({
      id,
      title,
      url: stringMember("url", json),
      author,
      points: intMember("points", json) |> Option.value(~default=0),
      createdAt,
      comments: intMember("num_comments", json) |> Option.value(~default=0),
      text: stringMember("story_text", json) |> Option.map(plainText),
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
    switch (Yojson.Safe.from_string(body)) {
    | json =>
      switch (member("hits", json)) {
      | `List(hits) => Lwt_result.return(List.filter_map(parseStory, hits))
      | _ => Lwt_result.fail("Hacker News API returned an invalid feed")
      }
    | exception _ => Lwt_result.fail("Hacker News API returned invalid JSON")
    }
  };
};

let parseStoryPage = json => {
  let remaining = ref(200);
  let rec parseComment = json =>
    if (remaining^ <= 0) {
      None;
    } else {
      remaining := remaining^ - 1;
      switch (
        intMember("id", json),
        stringMember("author", json),
        stringMember("text", json),
        floatMember("created_at_i", json),
      ) {
      | (Some(id), Some(author), Some(text), Some(createdAt)) =>
        let children =
          switch (member("children", json)) {
          | `List(children) => List.filter_map(parseComment, children)
          | _ => []
          };
        Some({
          id,
          author,
          text: plainText(text),
          createdAt,
          children,
        });
      | _ => None
      };
    };

  switch (
    intMember("id", json),
    stringMember("title", json),
    stringMember("author", json),
    floatMember("created_at_i", json),
  ) {
  | (Some(id), Some(title), Some(author), Some(createdAt)) =>
    let comments =
      switch (member("children", json)) {
      | `List(children) => List.filter_map(parseComment, children)
      | _ => []
      };
    Some({
      story: {
        id,
        title,
        url: stringMember("url", json),
        author,
        points: intMember("points", json) |> Option.value(~default=0),
        createdAt,
        comments: List.length(comments),
        text: stringMember("text", json) |> Option.map(plainText),
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
    switch (Yojson.Safe.from_string(body) |> parseStoryPage) {
    | Some(story) => Lwt_result.return(story)
    | None => Lwt_result.fail("Hacker News story was not found")
    | exception _ => Lwt_result.fail("Hacker News API returned invalid JSON")
    }
  };
};
