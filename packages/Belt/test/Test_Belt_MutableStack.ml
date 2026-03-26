type tree = { value : int; left : tree option; right : tree option }

let node ?left ?right value = { value; left; right }
let traversal_tree = node 1 ~left:(node 2 ~left:(node 4) ~right:(node 5)) ~right:(node 3)

let push_all_left start stack =
  let current = ref start in
  while Option.is_some !current do
    let value = Option.get !current in
    Belt.MutableStack.push stack value;
    current := value.left
  done

let in_order root =
  let stack = Belt.MutableStack.make () in
  let queue = Belt.MutableQueue.make () in
  push_all_left (Some root) stack;
  while not (Belt.MutableStack.isEmpty stack) do
    match Belt.MutableStack.pop stack with
    | None -> ()
    | Some value ->
        Belt.MutableQueue.add queue value.value;
        push_all_left value.right stack
  done;
  Belt.MutableQueue.toArray queue

let in_order_dynamic root =
  let stack = Belt.MutableStack.make () in
  let queue = Belt.MutableQueue.make () in
  push_all_left (Some root) stack;
  Belt.MutableStack.dynamicPopIter stack (fun popped ->
      Belt.MutableQueue.add queue popped.value;
      push_all_left popped.right stack);
  Belt.MutableQueue.toArray queue

let suites =
  [
    ( "MutableStack",
      [
        test "inorder traversal" (fun () -> assert_array Alcotest.int [| 4; 2; 5; 1; 3 |] (in_order traversal_tree));
        test "dynamicPopIter traversal" (fun () ->
            assert_array Alcotest.int [| 4; 2; 5; 1; 3 |] (in_order_dynamic traversal_tree));
      ] );
  ]
