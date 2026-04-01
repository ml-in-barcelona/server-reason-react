(* mlx desugaring places () before labeled args *)

let upper = Upper.createElement () [@JSX]
let upper_prop = Upper.createElement () ~count [@JSX]
let upper_children_single foo = Upper.createElement () ~children:[ foo ] [@JSX]
let upper_children_multiple foo bar = Upper.createElement () ~children:[ foo; bar ] [@JSX]
let upper_nested_module = Foo.Bar.createElement () ~a:1 ~b:"1" [@JSX]

let upper_all_kinds_of_props =
  MyComponent.createElement () ~booleanAttribute:true ~stringAttribute:"string" ~intAttribute:1
    ?forcedOptional:(Some "hello") ~onClick:(send handleClick)
    ~children:[ (React.createElement "div" [] [ "hello" ] [@JSX]) ] [@JSX]

(* Also test standard OCaml order: labeled args before unit *)
let upper_standard_order = Upper.createElement ~count () [@JSX]
