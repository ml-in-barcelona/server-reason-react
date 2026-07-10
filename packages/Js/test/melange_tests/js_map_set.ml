(** Tests for [Js.Map] and [Js.Set] (melange 6.0.1-54 API).

    Every expectation is verified against real JS behavior with node; the node expression is cited in a comment next to
    each assertion. *)

open Helpers

let assert_int_entries left right = Alcotest.(check (array (pair string int))) "should be equal" right left
let assert_string_array left right = Alcotest.(check (array string)) "should be equal" right left
let assert_int_array left right = Alcotest.(check (array int)) "should be equal" right left
let assert_string_pair_array left right = Alcotest.(check (array (pair string string))) "should be equal" right left

let map_tests =
  [
    test "make is empty" (fun () ->
        (* node: new Map().size === 0; JSON.stringify(Array.from(new Map())) === "[]" *)
        let m : (string, int) Js.Map.t = Js.Map.make () in
        assert_int (Js.Map.size m) 0;
        assert_int_entries (Js.Map.toArray m) [||]);
    test "set / get / has / size" (fun () ->
        (* node: const m = new Map([["x",1]]); m.get("x") === 1; m.get("nope") === undefined;
           m.has("x") === true; m.has("nope") === false; m.size === 1 *)
        let m = Js.Map.fromArray [| ("x", 1) |] in
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) (Some 1);
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"nope" m) None;
        assert_bool (Js.Map.has ~key:"x" m) true;
        assert_bool (Js.Map.has ~key:"nope" m) false;
        assert_int (Js.Map.size m) 1);
    test "set returns the map for chaining" (fun () ->
        (* node: const m = new Map(); m.set("a",1).set("b",2).set("c",3);
           JSON.stringify([...m]) === '[["a",1],["b",2],["c",3]]'; m.set("x",1) === m *)
        let m = Js.Map.make () in
        let returned =
          m |> Js.Map.set ~key:"a" ~value:1 |> Js.Map.set ~key:"b" ~value:2 |> Js.Map.set ~key:"c" ~value:3
        in
        assert_bool (returned == m) true;
        assert_int_entries (Js.Map.toArray m) [| ("a", 1); ("b", 2); ("c", 3) |]);
    test "re-set keeps position, updates value" (fun () ->
        (* node: const m = new Map(); m.set("a",1).set("b",2).set("c",3); m.set("a",10);
           JSON.stringify([...m.entries()]) === '[["a",10],["b",2],["c",3]]';
           JSON.stringify([...m.keys()]) === '["a","b","c"]';
           JSON.stringify([...m.values()]) === '[10,2,3]'; m.size === 3 *)
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("c", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:10 m in
        assert_int (Js.Map.size m) 3;
        assert_int_entries (Js.Iterator.toArray (Js.Map.entries m)) [| ("a", 10); ("b", 2); ("c", 3) |];
        assert_string_array (Js.Iterator.toArray (Js.Map.keys m)) [| "a"; "b"; "c" |];
        assert_int_array (Js.Iterator.toArray (Js.Map.values m)) [| 10; 2; 3 |]);
    test "delete then re-add moves key to the end" (fun () ->
        (* node: const m = new Map([["a",10],["b",2],["c",3]]); m.delete("b"); m.set("b",20);
           JSON.stringify([...m.keys()]) === '["a","c","b"]';
           JSON.stringify([...m.values()]) === '[10,3,20]' *)
        let m = Js.Map.fromArray [| ("a", 10); ("b", 2); ("c", 3) |] in
        assert_bool (Js.Map.delete ~key:"b" m) true;
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"b" ~value:20 m in
        assert_string_array (Js.Iterator.toArray (Js.Map.keys m)) [| "a"; "c"; "b" |];
        assert_int_array (Js.Iterator.toArray (Js.Map.values m)) [| 10; 3; 20 |]);
    test "delete returns whether the key was present" (fun () ->
        (* node: const m = new Map([["x",1]]); m.delete("x") === true; m.delete("nope") === false;
           m.size === 0; m.get("x") === undefined *)
        let m = Js.Map.fromArray [| ("x", 1) |] in
        assert_bool (Js.Map.delete ~key:"x" m) true;
        assert_bool (Js.Map.delete ~key:"nope" m) false;
        assert_int (Js.Map.size m) 0;
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) None);
    test "fromArray dedup: last value wins, first position kept" (fun () ->
        (* node: JSON.stringify([...new Map([["b",1],["a",2],["b",3]])]) === '[["b",3],["a",2]]' *)
        let m = Js.Map.fromArray [| ("b", 1); ("a", 2); ("b", 3) |] in
        assert_int (Js.Map.size m) 2;
        assert_int_entries (Js.Map.toArray m) [| ("b", 3); ("a", 2) |]);
    test "toArray follows insertion order" (fun () ->
        (* node: const m = new Map([["a",1],["b",2],["a",3]]); m.set("c",4); m.set("a",9);
           JSON.stringify(Array.from(m)) === '[["a",9],["b",2],["c",4]]' *)
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("a", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"c" ~value:4 m in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:9 m in
        assert_int_entries (Js.Map.toArray m) [| ("a", 9); ("b", 2); ("c", 4) |]);
    test "forEach passes value then key, in insertion order" (fun () ->
        (* node: const m = new Map([["a",1],["b",2],["a",3]]); m.set("c",4); m.delete("a"); m.set("a",5);
           let acc = []; m.forEach((v,k)=>acc.push([k,v]));
           JSON.stringify(acc) === '[["b",2],["c",4],["a",5]]' *)
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("a", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"c" ~value:4 m in
        let (_ : bool) = Js.Map.delete ~key:"a" m in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:5 m in
        let acc = ref [] in
        Js.Map.forEach ~f:(fun value key (_ : (string, int) Js.Map.t) -> acc := (key, value) :: !acc) m;
        assert_int_entries (Stdlib.Array.of_list (Stdlib.List.rev !acc)) [| ("b", 2); ("c", 4); ("a", 5) |]);
    test "forEach receives the map itself" (fun () ->
        (* node: const m = new Map([["x",1]]); m.forEach((v,k,map)=>{ if (map !== m) throw "no" }) *)
        let m = Js.Map.fromArray [| ("x", 1) |] in
        Js.Map.forEach ~f:(fun _value _key map -> assert_bool (map == m) true) m);
    test "clear empties the map" (fun () ->
        (* node: const m = new Map([["x",1],["y",2]]); m.clear();
           m.size === 0; JSON.stringify([...m]) === "[]"; m.get("x") === undefined *)
        let m = Js.Map.fromArray [| ("x", 1); ("y", 2) |] in
        Js.Map.clear m;
        assert_int (Js.Map.size m) 0;
        assert_int_entries (Js.Map.toArray m) [||];
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) None);
    test "set works after clear" (fun () ->
        (* node: const m = new Map([["x",1]]); m.clear(); m.set("y",2);
           JSON.stringify([...m]) === '[["y",2]]' *)
        let m = Js.Map.fromArray [| ("x", 1) |] in
        Js.Map.clear m;
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"y" ~value:2 m in
        assert_int_entries (Js.Map.toArray m) [| ("y", 2) |]);
    test "keys/values/entries iterators support next" (fun () ->
        (* node: const it = new Map([["a",1]]).keys();
           it.next() deep-equals { value: "a", done: false }; it.next() deep-equals { value: undefined, done: true } *)
        let m = Js.Map.fromArray [| ("a", 1) |] in
        let it = Js.Map.keys m in
        let step = Js.Iterator.next it in
        assert_option Alcotest.string "should be equal" step.value (Some "a");
        assert_option Alcotest.bool "should be equal" step.done_ (Some false);
        let step = Js.Iterator.next it in
        assert_option Alcotest.string "should be equal" step.value None;
        assert_option Alcotest.bool "should be equal" step.done_ (Some true));
  ]

let set_tests =
  [
    test "make is empty" (fun () ->
        (* node: new Set().size === 0 *)
        let s : string Js.Set.t = Js.Set.make () in
        assert_int (Js.Set.size s) 0;
        assert_string_array (Js.Set.toArray s) [||]);
    test "add / has / size" (fun () ->
        (* node: const s = new Set(); s.add("a"); s.has("a") === true; s.has("b") === false; s.size === 1 *)
        let s = Js.Set.make () in
        let (_ : string Js.Set.t) = Js.Set.add ~value:"a" s in
        assert_bool (Js.Set.has ~value:"a" s) true;
        assert_bool (Js.Set.has ~value:"b" s) false;
        assert_int (Js.Set.size s) 1);
    test "add returns the set for chaining" (fun () ->
        (* node: const s = new Set(); s.add(1).add(2).add(3); JSON.stringify([...s]) === "[1,2,3]"; s.add(9) === s *)
        let s = Js.Set.make () in
        let returned = s |> Js.Set.add ~value:1 |> Js.Set.add ~value:2 |> Js.Set.add ~value:3 in
        assert_bool (returned == s) true;
        assert_int_array (Js.Set.toArray s) [| 1; 2; 3 |]);
    test "add dedup keeps original position" (fun () ->
        (* node: const s = new Set(); s.add(1).add(2).add(3); s.add(1);
           JSON.stringify([...s]) === "[1,2,3]"; s.size === 3 *)
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        let (_ : int Js.Set.t) = Js.Set.add ~value:1 s in
        assert_int (Js.Set.size s) 3;
        assert_int_array (Js.Set.toArray s) [| 1; 2; 3 |]);
    test "fromArray dedup keeps first position" (fun () ->
        (* node: JSON.stringify([...new Set(["b","a","b","c","a"])]) === '["b","a","c"]' *)
        let s = Js.Set.fromArray [| "b"; "a"; "b"; "c"; "a" |] in
        assert_int (Js.Set.size s) 3;
        assert_string_array (Js.Set.toArray s) [| "b"; "a"; "c" |]);
    test "delete returns whether the value was present" (fun () ->
        (* node: const s = new Set([1,3]); s.delete(3) === true; s.delete(99) === false; s.size === 1 *)
        let s = Js.Set.fromArray [| 1; 3 |] in
        assert_bool (Js.Set.delete ~value:3 s) true;
        assert_bool (Js.Set.delete ~value:99 s) false;
        assert_int (Js.Set.size s) 1);
    test "delete then re-add moves value to the end" (fun () ->
        (* node: const s = new Set([1,2,3]); s.delete(2); s.add(2); JSON.stringify([...s]) === "[1,3,2]" *)
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        assert_bool (Js.Set.delete ~value:2 s) true;
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        assert_int_array (Js.Set.toArray s) [| 1; 3; 2 |]);
    test "forEach follows insertion order" (fun () ->
        (* node: const s = new Set([1,2,3]); s.delete(2); s.add(2);
           let acc = []; s.forEach(v=>acc.push(v)); JSON.stringify(acc) === "[1,3,2]" *)
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        let (_ : bool) = Js.Set.delete ~value:2 s in
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        let acc = ref [] in
        Js.Set.forEach ~f:(fun v -> acc := v :: !acc) s;
        assert_int_array (Stdlib.Array.of_list (Stdlib.List.rev !acc)) [| 1; 3; 2 |]);
    test "values iterator follows insertion order" (fun () ->
        (* node: JSON.stringify([...new Set(["b","a","c"]).values()]) === '["b","a","c"]' *)
        let s = Js.Set.fromArray [| "b"; "a"; "c" |] in
        assert_string_array (Js.Iterator.toArray (Js.Set.values s)) [| "b"; "a"; "c" |]);
    test "entries yields (value, value) pairs" (fun () ->
        (* node: JSON.stringify([...new Set(["x","y"]).entries()]) === '[["x","x"],["y","y"]]' *)
        let s = Js.Set.fromArray [| "x"; "y" |] in
        assert_string_pair_array (Js.Iterator.toArray (Js.Set.entries s)) [| ("x", "x"); ("y", "y") |]);
    test "clear empties the set" (fun () ->
        (* node: const s = new Set([1,2]); s.clear(); s.size === 0; JSON.stringify([...s]) === "[]";
           s.has(1) === false *)
        let s = Js.Set.fromArray [| 1; 2 |] in
        Js.Set.clear s;
        assert_int (Js.Set.size s) 0;
        assert_int_array (Js.Set.toArray s) [||];
        assert_bool (Js.Set.has ~value:1 s) false);
    test "add works after clear" (fun () ->
        (* node: const s = new Set([1]); s.clear(); s.add(2); JSON.stringify([...s]) === "[2]" *)
        let s = Js.Set.fromArray [| 1 |] in
        Js.Set.clear s;
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        assert_int_array (Js.Set.toArray s) [| 2 |]);
  ]

let tests = map_tests @ set_tests
