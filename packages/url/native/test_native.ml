let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let case title (fn : unit -> unit) = Alcotest.test_case title `Quick fn

let tests =
  ( "OK",
    [
      case "new URL" (fun () ->
          let url = URL.make "https://sancho.dev" in
          assert_string (URL.host url) "sancho.dev");
    ] )

let () = Alcotest.run "URL" [ tests ]
