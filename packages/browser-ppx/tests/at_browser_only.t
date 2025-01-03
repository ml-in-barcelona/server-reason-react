Pstr_include

  $ cat > input_include.ml << EOF
  > include struct
  >   type t = Js.Json.t
  > end [@@browser_only]
  > EOF

With -js flag it picks the block with `[@@browser_only]`

  $ ./standalone.exe -impl input_include.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = Js.Json.t
  end [@@browser_only]

Without -js flag, it picks the block without `[@@browser_only]`

  $ ./standalone.exe -impl input_include.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_module

  $ cat > input_module.ml << EOF
  > module M = struct
  >   let x = 42
  > end [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_module.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_module.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module M = struct
    let x = 42
  end
  [@@browser_only]

Pstr_value

  $ cat > input_value.ml << EOF
  > let x = 42 [@@browser_only]
  > let y = 44 
  > EOF

  $ ./standalone.exe -impl input_value.ml | ocamlformat - --enable-outside-detected-project --impl
  let y = 44

  $ ./standalone.exe -impl input_value.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x = 42 [@@browser_only]
  let y = 44

Nested

  $ cat > input_nested.ml << EOF
  >  module X = struct
  >    module Y = struct
  >      type t = Js.Json.t
  >      let a = 4 + 4
  >    end [@@browser_only]
  >  end
  > EOF

With -js flag it picks the block with `[@@browser_only]`

  $ ./standalone.exe -impl input_nested.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module X = struct
    module Y = struct
      type t = Js.Json.t
  
      let a = 4 + 4
    end
    [@@browser_only]
  end

Without -js flag, it picks the block without `[@@browser_only]`

  $ ./standalone.exe -impl input_nested.ml | ocamlformat - --enable-outside-detected-project --impl
  module X = struct end

Pexp_apply

  $ cat > input_apply.ml << EOF
  > let x =
  >   print_endline "hello" [@browser_only];
  >   let y = 44  in
  >   y
  > EOF

  $ ./standalone.exe -impl input_apply.ml | ocamlformat - --enable-outside-detected-project --impl
  let x =
    ();
    let y = 44 in
    y

  $ ./standalone.exe -impl input_apply.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x =
    print_endline "hello" [@browser_only];
    let y = 44 in
    y

Pexp_let

  $ cat > input_let.ml << EOF
  > let x =
  >   let _ = 42 [@@browser_only] in
  >   let y = 44 in
  >   y
  > EOF

  $ ./standalone.exe -impl input_let.ml | ocamlformat - --enable-outside-detected-project --impl
  let x =
    let y = 44 in
    y

  $ ./standalone.exe -impl input_let.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x =
    let _ = 42 [@@browser_only] in
    let y = 44 in
    y

Ppat_tuple

  $ cat > input_tuple.ml << EOF
  > let (x, y [@browser_only]) = (42, 44)
  > EOF

  $ ./standalone.exe -impl input_tuple.ml | ocamlformat - --enable-outside-detected-project --impl
  let x, _ = (42, 44)

  $ ./standalone.exe -impl input_tuple.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x, (y [@browser_only]) = (42, 44)

Pexp_apply

  $ cat > input_apply.ml << EOF
  > foo ((pexp_ident_var) [@browser_only]) ((42) [@browser_only]) ((fun () -> ())[@browser_only]) 24
  > EOF

  $ ./standalone.exe -impl input_apply.ml | ocamlformat - --enable-outside-detected-project --impl
  foo () () () 24

  $ ./standalone.exe -impl input_apply.ml -js | ocamlformat - --enable-outside-detected-project --impl
  foo (pexp_ident_var [@browser_only]) (42 [@browser_only])
    (fun [@browser_only] () -> ())
    24

Ppat_var

  $ cat > input_var.ml << EOF
  > let x (onClick [@browser_only]) = 24
  > let y ~onClick:(onClick [@browser_only]) = 42
  > EOF

  $ ./standalone.exe -impl input_var.ml | ocamlformat - --enable-outside-detected-project --impl
  let x _ = 24
  let y ~onClick:_ = 42

  $ ./standalone.exe -impl input_var.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x (onClick [@browser_only]) = 24
  let y ~onClick:(onClick [@browser_only]) = 42

Pstr_open

  $ cat > input_open.ml << EOF
  > open Printf [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_open.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_open.ml -js | ocamlformat - --enable-outside-detected-project --impl
  open Printf [@@browser_only]

Pstr_exception

  $ cat > input_exception.ml << EOF
  > exception MyException of string [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_exception.ml -js | ocamlformat - --enable-outside-detected-project --impl
  exception MyException of string [@@browser_only]

  $ ./standalone.exe -impl input_exception.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_primitive

  $ cat > input_primitive.ml << EOF
  > external add : int -> int -> int = "caml_add_int" [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  external add : int -> int -> int = "caml_add_int" [@@browser_only]

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_eval

  $ cat > input_primitive.ml << EOF
  > 2 [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  2 [@@browser_only]

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_type

  $ cat > input_type.ml << EOF
  > type point = { x : int; y : int } [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_type.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type point = { x : int; y : int } [@@browser_only]

  $ ./standalone.exe -impl input_type.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_recmodule

  $ cat > input_recmodule.ml << EOF
  > module rec M = struct
  >   let x = 42
  > end [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_recmodule.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module rec M = struct
    let x = 42
  end
  [@@browser_only]

  $ ./standalone.exe -impl input_recmodule.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_class

  $ cat > input_class.ml << EOF
  > class virtual ['a] base x = object
  >   method get = x
  > end [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_class.ml -js | ocamlformat - --enable-outside-detected-project --impl
  class virtual ['a] base x =
    object
      method get = x
    end [@@browser_only]

  $ ./standalone.exe -impl input_class.ml | ocamlformat - --enable-outside-detected-project --impl

Pstr_class_type

  $ cat > input_class_type.ml << EOF
  > class type base = object
  >   method get : int
  > end [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_class_type.ml -js | ocamlformat - --enable-outside-detected-project --impl
  class type base = object
    method get : int
  end [@@browser_only]

  $ ./standalone.exe -impl input_class_type.ml | ocamlformat - --enable-outside-detected-project --impl

Ppat_constraint

  $ cat > input_constr.ml << EOF
  > let foo ~on:((on [@browser_only]): unit -> string) ?opt:((opt [@browser_only])=42) = 0
  > EOF

  $ ./standalone.exe -impl input_constr.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let foo ~on:((on [@browser_only]) : unit -> string)
      ?opt:((opt [@browser_only]) = 42) =
    0
 
  $ ./standalone.exe -impl input_constr.ml | ocamlformat - --enable-outside-detected-project --impl
  let foo ~on:_ ?opt:(_ = 42) = 0

Core_type

  $ cat > input_constr.ml << EOF
  > type t = int [@browser_only]
  > type u = { x : (bool [@browser_only]) }
  > type toggleButtonFields =
  >   {
  >     isOpen: bool ;
  >     domRef: RRef.domRef option ;
  >     onClick: ((React.Event.Mouse.t -> unit)[@browser_only]);
  >     onKeyDown: (((React.Event.Keyboard.t -> unit) option)[@browser_only]) 
  >   }
  > 
  > let foo = {
  >   isOpen = true;
  >   domRef = None;
  >   onClick = (fun _ -> ())[@browser_only];
  >   onKeyDown = None;
  > }
  > EOF

  $ ./standalone.exe -impl input_constr.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type t = (int[@browser_only])
  type u = { x : (bool[@browser_only]) }
  
  type toggleButtonFields = {
    isOpen : bool;
    domRef : RRef.domRef option;
    onClick : (React.Event.Mouse.t -> unit[@browser_only]);
    onKeyDown : ((React.Event.Keyboard.t -> unit) option[@browser_only]);
  }
  
  let foo =
    {
      isOpen = true;
      domRef = None;
      onClick = (fun [@browser_only] _ -> ());
      onKeyDown = None;
    }
 

  $ ./standalone.exe -impl input_constr.ml | ocamlformat - --enable-outside-detected-project --impl
  type t = unit
  type u = { x : unit }
  
  type toggleButtonFields = {
    isOpen : bool;
    domRef : RRef.domRef option;
    onClick : unit;
    onKeyDown : unit;
  }
  
  let foo = { isOpen = true; domRef = None; onClick = (); onKeyDown = None }

