let id () =
  let strJson = `String "Melange is awesome" in
  Alcotest.(check @@ string)
    "should be equal" "Melange is awesome"
    (strJson |> Json.Decode.string |> Json.Decode.id)

let string () =
  let strJson = `String "Melange is awesome" in
  Alcotest.(check @@ string)
    "should be equal" "Melange is awesome"
    (strJson |> Json.Decode.string)

let int () =
  let intJson = `Int 256 in
  Alcotest.(check @@ int) "should be equal" 256 (intJson |> Json.Decode.int)

let float () =
  let floatJson = `Float 1.61 in
  Alcotest.(check @@ float @@ 0.)
    "should be equal" 1.61
    (floatJson |> Json.Decode.float)

let bool () =
  let boolJson = `Bool true in
  Alcotest.(check @@ bool) "should be equal" true (boolJson |> Json.Decode.bool)

let nullable () =
  Alcotest.(check @@ option @@ int)
    "should be equal" (Some 1)
    (Json.Decode.nullable Json.Decode.int (`Int 1))

let nullableNone () =
  Alcotest.(check @@ option @@ int)
    "should be equal" None
    (Json.Decode.nullable Json.Decode.int `Null)

let list () =
  let listJson = `List [ `Int 1; `Int 2; `Int 3; `Int 5; `Int 7 ] in
  Alcotest.(check @@ list @@ int)
    "should be equal" [ 1; 2; 3; 5; 7 ]
    (Json.Decode.list Json.Decode.int listJson)

let array () =
  let arrayJson = `List [ `Int 1; `Int 2; `Int 3; `Int 5; `Int 7 ] in
  Alcotest.(check @@ array @@ int)
    "should be equal" [| 1; 2; 3; 5; 7 |]
    (Json.Decode.array Json.Decode.int arrayJson)

let pair () =
  let pairJson = `List [ `Int 1; `String "a" ] in
  match Json.Decode.pair Json.Decode.int Json.Decode.string pairJson with
  | a, b ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b

let pair_raise () =
  let tuple3Json = `List [ `Int 1; `String "a"; `Float 1.61 ] in
  Alcotest.check_raises "should be equal"
    (Json.Decode.DecodeError "Expected array of length 2, got array of length 3")
    (fun () ->
      let _ = Json.Decode.pair Json.Decode.int Json.Decode.int tuple3Json in
      ())

let tuple3 () =
  let tuple3Json = `List [ `Int 1; `String "a"; `Float 1.61 ] in
  match
    Json.Decode.tuple3 Json.Decode.int Json.Decode.string Json.Decode.float
      tuple3Json
  with
  | a, b, c ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b;
      Alcotest.(check @@ float @@ 0.) "should be equal" 1.61 c

let tuple3_raise () =
  let listJson = `List [ `Int 1; `String "a"; `Float 1.61; `Bool false ] in
  Alcotest.check_raises "should be equal"
    (Json.Decode.DecodeError "Expected array of length 3, got array of length 4")
    (fun () ->
      let _ =
        Json.Decode.tuple3 Json.Decode.int Json.Decode.string Json.Decode.float
          listJson
      in
      ())

let tuple4 () =
  let tuple4Json = `List [ `Int 1; `String "a"; `Float 1.61; `Bool false ] in
  match
    Json.Decode.tuple4 Json.Decode.int Json.Decode.string Json.Decode.float
      Json.Decode.bool tuple4Json
  with
  | a, b, c, d ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b;
      Alcotest.(check @@ float @@ 0.) "should be equal" 1.61 c;
      Alcotest.(check @@ bool) "should be equal" false d

let tuple4_raise () =
  let tuple4Json =
    `List [ `Int 1; `String "a"; `Float 1.61; `Bool false; `String "hey" ]
  in
  Alcotest.check_raises "should be equal"
    (Json.Decode.DecodeError "Expected array of length 4, got array of length 5")
    (fun () ->
      let _ =
        Json.Decode.tuple4 Json.Decode.int Json.Decode.string Json.Decode.float
          Json.Decode.bool tuple4Json
      in
      ())

let field () =
  let json = `Assoc [ ("name", `String "John Doe") ] in
  Alcotest.check Alcotest.string "should be equal" "John Doe"
    (Json.Decode.field "name" Json.Decode.string json)

let withDefault () =
  let tuple3Json = `List [ `Int 1; `Int 2; `Int 3; `Int 3 ] in
  let a, b, c =
    Json.Decode.withDefault (3, 2, 1)
      (Json.Decode.tuple3 Json.Decode.int Json.Decode.int Json.Decode.int)
      tuple3Json
  in
  Alcotest.check
    (Alcotest.list Alcotest.int)
    "should be equal" [ 3; 2; 1 ] [ a; b; c ]

let dict () =
  let dictJson = `Assoc [ ("name", `String "John Doe") ] in
  Alcotest.(check @@ Alcotest.string)
    "should be equal" "John Doe"
    (Js.Dict.unsafeGet (Json.Decode.dict Json.Decode.string dictJson) "name")

let at () =
  let strJson =
    `Assoc
      [
        ("name", `Assoc [ ("first", `String "John"); ("last", `String "Doe") ]);
      ]
  in
  Alcotest.(check @@ string)
    "should be equal" "Doe"
    (strJson |> Json.Decode.at [ "name"; "last" ] Json.Decode.string)

let at_raise () =
  let strJson =
    `Assoc
      [
        ("name", `Assoc [ ("first", `String "John"); ("last", `String "Doe") ]);
      ]
  in
  Alcotest.check_raises "should raise"
    (Json.Decode.DecodeError "Expected field 'second'\n\tat field 'name'")
    (fun () ->
      strJson
      |> Json.Decode.at [ "name"; "second" ] Json.Decode.string
      |> ignore)

let at_raise_empty () =
  let strJson =
    `Assoc
      [
        ("name", `Assoc [ ("first", `String "John"); ("last", `String "Doe") ]);
      ]
  in
  Alcotest.check_raises "should raise"
    (Invalid_argument "Expected key_path to contain at least one element")
    (fun () -> strJson |> Json.Decode.at [] Json.Decode.string |> ignore)

let oneOf () =
  let strJson = `String "Melange is awesome" in
  Alcotest.(check @@ string)
    "should be equal" "Melange is awesome"
    (strJson
    |> Json.Decode.oneOf
         [ Json.Decode.(field "name" string); Json.Decode.string ])

let oneOf_raise () =
  let strJson = `Assoc [ ("last_name", `String "John Doe") ] in
  Alcotest.check_raises "should raises"
    (Json.Decode.DecodeError
       "All decoders given to oneOf failed. Here are all the errors: \n\
        - Expected field 'name'\n\
        - Expected field 'first_name'\n\
        And the JSON being decoded: {\"last_name\":\"John Doe\"}") (fun () ->
      strJson
      |> Json.Decode.oneOf
           [
             Json.Decode.(field "name" string);
             Json.Decode.(field "first_name" string);
           ]
      |> ignore)

let either () =
  let strJson = `String "Melange is awesome" in
  Alcotest.(check @@ string)
    "should be equal" "Melange is awesome"
    (strJson
    |> Json.Decode.either Json.Decode.(field "name" string) Json.Decode.string)

let either_raise () =
  let intJson = `Int 1 in
  Alcotest.check_raises "should raises"
    (Json.Decode.DecodeError
       "All decoders given to oneOf failed. Here are all the errors: \n\
        - Expected object, got `Int (1)\n\
        - Expected string, got int\n\
        And the JSON being decoded: 1") (fun () ->
      intJson
      |> Json.Decode.either Json.Decode.(field "name" string) Json.Decode.string
      |> ignore)

let map () =
  let intValue =
    (Json.Decode.map (( + ) 2)) Json.Decode.int (Json.Encode.int 23)
  in
  Alcotest.(check @@ int) "should be equal" 25 intValue

let andThen () =
  let strJson : Yojson.Basic.t =
    `Assoc [ ("first_name", `String "John"); ("last_name", `String "Doe") ]
  in
  let lastName =
    strJson
    |> Json.Decode.andThen
         (function
           | "John" ->
               print_endline "hey";
               Json.Decode.field "last_name" Json.Decode.string
           | _ -> Json.Decode.field "first_name" Json.Decode.string)
         (Json.Decode.field "first_name" Json.Decode.string)
  in

  Alcotest.(check @@ string) "should be equal" "Doe" lastName

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "Decode",
    [
      case "Decode id" id;
      case "Decode string" string;
      case "Decode int" int;
      case "Decode float" float;
      case "Decode bool" bool;
      case "Decode nullable" nullable;
      case "Decode list" list;
      case "Decode array" array;
      case "Decode field" field;
      case "Decode pair" pair;
      case "Decode pair_raise" pair_raise;
      case "Decode tuple3" tuple3;
      case "Decode tuple3_raise" tuple3_raise;
      case "Decode tuple4" tuple4;
      case "Decode tuple4_raise" tuple4_raise;
      case "Decode withDefault" withDefault;
      case "Decode map" map;
      case "Decode at" at;
      case "Decode at_raise" at_raise;
      case "Decode oneOf" oneOf;
      case "Decode oneOf_raise" oneOf_raise;
      case "Decode either" either;
      case "Decode either_raise" either_raise;
      case "Decode at_raise_empty" at_raise_empty;
      case "Decode andThen" andThen;
    ] )
