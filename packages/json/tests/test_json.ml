let parse () =
  let json = Json.parse "{ name: \"John Doe\" }" in
  match json with
  | Some (`Assoc [ ("name", `String a) ]) ->
      Alcotest.(check @@ string) "should be equal" "John Doe" a
  | _ -> Alcotest.fail "Ops"

let parseNone () =
  let json = Json.parse "ops" in
  match json with
  | None -> Alcotest.(check @@ pass) "Should be None" () ()
  | _ -> Alcotest.fail "ops"

let parseOrRaise () =
  let json = Json.parseOrRaise "{ name: \"John Doe\" }" in
  match json with
  | `Assoc [ ("name", `String a) ] ->
      Alcotest.(check @@ string) "should be equal" "John Doe" a
  | _ -> Alcotest.fail "Ops"

let parseOrRaiseExn () =
  Alcotest.check_raises "should be equal" (Json.ParseError "Blank input data")
    (fun () ->
      let _ = Json.parseOrRaise "" in
      ())

let stringify () =
  let jsonString = `Assoc [ ("name", `String "John Doe") ] |> Json.stringify in
  Alcotest.(check @@ string)
    "should be equal" "{\"name\":\"John Doe\"}" jsonString

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "Json",
    [
      case "Json parse" parse;
      case "Json parseNone" parseNone;
      case "Json parseOrRaise" parseOrRaise;
      case "Json parseOrRaiseExn" parseOrRaiseExn;
      case "Json stringify" stringify;
    ] )
