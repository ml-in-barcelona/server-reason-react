open Alcotest

let make_cases (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () ->
      (check string) "should be equal" expected (Emotion.Hash.make input) )

let data =
  [ ("david", "s1805074336826390618")
  ; ("something ", "s7698830768729985754")
  ; ("display: block", "s8509574055721759670")
  ; ("display: block;", "s8509574055721759670")
  ; ("display: flex", "s8509574055721759670")
  ; ("display: flex; font-size: 33px", "s6869457718971540809")
  ]

let tests = ("Hash", List.map make_cases data)
