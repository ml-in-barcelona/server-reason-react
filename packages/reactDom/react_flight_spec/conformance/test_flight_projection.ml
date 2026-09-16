let equal expected native =
  Alcotest.check Alcotest.string "retained bytes" expected (Flight_projection.project_row native)

let rejected native =
  match Flight_projection.project_row native with
  | _ -> Alcotest.failf "accepted invalid native row %S" native
  | exception Invalid_argument message -> Alcotest.check Alcotest.bool "diagnostic" true (String.length message > 0)

let core ?(key = "null") ?(props = "{}") tag = Printf.sprintf {|["$",%s,%s,%s]|} tag key props

let extended ?(key = "null") ?(props = "{}") ?(suffix = "null,null,0") tag =
  Printf.sprintf {|["$",%s,%s,%s,%s]|} tag key props suffix

let states () =
  List.iter
    (fun state -> equal ("0:" ^ core {|"div"|}) ("0:" ^ extended ~suffix:("null,null," ^ state) {|"div"|}))
    [ "0"; "1"; "2" ]

let nested () =
  equal {|0:["$","div",null,{"children":[["$","span","a",{"children":"a"}],{"items":[["$","$L1",null,{}]]}]}]|}
    {|0:["$","div",null,{"children":[["$","span","a",{"children":"a"},null,null,0],{"items":[["$","$L1",null,{},null,null,2]]}]},null,null,1]|}

let strings_and_arrays () =
  List.iter
    (fun row -> equal row row)
    [
      {|0:"[\"$\",\"div\",null,{},null,null,1]"|};
      {|0:{"[\"$\",\"div\",null,{}]":"quote: \" backslash: \\"}|};
      {|0:["$$","div",null,{},null,null,1]|};
      {|0:["\u0024\u0024","div",null,{}]|};
      {|0:["$1","$L2","$@3",[1,2,3],[null,null,2]]|};
      {|0:[[],{},true,false,null,"$","$$"]|};
    ];
  equal {|0:["\u0024","span",null,{}]|} {|0:["\u0024","span",null,{},null,null,1]|};
  equal {|0:["$$",["$","span",null,{}]]|} {|0:["$$",["$","span",null,{},null,null,1]]|}

let retained_spelling () =
  equal
    {|aF: [ "$" , "\u0073pan" , "k\u0065y" , { "z":1.00e+02,"a":-0,"b":1E-9,"big":90071992547409931234567890,"text":"<\/script>\n\u0024" }  ]  |}
    {|aF: [ "$" , "\u0073pan" , "k\u0065y" , { "z":1.00e+02,"a":-0,"b":1E-9,"big":90071992547409931234567890,"text":"<\/script>\n\u0024" } , null , null , 2 ]  |}

let tagged_rows () =
  List.iter
    (fun row -> equal row row)
    [
      {|0:I["module.js",[],"default"]|};
      {|0:I["$",[],"default"]|};
      {|a:E{"digest":"123","stack":[["name","file",1,2]],"message":"[\"$\",\"div\",null,{}]"}|};
      {|:HL["/style.css","style",{"crossOrigin":"","priority":1.0}]|};
      {|:HL["$","style",{}]|};
      {|:HD"https://example.com"|};
      {|01:HC["https://example.com","anonymous"]|};
    ]

let suffixes () =
  List.iter
    (fun suffix -> rejected ("0:" ^ extended ~suffix {|"div"|}))
    [
      "null,null";
      "null,null,1,null";
      "\"$1\",null,1";
      "{},null,1";
      "null,[],1";
      "null,\"stack\",1";
      "null,null,-1";
      "null,null,3";
      "null,null,0.0";
      "null,null,2e0";
      "null,null,-0";
      "null,null,\"1\"";
      "null,null,true";
      "null,null,null";
      "null,null,[]";
    ];
  rejected ("0:" ^ core {|"div"|});
  rejected {|0:["$"]|};
  rejected {|0:["$","div",null,{},null]|};
  rejected {|0:{"items":[["$","div",null,{}]]}|}

let element_shapes () =
  List.iter (fun tag -> rejected ("0:" ^ extended tag)) [ "null"; "1"; "true"; "[]"; "{}"; {|""|} ];
  List.iter (fun key -> rejected ("0:" ^ extended ~key {|"div"|})) [ "0"; "false"; "[]"; "{}" ];
  List.iter (fun props -> rejected ("0:" ^ extended ~props {|"div"|})) [ "null"; "0"; "[]"; {|"$1"|} ];
  List.iter
    (fun tag -> equal ("0:" ^ core tag) ("0:" ^ extended tag))
    [ {|"div"|}; {|"$1"|}; {|"$L1"|}; {|"$Sreact.suspense"|} ]

let malformed_rows () =
  List.iter rejected
    [
      "";
      "[]";
      "0:";
      ":null";
      "xyz:null";
      "0:null null";
      "0:undefined";
      "0:NaN";
      "0:Infinity";
      "0:01";
      "0:1.";
      "0:1e+";
      "0:[1,]";
      {|0:{"a":1,}|};
      {|0:{a:1}|};
      {|0:["unterminated]|};
      "0:\"raw\nnewline\"";
      {|0:"\q"|};
      "0:I{}";
      "0:E[]";
      ":HZ[]";
      ":HL{}";
      ":H";
      "0:D{}";
    ]

let differences_remain_visible () =
  let fixture = "0:" ^ core ~key:{|"a"|} ~props:{|{"a":1,"b":2,"ref":"$1"}|} {|"div"|} in
  List.iter
    (fun native ->
      Alcotest.check Alcotest.bool "core difference retained" false (fixture = Flight_projection.project_row native))
    [
      "0:" ^ extended ~key:{|"b"|} ~props:{|{"a":1,"b":2,"ref":"$1"}|} {|"div"|};
      "0:" ^ extended ~key:{|"a"|} ~props:{|{"b":2,"a":1,"ref":"$1"}|} {|"div"|};
      "0:" ^ extended ~key:{|"a"|} ~props:{|{"a":1,"b":2,"ref":"$2"}|} {|"div"|};
      "0:" ^ extended ~key:{|"a"|} ~props:{|{"a":1.0,"b":2,"ref":"$1"}|} {|"div"|};
      "0:" ^ extended ~key:{|"a"|} ~props:{|{"a":1,"b":3,"ref":"$1"}|} {|"div"|};
    ];
  let rows = [ "0:" ^ extended {|"div"|}; "1:" ^ extended {|"span"|} ] in
  let projected = List.map Flight_projection.project_row rows in
  Alcotest.check (Alcotest.list Alcotest.string) "row IDs and order"
    [ "0:" ^ core {|"div"|}; "1:" ^ core {|"span"|} ]
    projected;
  Alcotest.check Alcotest.bool "reordered rows still differ" false
    (projected = List.map Flight_projection.project_row (List.rev rows))

let () =
  Alcotest.run "flight_projection"
    [
      ( "projection",
        List.map
          (fun (name, run) -> Alcotest.test_case name `Quick run)
          [
            ("all valid states", states);
            ("nested elements", nested);
            ("strings and ordinary arrays", strings_and_arrays);
            ("byte spelling and whitespace", retained_spelling);
            ("tagged rows", tagged_rows);
            ("invalid or missing suffix", suffixes);
            ("element shapes", element_shapes);
            ("malformed rows", malformed_rows);
            ("core and row differences", differences_remain_visible);
          ] );
    ]
