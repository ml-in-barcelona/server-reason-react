open Helpers

let equal_same () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 42 in
  assert_bool (BigInt.equal a b) true

let equal_different () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 43 in
  assert_bool (BigInt.equal a b) false

let equal_negative () =
  let a = BigInt.of_int (-42) in
  let b = BigInt.of_int (-42) in
  assert_bool (BigInt.equal a b) true

let equal_opposite_sign () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int (-42) in
  assert_bool (BigInt.equal a b) false

let equal_zero () =
  let a = BigInt.of_int 0 in
  let b = BigInt.of_int 0 in
  assert_bool (BigInt.equal a b) true

let equal_large () =
  let a = BigInt.of_string "515377520732011331036461129765621272702107522001" in
  let b = BigInt.of_string "515377520732011331036461129765621272702107522001" in
  assert_bool (BigInt.equal a b) true

let equal_large_different () =
  let a = BigInt.of_string "515377520732011331036461129765621272702107522001" in
  let b = BigInt.of_string "515377520732011331036461129765621272702107522000" in
  assert_bool (BigInt.equal a b) false

let compare_less () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 3 in
  assert_int (BigInt.compare a b) (-1)

let compare_greater () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 2 in
  assert_int (BigInt.compare a b) 1

let compare_equal () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 3 in
  assert_int (BigInt.compare a b) 0

let compare_negative () =
  let a = BigInt.of_int (-5) in
  let b = BigInt.of_int (-3) in
  assert_int (BigInt.compare a b) (-1)

let compare_mixed_sign () =
  let a = BigInt.of_int (-1) in
  let b = BigInt.of_int 1 in
  assert_int (BigInt.compare a b) (-1)

let lt_true () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.lt a b) true

let lt_false_greater () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 2 in
  assert_bool (BigInt.lt a b) false

let lt_false_equal () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.lt a b) false

let lt_negative () =
  let a = BigInt.of_int (-5) in
  let b = BigInt.of_int (-3) in
  assert_bool (BigInt.lt a b) true

let le_true_less () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.le a b) true

let le_true_equal () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.le a b) true

let le_false () =
  let a = BigInt.of_int 4 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.le a b) false

let gt_true () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 2 in
  assert_bool (BigInt.gt a b) true

let gt_false_less () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.gt a b) false

let gt_false_equal () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.gt a b) false

let ge_true_greater () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 2 in
  assert_bool (BigInt.ge a b) true

let ge_true_equal () =
  let a = BigInt.of_int 3 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.ge a b) true

let ge_false () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 3 in
  assert_bool (BigInt.ge a b) false

let tests =
  [
    test "equal: same value" equal_same;
    test "equal: different values" equal_different;
    test "equal: negative values" equal_negative;
    test "equal: opposite signs" equal_opposite_sign;
    test "equal: zeros" equal_zero;
    test "equal: large same" equal_large;
    test "equal: large different" equal_large_different;
    test "compare: less" compare_less;
    test "compare: greater" compare_greater;
    test "compare: equal" compare_equal;
    test "compare: negative" compare_negative;
    test "compare: mixed sign" compare_mixed_sign;
    test "lt: true" lt_true;
    test "lt: false (greater)" lt_false_greater;
    test "lt: false (equal)" lt_false_equal;
    test "lt: negative" lt_negative;
    test "le: true (less)" le_true_less;
    test "le: true (equal)" le_true_equal;
    test "le: false" le_false;
    test "gt: true" gt_true;
    test "gt: false (less)" gt_false_less;
    test "gt: false (equal)" gt_false_equal;
    test "ge: true (greater)" ge_true_greater;
    test "ge: true (equal)" ge_true_equal;
    test "ge: false" ge_false;
  ]
