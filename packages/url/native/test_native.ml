let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let case title (fn : unit -> unit) = Alcotest.test_case title `Quick fn

let tests =
  ( "OK",
    [
      case "make" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.toString url) "https://sancho.dev");
      case "makeWith" (fun () ->
          let url = URL.makeWith "about" ~base:"https://sancho.dev" in
          assert_string (URL.host url) "sancho.dev";
          assert_string (URL.pathname url) "/about";
          assert_string (URL.toString url) "https://sancho.dev/about");
      case "makeWith and relative base" (fun () ->
          let url =
            URL.makeWith "../cats" ~base:"http://www.example.com/dogs"
          in
          assert_string (URL.host url) "www.example.com";
          assert_string (URL.pathname url) "/cats");
      case "host" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.host url) "sancho.dev");
      case "hostname" (fun () ->
          let url = URL.make "https://sancho.dev:8080" in
          assert_string (URL.host url) "sancho.dev:8080";
          assert_string (URL.hostname url) "sancho.dev");
      case "setHostname" (fun () ->
          let url = URL.make "https://sancho.dev:8080" in
          assert_string (URL.hostname url) "sancho.dev";
          let url = URL.setHostname url "www.refulz.com" in
          assert_string (URL.toString url) "https://www.refulz.com:8080");
      case "pathname" (fun () ->
          let url = URL.make "https://sancho.dev:8080" in
          assert_string (URL.pathname url) "";
          let url = URL.make "https://sancho.dev:8080/about" in
          assert_string (URL.pathname url) "/about";
          let url = URL.make "https://sancho.dev:8080/about/" in
          assert_string (URL.pathname url) "/about/";
          let url = URL.make "https://sancho.dev:8080/about/and/more/paths" in
          assert_string (URL.pathname url) "/about/and/more/paths");
      case "origin" (fun () ->
          let url = URL.make "http://www.refulz.com:8082/index.php#tab2" in
          assert_string (URL.origin url) "http://www.refulz.com:8082");
      case "href" (fun () ->
          let url = URL.make "https://sancho.dev:8080" in
          assert_string (URL.href url) "https://sancho.dev:8080";
          let url = URL.make "http://www.refulz.com:8082/index.php#tab2" in
          assert_string (URL.href url)
            "http://www.refulz.com:8082/index.php#tab2");
      case "port" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.port url) "";
          let url = URL.make "https://sancho.dev:1234" in
          assert_string (URL.port url) "1234");
      case "hash" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.hash url) "";
          let url = URL.make "http://www.refulz.com:8082/index.php#tab2" in
          assert_string (URL.hash url) "#tab2");
      case "setHash" (fun () ->
          let url = URL.make "https://sancho.dev" in
          let url = URL.setHash url "header" in
          assert_string (URL.hash url) "#header";
          let url = URL.make "http://www.refulz.com:8082/index.php#tab2" in
          let url = URL.setHash url "header" in
          assert_string (URL.hash url) "#header");
      case "search" (fun () ->
          let url = URL.make "https://www.google.es?lang=en" in
          assert_string (URL.search url) "?lang=en";
          let url = URL.make "https://www.google.es?lang=en&region=cat" in
          assert_string (URL.search url) "?lang=en&region=cat";
          let url = URL.setSearch url "x=1&y=2" in
          assert_string (URL.toString url) "https://www.google.es?x=1&y=2");
      case "protocol" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.protocol url) "https:";
          let url = URL.make "http://www.refulz.com" in
          assert_string (URL.protocol url) "http:";
          let url = URL.make "ftp://jkorpela@alfa.hut.fi/.plan" in
          assert_string (URL.protocol url) "ftp:";
          let url = URL.make "slack://channel?id=123" in
          assert_string (URL.protocol url) "slack:");
      case "setProtocol" (fun () ->
          let url = URL.make "https://sancho.dev" in
          let url = URL.setProtocol url "lola" in
          assert_string (URL.toString url) "lola://sancho.dev");
      case "username" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.username url) "";
          let url = URL.make "http://admin@example.com" in
          assert_string (URL.username url) "admin");
      case "setUsername" (fun () ->
          let url = URL.make "https://app.herokuapp.com/auth" in
          let url = URL.setUsername url "webmaster" in
          assert_string (URL.password url) "";
          assert_string (URL.username url) "webmaster";
          assert_string (URL.toString url)
            "https://webmaster@app.herokuapp.com/auth");
      case "password" (fun () ->
          let url = URL.make "https://admin:root@app.herokuapp.com/auth" in
          assert_string (URL.username url) "admin";
          assert_string (URL.password url) "root";
          let url = URL.make "https://:root@app.herokuapp.com/auth" in
          assert_string (URL.username url) "";
          assert_string (URL.password url) "root";
          let url = URL.make "https://admin:@app.herokuapp.com/auth" in
          assert_string (URL.username url) "admin";
          assert_string (URL.password url) "");
      case "setPassword" (fun () ->
          let url = URL.make "https://app.herokuapp.com/auth" in
          let url = URL.setPassword url "root" in
          assert_string (URL.password url) "root";
          assert_string (URL.toString url)
            "https://:root@app.herokuapp.com/auth");
    ] )

let () = Alcotest.run "URL" [ tests ]
