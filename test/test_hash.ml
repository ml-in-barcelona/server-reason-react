open Alcotest

let check_equality (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () -> (check string) "should be equal" expected input )

let data =
  [ (* Ensure hashing is pure and equal *)
    (Css.Hash.make "david", Css.Hash.make "david")
  ; (Css.Hash.make "david", "css-10839m")
  ; (Css.Hash.make "something ", "css-yqjpkl")
  ; (Css.Hash.make "display: block", "css-etlvsf")
  ; (Css.Hash.make "display: block;", "css-c7pm1f")
  ; (Css.Hash.make "display: flex", "css-u5mu6e")
  ; (Css.Hash.make "display: flex; font-size: 33px", "css-35n6jn")
  ]

let tests = ("Hash", List.map check_equality data)
