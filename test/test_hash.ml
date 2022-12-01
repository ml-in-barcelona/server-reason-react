open Alcotest

let check_equality (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () -> (check string) "should be equal" expected input )

let data =
  [ (* Ensure hashing is pure and equal *)
    (Css.Hash.make "david", Css.Hash.make "david")
  ; (Css.Hash.make "david", "css-60843658")
  ; (Css.Hash.make "something ", "css-2100439605")
  ; (Css.Hash.make "display: block", "css-896256303")
  ; (Css.Hash.make "display: block;", "css-738546387")
  ; (Css.Hash.make "display: flex", "css-1823448902")
  ; (Css.Hash.make "display: flex; font-size: 33px", "css-190878179")
  ]

let tests = ("Hash", List.map check_equality data)
