open Alcotest

let make_cases (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () ->
      (check string) "should be equal" expected (Emotion.Hash.make input) )

let data =
  [ ("something", "153125035")
  ; ("something ", "1285110230")
  ; ("display: block", "1614261199")
  ; ("display: block;", "362999430")
  ; ("display: flex", "43767426")
  ; ("display: flex; font-size: 33", "580161953")
  ]

let tests = ("Hash", List.map make_cases data)
