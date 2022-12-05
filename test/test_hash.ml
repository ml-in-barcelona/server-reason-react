open Alcotest

let check_equality (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () -> (check string) "should be equal" expected input )

let data =
  [ (* Ensure hashing is pure and equal *)
    (Css.Hash.make "david", Css.Hash.make "david")
  ; (Css.Hash.make "david", "css-3a0668a")
  ; (Css.Hash.make "something ", "css-7d322a35")
  ; (Css.Hash.make "display: block", "css-356bc92f")
  ; (Css.Hash.make "display: block;", "css-2c0552d3")
  ; (Css.Hash.make "display: flex", "css-6caf9f46")
  ; (Css.Hash.make "display: flex; font-size: 33px", "css-b6091e3")
  ]

let tests = ("Hash", List.map check_equality data)
