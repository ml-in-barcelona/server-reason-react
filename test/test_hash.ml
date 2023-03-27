let check_equality (input, expected) =
  ( Printf.sprintf "\"%s\"" input
  , `Quick
  , fun () -> (Alcotest.check Alcotest.string) "should be equal" expected input
  )

let data =
  [ (* Ensure hashing is pure and equal *)
    (Hash.make "david", Hash.make "david")
  ; (Hash.make "david", "10839m")
  ; (Hash.make "something ", "yqjpkl")
  ; (Hash.make "display: block", "etlvsf")
  ; (Hash.make "display: block;", "c7pm1f")
  ; (Hash.make "display: flex", "u5mu6e")
  ; (Hash.make "display: flex;", "etlvsf")
  ; (Hash.make "display: flex; font-size: 33px", "35n6jn")
  ]

let tests = ("Hash", List.map check_equality data)
