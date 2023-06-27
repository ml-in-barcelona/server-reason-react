let case title fn = Alcotest.test_case title `Quick fn

let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let assert_int left right =
  Alcotest.check Alcotest.int "should be equal" right left

let assert_option ty left right =
  Alcotest.check (Alcotest.option ty) "should be equal" right left

let assert_array ty left right =
  Alcotest.check (Alcotest.array ty) "should be equal" right left

let assert_list ty left right =
  Alcotest.check (Alcotest.list ty) "should be equal" right left

type ('a, 'id) eq = ('a, 'id) Belt.Id.eq
type ('a, 'id) hash = ('a, 'id) Belt.Id.hash
type ('a, 'id) id = ('a, 'id) Belt.Id.hashable

module Example = struct
  include (
    struct
      type foo = { name : string; age : int }

      let foo : name:string -> age:int -> foo = fun ~name ~age -> { name; age }
      let name : foo -> string = fun o -> o.name
      let age : foo -> int = fun o -> o.age
    end :
      sig
        type foo

        val foo : name:string -> age:int -> foo
        val name : foo -> string
        val age : foo -> int
      end)
end

let eq () =
  let tony = Example.foo ~name:"Tony" ~age:27 in
  print_endline (Example.name tony)

let length () =
  let arr : int Js.undefined array = Belt.Array.makeUninitialized 1 in
  assert_int 1 (Belt.Array.length arr)

let mapU () =
  let array : int Js.undefined array = Belt.Array.makeUninitialized 1 in
  let result = Belt.Array.mapU array Js.Undefined.toOption in
  assert_array (Alcotest.option Alcotest.int) array result

let mapWithIndex () =
  let result = Belt.Array.mapWithIndex [| "a"; "b"; "c" |] (fun i _ -> i) in
  assert_array Alcotest.int [| 0; 1; 2 |] result

let concat () =
  let result = Belt.List.concat [ 1; 2 ] [ 3; 4 ] in
  assert_list Alcotest.int [ 1; 2; 3; 4 ] result

let map () =
  let result =
    Belt.List.map [ 3.0; 4.0 ] (fun x -> "Number: " ^ string_of_float x)
  in
  assert_list Alcotest.string [ "Number: 3."; "Number: 4." ] result

module TestingMore = struct
  include (
    struct
      type t = { name2 : string option; [@bs.optional] age2 : int }

      let t : ?name2:string -> age2:int -> unit -> t =
       fun ?name2 ~age2 () -> { name2; age2 }

      let name2 : t -> string option = fun o -> o.name2
      let age2 : t -> int = fun o -> o.age2
    end :
      sig
        type t

        val t : ?name2:string -> age2:int -> unit -> t
        val name2 : t -> string option
        val age2 : t -> int
      end)
end

let aaaaa = TestingMore.t ~age2:10 ()

let keep_1 () =
  let (some10 : int option) = Belt.Option.keep (Some 10) (fun x -> x > 5) in
  assert_option Alcotest.int (Some 10) some10

let keep_2 () =
  let (none : int option) = Belt.Option.keep (Some 4) (fun x -> x > 5) in
  assert_option Alcotest.int None none

let keep_3 () =
  let (none : int option) = Belt.Option.keep None (fun x -> x > 5) in
  assert_option Alcotest.int None none

let fromString () =
  let ten = Belt.Int.fromString "10" in
  match ten with
  | Some t -> assert_string "10" (Belt.Int.toString t)
  | None -> Alcotest.fail "fromString returned None"

let toString () =
  let ten = Belt.Int.toString 10 in
  assert_string "10" ten

let truncateToLengthUnsafe () =
  let arr = Belt.Array.makeUninitializedUnsafe 5 "lola" in
  let newa = Belt.Array.truncateToLengthUnsafe arr 3 in
  assert_string (Belt.Array.getUnsafe newa 0) "lola"

let makeUninitializedUnsafe () =
  let arr = Belt.Array.makeUninitializedUnsafe 5 "lola" in
  assert_string (Belt.Array.getUnsafe arr 0) "lola";
  assert_string (Belt.Array.getUnsafe arr 1) "lola";
  assert_string (Belt.Array.getUnsafe arr 2) "lola";
  assert_string (Belt.Array.getUnsafe arr 3) "lola";
  assert_string (Belt.Array.getUnsafe arr 4) "lola"

let () =
  Alcotest.run "Belt"
    [
      ("Records", [ case "eq" eq ]);
      ( "Array",
        [
          case "truncateToLengthUnsafe" truncateToLengthUnsafe;
          case "makeUninitializedUnsafe" makeUninitializedUnsafe;
          case "length" length;
        ] );
      ( "List",
        [
          case "eq" eq;
          case "map" map;
          case "mapU" mapU;
          case "mapWithIndex" mapWithIndex;
          case "concat" concat;
        ] );
      ("Int", [ case "fromString" fromString; case "toString" toString ]);
      ( "Option",
        [ case "keep_1" keep_1; case "keep_2" keep_2; case "keep_3" keep_3 ] );
    ]
