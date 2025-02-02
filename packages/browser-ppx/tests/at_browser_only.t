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
    let y = 44 in
    y

  $ ./standalone.exe -impl input_apply.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x =
    print_endline "hello" [@browser_only];
    let y = 44 in
    y

  $ ./standalone.exe -impl input_apply.ml > input_apply_server.ml && ocamlc -c input_apply_server.ml

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

  $ ./standalone.exe -impl input_let.ml > input_let_server.ml && ocamlc -c input_let_server.ml

Ppat_tuple

  $ cat > input_tuple.ml << EOF
  > let (x, y [@browser_only]) = (42, 44)
  > EOF

  $ ./standalone.exe -impl input_tuple.ml | ocamlformat - --enable-outside-detected-project --impl
  let x, _ = (42, 44)

  $ ./standalone.exe -impl input_tuple.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x, (y [@browser_only]) = (42, 44)

  $ ./standalone.exe -impl input_let.ml > input_let_server.ml && ocamlc -c input_let_server.ml

Pexp_apply

  $ cat > input_apply.ml << EOF
  > let foo (_: int) (_: int) (_: (unit -> unit) [@browser_only]) (_: int) = ()
  > let _ = foo ((24) [@browser_only]) ((42) [@browser_only]) ((fun () -> ())[@browser_only]) 24
  > EOF

  $ ./standalone.exe -impl input_apply.ml | ocamlformat - --enable-outside-detected-project --impl
  let foo (_ : int) (_ : int) (_ : Obj.t) (_ : int) = ()
  let _ = foo (Obj.magic ()) (Obj.magic ()) (Obj.magic ()) 24

  $ ./standalone.exe -impl input_apply.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let foo (_ : int) (_ : int) (_ : (unit -> unit[@browser_only])) (_ : int) = ()
  
  let _ =
    foo (24 [@browser_only]) (42 [@browser_only])
      (fun [@browser_only] () -> ())
      24

  $ ./standalone.exe -impl input_apply.ml > input_apply_server.ml && ocamlc -c input_apply_server.ml

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

  $ ./standalone.exe -impl input_var.ml > input_var_server.ml && ocamlc -c input_var_server.ml

Pstr_open

  $ cat > input_open.ml << EOF
  > open Printf [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_open.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_open.ml -js | ocamlformat - --enable-outside-detected-project --impl
  open Printf [@@browser_only]

  $ ./standalone.exe -impl input_open.ml > input_open_server.ml && ocamlc -c input_open_server.ml

Pstr_exception

  $ cat > input_exception.ml << EOF
  > exception MyException of string [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_exception.ml -js | ocamlformat - --enable-outside-detected-project --impl
  exception MyException of string [@@browser_only]

  $ ./standalone.exe -impl input_exception.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_exception.ml > input_exception_server.ml && ocamlc -c input_exception_server.ml

Pstr_primitive

  $ cat > input_primitive.ml << EOF
  > external add : int -> int -> int = "caml_add_int" [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  external add : int -> int -> int = "caml_add_int" [@@browser_only]

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_primitive.ml > input_primitive_server.ml && ocamlc -c input_primitive_server.ml

Pstr_eval

  $ cat > input_primitive.ml << EOF
  > 2 [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  2 [@@browser_only]

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_primitive.ml > input_primitive_server.ml && ocamlc -c input_primitive_server.ml

Pstr_type

  $ cat > input_type.ml << EOF
  > type point = { x : int; y : int } [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input_type.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type point = { x : int; y : int } [@@browser_only]

  $ ./standalone.exe -impl input_type.ml | ocamlformat - --enable-outside-detected-project --impl

  $ ./standalone.exe -impl input_type.ml > input_type_server.ml && ocamlc -c input_type_server.ml

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

  $ ./standalone.exe -impl input_class_type.ml > input_class_type_server.ml && ocamlc -c input_class_type_server.ml

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
  >     x: bool;
  >     y: (unit -> unit[@browser_only]);
  >     z: ((unit -> unit) option[@browser_only]);
  >   }
  > 
  > let foo = {
  >   x = true;
  >   y = (fun _ -> ())[@browser_only];
  >   z = (None[@browser_only])
  > }
  > 
  > let bar = if foo.x then (1 [@browser_only]) else 2
  > EOF

  $ ./standalone.exe -impl input_constr.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type t = (int[@browser_only])
  type u = { x : (bool[@browser_only]) }
  
  type toggleButtonFields = {
    x : bool;
    y : (unit -> unit[@browser_only]);
    z : ((unit -> unit) option[@browser_only]);
  }
  
  let foo =
    { x = true; y = (fun [@browser_only] _ -> ()); z = None [@browser_only] }
  
  let bar = if foo.x then (1 [@browser_only]) else 2

  $ ./standalone.exe -impl input_constr.ml | ocamlformat - --enable-outside-detected-project --impl
  type t = Obj.t
  type u = { x : Obj.t }
  type toggleButtonFields = { x : bool; y : Obj.t; z : Obj.t }
  
  let foo = { x = true; y = Obj.magic (); z = Obj.magic () }
  let bar = if foo.x then Obj.magic () else 2

  $ ./standalone.exe -impl input_constr.ml > input_constr_server.ml && ocamlc -c input_constr_server.ml

Core_type error

  $ cat > input_constr.ml << EOF
  > type t = int [@browser_only]
  > let bar: t = if true then (1 [@browser_only]) else 2
  > EOF

  $ ./standalone.exe -impl input_constr.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type t = (int[@browser_only])
  
  let bar : t = if true then (1 [@browser_only]) else 2

  $ ./standalone.exe -impl input_constr.ml | ocamlformat - --enable-outside-detected-project --impl
  type t = Obj.t
  
  let bar : t = if true then Obj.magic () else 2

  $ ./standalone.exe -impl input_constr.ml > input_constr_server.ml && ocamlc -c input_constr_server.ml
  File "input_constr_server.ml", line 2, characters 45-46:
  2 | let bar : t = if true then Obj.magic () else 2
                                                   ^
  Error: This expression has type int but an expression was expected of type
           t = Obj.t
  [2]

If the else

  $ cat > input_constr.ml << EOF
  > let foo = if true then (42 [@browser_only]) else 24
  > EOF

  $ ./standalone.exe -impl input_constr.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let foo = if true then (42 [@browser_only]) else 24

  $ ./standalone.exe -impl input_constr.ml | ocamlformat - --enable-outside-detected-project --impl
  let foo = if true then Obj.magic () else 24

  $ ./standalone.exe -impl input_constr.ml > input_constr_server.ml && ocamlc -c input_constr_server.ml

Pexp_match

  $ cat > input_match.ml << EOF
  > let x = 2
  > let foo = match x with
  >   | 1 -> "1"
  >   | 2 -> "2" [@browser_only]
  >   | _ -> "0"
  > EOF

  $ ./standalone.exe -impl input_match.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x = 2
  let foo = match x with 1 -> "1" | 2 -> ("2" [@browser_only]) | _ -> "0"

  $ ./standalone.exe -impl input_match.ml | ocamlformat - --enable-outside-detected-project --impl
  let x = 2
  let foo = match x with 1 -> "1" | 2 -> Obj.magic () | _ -> "0"

  $ ./standalone.exe -impl input_match.ml | ocamlc -c input_match.ml

Pexp_match

  $ cat > input_match.ml << EOF
  > let x = 2
  > let foo = match x with
  >   | 1 -> "1"
  >   | 2 -> "2" [@browser_only]
  >   | 3 -> "3" [@browser_only]
  >   | _ -> "0"
  > EOF

  $ ./standalone.exe -impl input_match.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x = 2
  
  let foo =
    match x with
    | 1 -> "1"
    | 2 -> ("2" [@browser_only])
    | 3 -> ("3" [@browser_only])
    | _ -> "0"

  $ ./standalone.exe -impl input_match.ml | ocamlformat - --enable-outside-detected-project --impl
  let x = 2
  
  let foo =
    match x with 1 -> "1" | 2 -> Obj.magic () | 3 -> Obj.magic () | _ -> "0"

  $ ./standalone.exe -impl input_match.ml | ocamlc -c input_match.ml
