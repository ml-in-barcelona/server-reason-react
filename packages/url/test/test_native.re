let assert_option = (ty, left, right) =>
  Alcotest.check(Alcotest.option(ty), "should be equal", right, left);

let assert_array = (ty, left, right) =>
  Alcotest.check(Alcotest.array(ty), "should be equal", right, left);

let assert_string = (left, right) =>
  Alcotest.check(Alcotest.string, "should be equal", right, left);

let assert_bool = (left, right) =>
  Alcotest.check(Alcotest.bool, "should be equal", right, left);

let assert_string_array = assert_array(Alcotest.string);
let assert_entries =
  assert_array(Alcotest.pair(Alcotest.string, Alcotest.string));
let assert_option_string = assert_option(Alcotest.string);

let case = (title, fn: unit => unit) =>
  Alcotest.test_case(title, `Quick, fn);

let url_tests = (
  "URL",
  [
    case("make", () => {
      let url = URL.makeExn("https://sancho.dev");
      assert_string(URL.toString(url), "https://sancho.dev");
    }),
    case("makeWith", () => {
      let url = URL.makeWith("about", ~base="https://sancho.dev");
      assert_option_string(URL.host(url), Some("sancho.dev"));
      assert_string(URL.pathname(url), "/about");
      assert_string(URL.toString(url), "https://sancho.dev/about");
    }),
    case("makeWith and relative base", () => {
      let url = URL.makeWith("../cats", ~base="http://www.example.com/dogs");

      assert_option_string(URL.host(url), Some("www.example.com"));
      assert_string(URL.pathname(url), "/cats");
    }),
    case("host", () => {
      let url = URL.makeExn("https://sancho.dev");
      assert_option_string(URL.host(url), Some("sancho.dev"));
      let url = URL.makeExn("../to/myfile");
      assert_option_string(URL.host(url), None);
    }),
    case("hostname", () => {
      let url = URL.makeExn("https://sancho.dev:8080");
      assert_option_string(URL.host(url), Some("sancho.dev:8080"));
      assert_string(URL.hostname(url), "sancho.dev");
    }),
    case("setHostname", () => {
      let url = URL.makeExn("https://sancho.dev:8080");
      assert_string(URL.hostname(url), "sancho.dev");
      let url = URL.setHostname(url, "www.refulz.com");
      assert_string(URL.toString(url), "https://www.refulz.com:8080");
    }),
    case("pathname", () => {
      let url = URL.makeExn("https://sancho.dev:8080");
      assert_string(URL.pathname(url), "");
      let url = URL.makeExn("https://sancho.dev:8080/about");
      assert_string(URL.pathname(url), "/about");
      let url = URL.makeExn("https://sancho.dev:8080/about/");
      assert_string(URL.pathname(url), "/about/");
      let url = URL.makeExn("https://sancho.dev:8080/about/and/more/paths");
      assert_string(URL.pathname(url), "/about/and/more/paths");
    }),
    case("origin", () => {
      let url = URL.makeExn("http://www.refulz.com:8082/index.php#tab2");
      assert_option_string(
        URL.origin(url),
        Some("http://www.refulz.com:8082"),
      );
    }),
    case("href", () => {
      let url = URL.makeExn("https://sancho.dev:8080");
      assert_string(URL.href(url), "https://sancho.dev:8080");
      let url = URL.makeExn("http://www.refulz.com:8082/index.php#tab2");
      assert_string(
        URL.href(url),
        "http://www.refulz.com:8082/index.php#tab2",
      );
    }),
    case("port", () => {
      let url = URL.makeExn("https://sancho.dev");
      assert_option_string(URL.port(url), None);
      let url = URL.makeExn("https://sancho.dev:1234");
      assert_option_string(URL.port(url), Some("1234"));
    }),
    case("hash", () => {
      let url = URL.makeExn("https://sancho.dev");
      assert_option_string(URL.hash(url), None);
      let url = URL.makeExn("http://www.refulz.com:8082/index.php#tab2");
      assert_option_string(URL.hash(url), Some("#tab2"));
    }),
    case("setHash", () => {
      let url = URL.makeExn("https://sancho.dev");
      let url = URL.setHash(url, "header");
      assert_option_string(URL.hash(url), Some("#header"));
      let url = URL.makeExn("http://www.refulz.com:8082/index.php#tab2");
      let url = URL.setHash(url, "header");
      assert_option_string(URL.hash(url), Some("#header"));
    }),
    case("search", () => {
      let url = URL.makeExn("https://www.google.es");
      assert_option_string(URL.search(url), None);
      let url = URL.makeExn("https://www.google.es?lang=en");
      assert_option_string(URL.search(url), Some("?lang=en"));
      let url = URL.makeExn("https://www.google.es?lang=en&region=cat");
      assert_option_string(URL.search(url), Some("?lang=en&region=cat"));
      let url = URL.setSearchAsString(url, "x=1&y=2");
      assert_string(URL.toString(url), "https://www.google.es?x=1&y=2");
      let search_params =
        URL.SearchParams.makeWithArray([|
          ("name", "John"),
          ("last_name", "Doe"),
        |]);
      let url = URL.setSearch(url, search_params);
      assert_string(
        URL.toString(url),
        "https://www.google.es?name=John&last_name=Doe",
      );
    }),
    case("protocol", () => {
      let url = URL.makeExn("//cdn.example.com/somewhere/something.js");
      assert_option_string(URL.protocol(url), None);
      let url = URL.makeExn("https://sancho.dev");
      assert_option_string(URL.protocol(url), Some("https:"));
      let url = URL.makeExn("http://www.refulz.com");
      assert_option_string(URL.protocol(url), Some("http:"));
      let url = URL.makeExn("ftp://jkorpela@alfa.hut.fi/.plan");
      assert_option_string(URL.protocol(url), Some("ftp:"));
      let url = URL.makeExn("slack://channel?id=123");
      assert_option_string(URL.protocol(url), Some("slack:"));
    }),
    case("setProtocol", () => {
      let url = URL.makeExn("https://sancho.dev");
      let url = URL.setProtocol(url, "lola");
      assert_string(URL.toString(url), "lola://sancho.dev");
    }),
    case("username", () => {
      let url = URL.makeExn("https://sancho.dev");
      assert_option_string(URL.username(url), None);
      let url = URL.makeExn("http://admin@example.com");
      assert_option_string(URL.username(url), Some("admin"));
    }),
    case("setUsername", () => {
      let url = URL.makeExn("https://app.herokuapp.com/auth");
      let url = URL.setUsername(url, "webmaster");
      assert_option_string(URL.password(url), None);
      assert_option_string(URL.username(url), Some("webmaster"));
      assert_string(
        URL.toString(url),
        "https://webmaster@app.herokuapp.com/auth",
      );
    }),
    case("password", () => {
      let url = URL.makeExn("https://admin:root@app.herokuapp.com/auth");
      assert_option_string(URL.username(url), Some("admin"));
      assert_option_string(URL.password(url), Some("root"));
      let url = URL.makeExn("https://:root@app.herokuapp.com/auth");
      assert_option_string(URL.username(url), None);
      let url = URL.makeExn("https://app.herokuapp.com/auth");
      assert_option_string(URL.username(url), None);
      assert_option_string(URL.password(url), None);
      let url = URL.makeExn("https://admin:@app.herokuapp.com/auth");
      assert_option_string(URL.username(url), Some("admin"));
      assert_option_string(URL.password(url), None);
    }),
    case("setPassword", () => {
      let url = URL.makeExn("https://app.herokuapp.com/auth");
      let url = URL.setPassword(url, "root");
      assert_option_string(URL.password(url), Some("root"));
      assert_string(
        URL.toString(url),
        "https://:root@app.herokuapp.com/auth",
      );
    }),
  ],
);

let url_search_params_tests =
  URL.(
    "URL.SearchParams",
    [
      /* case("make", () => {
           TODO: Fix this
           let search = SearchParams.makeExn("33");
           assert_string(SearchParams.toString(search), "33=");
         }), */
      case("has", () => {
        let search = SearchParams.makeExn("topic=api");
        assert_bool(SearchParams.has(search, "topic"), true);
        assert_bool(SearchParams.has(search, "lola"), false);
      }),
      case("get", () => {
        let search = SearchParams.makeExn("topic=api");
        let topic = SearchParams.get(search, "topic");
        assert_option_string(topic, Some("api"));
        let nope = SearchParams.get(search, "nope");
        assert_option_string(nope, None);
        let search = SearchParams.makeExn("foo=bar&foo=baz");
        let topics = SearchParams.get(search, "foo");
        /* only get the first value */
        assert_option_string(topics, Some("bar"));
        /* URLSearchParams doesn't distinguish between a parameter with nothing after the =, and a parameter that doesn't have a = altogether. */
        let emptyVal = SearchParams.makeExn("foo=&bar=baz");
        assert_option_string(SearchParams.get(emptyVal, "foo"), Some(""));
        /* let noEquals = SearchParams.makeExn("foo&bar=baz");
           assert_option_string(SearchParams.get(noEquals, "foo"), Some("")); */
        /* assert_string(SearchParams.toString(noEquals), "foo=&bar=baz"); */
      }),
      case("getAll", () => {
        let search = SearchParams.makeExn("topic=api");
        let topic = SearchParams.getAll(search, "topic");
        assert_string_array(topic, [|"api"|]);
        let search = SearchParams.makeExn("topic=api,webdev");
        let topics = SearchParams.getAll(search, "topic");
        assert_string_array(topics, [|"api", "webdev"|]);
        /* let search = SearchParams.makeExn("foo=bar&foo=baz");
           let topics = SearchParams.getAll(search, "foo"); */
        /* only get the first value */
        /* assert_string_array(topics, [|"bar", "baz"|]); */
      }),
      case("keys", () => {
        let search =
          SearchParams.makeExn("q=URLUtils.searchParams&topic=api");
        assert_string_array(SearchParams.keys(search), [|"q", "topic"|]);
        let search = SearchParams.makeExn("");
        assert_string_array(SearchParams.keys(search), [||]);
      }),
      case("values", () => {
        let search = SearchParams.makeExn("key1=v1&key2=v2");
        assert_string_array(SearchParams.values(search), [|"v1", "v2"|]);
        let search = SearchParams.makeExn("");
        assert_string_array(SearchParams.values(search), [||]);
      }),
      case("entries", () => {
        let search = SearchParams.makeExn("key1=v1&key2=v2");
        assert_entries(
          SearchParams.entries(search),
          [|("key1", "v1"), ("key2", "v2")|],
        );
        let search = SearchParams.makeExn("");
        assert_entries(SearchParams.entries(search), [||]);
      }),
      case("toString", () => {
        let search = SearchParams.makeExn("key1=v1&key2=v2");
        assert_string(SearchParams.toString(search), "key1=v1&key2=v2");
        let search = SearchParams.makeExn("");
        assert_string(SearchParams.toString(search), "");
        /*
         TODO: Encode when printing to string
         let search = SearchParams.makeExn("q=2,3,5");
          assert_string(SearchParams.toString(search), "q=2%2C3%2C5"); */
      }),
    ],
  );

Alcotest.run("URL", [url_tests, url_search_params_tests]);
