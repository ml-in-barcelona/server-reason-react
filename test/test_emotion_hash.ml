open Alcotest

let make_cases (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () ->
      (check string) "should be equal" expected (Emotion.Hash.make input) )

let data =
  [ ("something", "s153125035")
  ; ("something ", "s1285110230")
  ; ("display: block", "s1614261199")
  ; ("display: block;", "s362999430")
  ; ("display: flex", "s43767426")
  ; ("display: flex; font-size: 33", "s580161953")
  ]

let tests = ("Hash", List.map make_cases data)
