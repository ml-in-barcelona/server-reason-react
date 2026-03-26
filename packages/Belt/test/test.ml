let case title fn = Alcotest.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left
let assert_option ty left right = Alcotest.check (Alcotest.option ty) "should be equal" right left
let assert_array ty left right = Alcotest.check (Alcotest.array ty) "should be equal" right left
let assert_list ty left right = Alcotest.check (Alcotest.list ty) "should be equal" right left

let assert_array_unordered ty expected actual =
  let expected = Array.copy expected in
  let actual = Array.copy actual in
  Array.sort compare expected;
  Array.sort compare actual;
  Alcotest.check (Alcotest.array ty) "should be equal" expected actual

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
  let () = print_endline (Example.name tony) in
  let () = print_endline (Int.to_string (Example.age tony)) in
  ()

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
  let result = Belt.List.map [ 3.0; 4.0 ] (fun x -> "Number: " ^ string_of_float x) in
  assert_list Alcotest.string [ "Number: 3."; "Number: 4." ] result

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
  match ten with Some t -> assert_string "10" (Belt.Int.toString t) | None -> Alcotest.fail "fromString returned None"

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

module IntCmp = Belt.Id.MakeComparable (struct
  type t = int

  let cmp = compare
end)

(* Removing a node preserves remaining values *)
let mutable_map_remove_preserves_value () =
  let m = Belt.MutableMap.make ~id:(module IntCmp) in
  Belt.MutableMap.set m 2 "two";
  Belt.MutableMap.set m 1 "one";
  Belt.MutableMap.set m 3 "three";
  (* Remove root node with two children *)
  Belt.MutableMap.remove m 2;
  assert_option Alcotest.string None (Belt.MutableMap.get m 2);
  assert_option Alcotest.string (Some "one") (Belt.MutableMap.get m 1);
  assert_option Alcotest.string (Some "three") (Belt.MutableMap.get m 3)

module IntHash = Belt.Id.MakeHashable (struct
  type t = int

  let hash _ = 0
  let eq = ( = )
end)

(* keepMapInPlace removes and transforms entries correctly.
   The test hash forces all keys into the same bucket. *)
let hashmap_keep_map_in_place () =
  let h = Belt.HashMap.make ~hintSize:16 ~id:(module IntHash) in
  Belt.HashMap.set h 0 "zero";
  Belt.HashMap.set h 11 "eleven";
  Belt.HashMap.set h 23 "twenty-three";
  (* Keep 0 and 23, remove 11 — all same bucket by construction *)
  Belt.HashMap.keepMapInPlace h (fun k v -> if k <> 11 then Some (v ^ "!") else None);
  assert_int (Belt.HashMap.size h) 2;
  assert_option Alcotest.string (Some "zero!") (Belt.HashMap.get h 0);
  assert_option Alcotest.string None (Belt.HashMap.get h 11);
  assert_option Alcotest.string (Some "twenty-three!") (Belt.HashMap.get h 23);
  (* forEach and toArray visit all kept elements *)
  let count = ref 0 in
  Belt.HashMap.forEach h (fun _ _ -> incr count);
  assert_int !count 2;
  let pairs = Belt.HashMap.toArray h in
  assert_int (Array.length pairs) 2;
  assert_array_unordered (Alcotest.pair Alcotest.int Alcotest.string) [| (0, "zero!"); (23, "twenty-three!") |] pairs;
  let keys = Belt.HashMap.keysToArray h in
  assert_array_unordered Alcotest.int [| 0; 23 |] keys;
  let values = Belt.HashMap.valuesToArray h in
  assert_array_unordered Alcotest.string [| "zero!"; "twenty-three!" |] values

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
        [ case "eq" eq; case "map" map; case "mapU" mapU; case "mapWithIndex" mapWithIndex; case "concat" concat ] );
      ("Int", [ case "fromString" fromString; case "toString" toString ]);
      ("Option", [ case "keep_1" keep_1; case "keep_2" keep_2; case "keep_3" keep_3 ]);
      ("MutableMap", [ case "remove preserves successor value" mutable_map_remove_preserves_value ]);
      ("HashMap", [ case "keepMapInPlace" hashmap_keep_map_in_place ]);
    ]
