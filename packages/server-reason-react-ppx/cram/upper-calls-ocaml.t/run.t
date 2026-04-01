Test uppercase component calls in OCaml syntax (mlx-style: unit before labeled args)

  $ ../standalone.exe --impl input.ml -o output.ml && ocamlformat --enable-outside-detected-project --impl output.ml
  let upper = Upper.make (Upper.makeProps ())
  let upper_prop = Upper.make (Upper.makeProps ~count ())
  let upper_children_single foo = Upper.make (Upper.makeProps ~children:foo ())
  
  let upper_children_multiple foo bar =
    Upper.make (Upper.makeProps ~children:(React.list [ foo; bar ]) ())
  
  let upper_nested_module = Foo.Bar.make (Foo.Bar.makeProps ~a:1 ~b:"1" ())
  
  let upper_all_kinds_of_props =
    MyComponent.make
      (MyComponent.makeProps
         ~children:(React.make (React.makeProps "div" [] [ "hello" ] ()))
         ~booleanAttribute:true ~stringAttribute:"string" ~intAttribute:1
         ?forcedOptional:(Some "hello") ~onClick:(send handleClick) ())
  
  let upper_standard_order = Upper.make (Upper.makeProps ~count ())
