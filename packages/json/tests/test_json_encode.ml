let expectFail expect (got : Json.t) =
  let expectFailStr = Printf.sprintf "Expect %s, got %s" expect in
  match got with
  | `List _ -> expectFailStr "`List"
  | `Int _ -> expectFailStr "`Int"
  | `String _ -> expectFailStr "`String"
  | `Null -> expectFailStr "`Null"
  | `Float _ -> expectFailStr "`Float"
  | `Bool _ -> expectFailStr "`Bool"
  | `Assoc _ -> expectFailStr "`Assoc"

let string () =
  match Json.Encode.string "Melange is awesome" with
  | `String str ->
      Alcotest.(check @@ string) "should be equal" "Melange is awesome" str
  | a -> Alcotest.fail (expectFail "`String" a)

let nullable () =
  match Json.Encode.nullable Json.Encode.string (Some "Melange is awesome") with
  | `String str ->
      Alcotest.(check @@ string) "should be equal" "Melange is awesome" str
  | a -> Alcotest.fail (expectFail "`String" a)

let int () =
  match Json.Encode.int 256 with
  | `Int int -> Alcotest.(check @@ int) "should be equal" 256 int
  | a -> Alcotest.fail (expectFail "`Int" a)

let bool () =
  match Json.Encode.bool true with
  | `Bool bool -> Alcotest.(check @@ bool) "should be equal" true bool
  | a -> Alcotest.fail (expectFail "`Bool" a)

let float () =
  match Json.Encode.float 1.61 with
  | `Float float -> Alcotest.(check @@ float @@ 0.) "should be equal" 1.61 float
  | a -> Alcotest.fail (expectFail "`Float" a)

let list () =
  match Json.Encode.list [ 1; 2 ] Json.Encode.int with
  | `List [ `Int 1; `Int 2 ] ->
      Alcotest.(check @@ pass) "should be [ 1; 2 ]" () ()
  | a -> Alcotest.fail (expectFail "`List" a)

let array () =
  match Json.Encode.array [| 1; 2 |] Json.Encode.int with
  | `List [ `Int 1; `Int 2 ] ->
      Alcotest.(check @@ pass) "should be `List [ `Int 1; `Int 2 ] ]" () ()
  | a -> Alcotest.fail (expectFail "`List" a)

let pair () =
  match Json.Encode.pair (1, "a") Json.Encode.int Json.Encode.string with
  | `List [ `Int a; `String b ] ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b
  | a -> Alcotest.fail (expectFail "`List" a)

let tuple3 () =
  match
    Json.Encode.tuple3 (1, "a", 1.61) Json.Encode.int Json.Encode.string
      Json.Encode.float
  with
  | `List [ `Int a; `String b; `Float c ] ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b;
      Alcotest.(check @@ float @@ 0.) "should be equal" 1.61 c
  | a -> Alcotest.fail (expectFail "`List" a)

let tuple4 () =
  match
    Json.Encode.tuple4 (1, "a", 1.61, false) Json.Encode.int Json.Encode.string
      Json.Encode.float Json.Encode.bool
  with
  | `List [ `Int a; `String b; `Float c; `Bool d ] ->
      Alcotest.(check @@ int) "should be equal" 1 a;
      Alcotest.(check @@ string) "should be equal" "a" b;
      Alcotest.(check @@ float @@ 0.) "should be equal" 1.61 c;
      Alcotest.(check @@ bool) "should be equal" false d
  | a -> Alcotest.fail (expectFail "`List" a)

let dict () =
  let d = Js.Dict.empty () in
  Js.Dict.set d "Answer" 42;

  match Json.Encode.dict Json.Encode.int d with
  | `Assoc [ (key, value); _ ] ->
      Alcotest.(check @@ string) "should be equal" "Answer" key;
      Alcotest.(check @@ int) "should be equal" 42 (Json.Decode.int value)
  | a -> Alcotest.fail (expectFail "`Assoc" a)

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "Encode",
    [
      case "Encode string" string;
      case "Encode int" int;
      case "Encode float" float;
      case "Encode bool" bool;
      case "Encode nullable" nullable;
      case "Encode list" list;
      case "Encode array" array;
      case "Encode pair" pair;
      case "Encode tuple3" tuple3;
      case "Encode tuple4" tuple4;
    ] )
