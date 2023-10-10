let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let case title (fn : unit -> unit) = Alcotest.test_case title `Quick fn

let tests =
  ( "OK",
    [
      case "host" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.host url) "sancho.dev");
      case "hostname" (fun () ->
          let url = URL.make "https://sancho.dev:8080" in
          assert_string (URL.host url) "sancho.dev:8080";
          assert_string (URL.hostname url) "sancho.dev");
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
      case "username" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.username url) "";
          let url = URL.make "http://admin@example.com" in
          assert_string (URL.username url) "admin");
    ] )

let () = Alcotest.run "URL" [ tests ]
