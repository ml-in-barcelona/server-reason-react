let quoted s = Printf.sprintf "\"%s\"" s

let check_equality (input, expected) =
  ( quoted input,
    `Quick,
    fun () ->
      (Alcotest.check Alcotest.string)
        (quoted input ^ " should hash")
        expected (Hash.make input) )

let data =
  [
    (* ("color: #323337", "fobhu4");
       ("color: #323335", "9we89e"); *)
    ("font-size: 32px;", "8ofgqt");
    ("font-size: 33px;", "8ofgqtx")
    (* ("something ", "c2ck6f");
       ("display: block", "pj97z6");
       ("display: blocki", "6t0coy");
       ("display: block;", "6t0coy");
       ("display: flex", "by7tbo");
       ("display: flex;", "rueolu");
       ("padding: 0px;", "dc8tgx");
       ("color: #333;", "hyb0ye");
       ("padding: 0;", "xakfz6");
       ("padding: 1;", "u8g46m");
       ("font-size: 22px;", "ummi9d");
       ("font-size: 40px;", "i97mpq");
       ("line-height: 33px;", "rga2o2");
       ("display: flex; font-size: 33px", "usohzx"); *);
  ]

let tests = ("Hash", List.map check_equality data)
