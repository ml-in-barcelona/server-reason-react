let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let decodeReply () =
  let response = ReactServerDOM.decodeReply "[\"Lola\", 20]" in
  match response with
  | [| `String hello; `Int age |] ->
      assert_string hello "Lola";
      Alcotest.check Alcotest.int "should be equal" age 20
  | _ -> Alcotest.fail "Something went wrong on the decodeReply"

let decodeFormDataReply () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_name" (`String "Lola");
  Js.FormData.append formData "1_age" (`String "20");
  Js.FormData.append formData "0" (`String "[\"$K1\"]");
  let _, formData = ReactServerDOM.decodeFormDataReply formData in
  match (Js.FormData.get formData "name", Js.FormData.get formData "age") with
  | `String name, `String age ->
      assert_string name "Lola";
      assert_string age "20"

let decodeFormDataReplyWithArg () =
  let formData = Js.FormData.make () in
  Js.FormData.append formData "1_name" (`String "Lola");
  Js.FormData.append formData "1_age" (`String "20");
  Js.FormData.append formData "0" (`String "[\"Hello\", \"$K1\"]");
  let args, formData = ReactServerDOM.decodeFormDataReply formData in
  match (args, Js.FormData.get formData "name", Js.FormData.get formData "age") with
  | [| `String greet |], `String name, `String age ->
      assert_string greet "Hello";
      assert_string name "Lola";
      assert_string age "20"
  | _ -> Alcotest.fail "Something went wrong on the decodeFormDataReplyWithArg"

let test title fn = (Printf.sprintf "Decoders / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])
let tests = [ test "decodeReply" decodeReply; test "decodeFormDataReply" decodeFormDataReply ]
