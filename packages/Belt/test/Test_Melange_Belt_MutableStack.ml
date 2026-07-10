(* Ported from melange jscomp/test/bs_stack_test.ml.
   The melange original models the tree with [Js.undefined] children and a
   [@@deriving jsProperties, getSet] record; natively we use plain records with
   [option] children instead. *)

module S = Belt.MutableStack
module Q = Belt.MutableQueue

type node = { value : int; left : node option; right : node option }

let n ?l ?r a = { value = a; left = l; right = r }

let push_all_left start stack =
  let current = ref start in
  while Option.is_some !current do
    let v = Option.get !current in
    S.push stack v;
    current := v.left
  done

let in_order (root : node option) : int array =
  let s : node S.t = S.make () in
  let q : int Q.t = Q.make () in
  push_all_left root s;
  while not (S.isEmpty s) do
    match S.pop s with
    | None -> ()
    | Some v ->
        Q.add q v.value;
        push_all_left v.right s
  done;
  Q.toArray q

let in_order3 (root : node option) : int array =
  let s : node S.t = S.make () in
  let q : int Q.t = Q.make () in
  push_all_left root s;
  S.dynamicPopIter s (fun popped ->
      Q.add q popped.value;
      push_all_left popped.right s);
  Q.toArray q

(* skipped (melange-only): inOrder2 builds no observable result and is never
   asserted in the melange original; test2/test3 trees are likewise unused *)

let test1 = n 1 ~l:(n 2 ~l:(n 4) ~r:(n 5)) ~r:(n 3)

let suites =
  [
    ( "Melange.Belt.MutableStack",
      [
        test "inOrder traversal" (fun () -> assert_array Alcotest.int [| 4; 2; 5; 1; 3 |] (in_order (Some test1)));
        test "inOrder3 dynamicPopIter traversal" (fun () ->
            assert_array Alcotest.int [| 4; 2; 5; 1; 3 |] (in_order3 (Some test1)));
      ] );
  ]
