open Alcotest

let make_cases (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () -> (check string) "should be equal" expected (Css.Hash.make input) )

let data =
  [ ("david", "css-60843658")
  ; ("something ", "css-2100439605")
  ; ("display: block", "css-896256303")
  ; ("display: block;", "css-738546387")
  ; ("display: flex", "css-1823448902")
  ; ("display: flex; font-size: 33px", "css-190878179")
  ]

let tests = ("Hash", List.map make_cases data)
