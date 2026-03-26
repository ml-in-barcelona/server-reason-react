let test title fn = Alcotest.test_case title `Quick fn
let slow_test title fn = Alcotest.test_case title `Slow fn
let float = Alcotest.float 0.
let assert_string expected actual = Alcotest.check Alcotest.string "should be equal" expected actual
let assert_int expected actual = Alcotest.check Alcotest.int "should be equal" expected actual
let assert_float expected actual = Alcotest.check float "should be equal" expected actual
let assert_bool expected actual = Alcotest.check Alcotest.bool "should be equal" expected actual
let assert_option ty expected actual = Alcotest.check (Alcotest.option ty) "should be equal" expected actual
let assert_array ty expected actual = Alcotest.check (Alcotest.array ty) "should be equal" expected actual
let assert_list ty expected actual = Alcotest.check (Alcotest.list ty) "should be equal" expected actual

let assert_pair left_ty right_ty expected actual =
  Alcotest.check (Alcotest.pair left_ty right_ty) "should be equal" expected actual

let assert_array_unordered ty expected actual =
  let expected = Array.copy expected in
  let actual = Array.copy actual in
  Array.sort compare expected;
  Array.sort compare actual;
  Alcotest.check (Alcotest.array ty) "should be equal" expected actual

let assert_same_physical left right = assert_bool true (left == right)
let assert_not_same_physical left right = assert_bool false (left == right)
let assert_undefined ty expected actual = assert_option ty expected (Js.Undefined.toOption actual)
let assert_raises_any f = match f () with exception _ -> () | _ -> Alcotest.fail "Expected an exception"

let assert_raises_js_error f =
  match f () with exception Js.Exn.Error _ -> () | _ -> Alcotest.fail "Expected Js.Exn.Error"

let inclusive_range start finish = if finish < start then [||] else Array.init (finish - start + 1) (fun i -> start + i)
let reverse_inclusive_range start finish = inclusive_range start finish |> Array.to_list |> List.rev |> Array.of_list
let arithmetic_sum start finish = if finish < start then 0 else (start + finish) * (finish - start + 1) / 2

let shuffled_copy values =
  let values = Array.copy values in
  let state = Random.State.make [| 0x5eed; Array.length values |] in
  for i = Array.length values - 1 downto 1 do
    let j = Random.State.int state (i + 1) in
    let tmp = values.(i) in
    values.(i) <- values.(j);
    values.(j) <- tmp
  done;
  values

let shuffled_range start finish = shuffled_copy (inclusive_range start finish)
let shuffled_pairs start finish = Array.map (fun i -> (i, i)) (shuffled_range start finish)

module IntCmp = Belt.Id.MakeComparable (struct
  type t = int

  let cmp = compare
end)

module IntCmpDesc = Belt.Id.MakeComparable (struct
  type t = int

  let cmp left right = compare right left
end)

module StringCmp = Belt.Id.MakeComparable (struct
  type t = string

  let cmp = compare
end)

module IntHash = Belt.Id.MakeHashable (struct
  type t = int

  let hash = Hashtbl.hash
  let eq = ( = )
end)

module CollidingIntHash = Belt.Id.MakeHashable (struct
  type t = int

  let hash _ = 0
  let eq = ( = )
end)
