  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let basic = Js.Re.fromString "foo"
  let flag_global = Js.Re.fromStringWithFlags ~flags:"g" "foo"
  
  let flags_global_multiline_insensitive =
    Js.Re.fromStringWithFlags ~flags:"gim" "foo"
  
  let scape_digis_with_global = Js.Re.fromStringWithFlags ~flags:"g" "(\\d+)"
  
  let payload_should_be_a_string =
    [%ocaml.error "payload should be a string literal"]
