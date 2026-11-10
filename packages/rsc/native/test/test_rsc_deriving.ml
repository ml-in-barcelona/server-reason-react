type v = A | B of int | C of { x : int; y : string } | D [@rsc.name "dee"] [@@deriving rsc]
type inner = [ `X | `Y of int ] [@@deriving rsc]
type outer = [ inner | `Z ] [@@deriving rsc]

let round_trip name of_rsc to_rsc values =
  Alcotest.test_case name `Quick (fun () ->
      List.iter (fun value -> Alcotest.(check bool) "round trip" true (of_rsc (to_rsc value) = value)) values)

let unknown name of_rsc =
  Alcotest.test_case name `Quick (fun () ->
      match of_rsc RSC.Primitives.(list_values_to_rsc [ string_to_rsc "nope" ]) with
      | _ -> Alcotest.fail "expected Of_rsc_error"
      | exception RSC.Of_rsc_error _ -> ())

let () =
  Alcotest.run "rsc deriving"
    [
      ( "variant",
        [
          round_trip "round trip" v_of_rsc v_to_rsc [ A; B 1; C { x = 2; y = "y" }; D ];
          Alcotest.test_case "renamed constructor" `Quick (fun () ->
              Alcotest.(check bool) "dee" true (v_of_rsc RSC.Primitives.(list_values_to_rsc [ string_to_rsc "dee" ]) = D));
          unknown "unknown tag" v_of_rsc;
        ] );
      ( "polyvariant",
        [
          round_trip "inner round trip" inner_of_rsc inner_to_rsc [ `X; `Y 3 ];
          round_trip "outer round trip" outer_of_rsc outer_to_rsc [ `X; `Y 4; `Z ];
          unknown "unknown tag" outer_of_rsc;
        ] );
    ]
