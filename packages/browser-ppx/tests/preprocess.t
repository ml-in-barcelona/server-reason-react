Nested

  $ cat > input.ml << EOF
  >  module X = struct
  >    include struct
  >    type t = Js.Json.t
  >    let a = 2 + 2
  >    end [@@platform js]
  >  
  >    include struct
  >      type t = Js.Json.t
  >      let a = 4 + 4
  >    end [@@platform native]
  >  end
  > EOF

With -js flag it picks the block with `[@@platform js]`

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = Js.Json.t
  end [@@platform js]

Without -js flag, it picks the block with `[@@platform native]`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = string
  end [@@platform native]

Pstr_include

  $ cat > input.ml << EOF
  > include struct
  >   type t = Js.Json.t
  > end [@@platform js]
  > 
  > include struct
  >   type t = string
  > end [@@platform native]
  > EOF

With -js flag it picks the block with `[@@platform js]`

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = Js.Json.t
  end [@@platform js]

Without -js flag, it picks the block with `[@@platform native]`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = string
  end [@@platform native]

Use only one of the platforms

  $ cat > input.ml << EOF
  > include struct
  >   type t = Js.Json.t
  > end [@@platform js]
  > 
  > include struct
  >   type t = string
  > end
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = string
  end

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = Js.Json.t
  end [@@platform js]
  
  include struct
    type t = string
  end

Pstr_module

  $ cat > input_module.ml << EOF
  > module M = struct
  >   let x = 42
  > end [@@platform js]
  > module M = struct
  >   let x = 44
  > end [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_module.ml | ocamlformat - --enable-outside-detected-project --impl
  module M = struct
    let x = 44
  end
  [@@platform native]

  $ ./standalone.exe -impl input_module.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module M = struct
    let x = 42
  end
  [@@platform js]

Pstr_value

  $ cat > input_let.ml << EOF
  > let x = 42 [@@platform js]
  > let y = 44 [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_let.ml | ocamlformat - --enable-outside-detected-project --impl
  let y = 44 [@@platform native]

  $ ./standalone.exe -impl input_let.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let x = 42 [@@platform js]

Pstr_open

  $ cat > input_open.ml << EOF
  > open Printf [@@platform js]
  > open List [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_open.ml | ocamlformat - --enable-outside-detected-project --impl
  open List [@@platform native]

  $ ./standalone.exe -impl input_open.ml -js | ocamlformat - --enable-outside-detected-project --impl
  open Printf [@@platform js]

Pstr_exception

  $ cat > input_exception.ml << EOF
  > exception MyException of string [@@platform js]
  > exception AnotherException of int [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_exception.ml | ocamlformat - --enable-outside-detected-project --impl
  exception AnotherException of int [@@platform native]

  $ ./standalone.exe -impl input_exception.ml -js | ocamlformat - --enable-outside-detected-project --impl
  exception MyException of string [@@platform js]

Pstr_primitive

  $ cat > input_primitive.ml << EOF
  > external add : int -> int -> int = "caml_add_int" [@@platform js]
  > external subtract : int -> int -> int = "caml_subtract_int" [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl
  external subtract : int -> int -> int = "caml_subtract_int" [@@platform native]

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  external add : int -> int -> int = "caml_add_int" [@@platform js]

Pstr_eval (doesn't work)

  $ cat > input_primitive.ml << EOF
  > include struct
  >   2 [@@platform js]
  > end
  > 
  > include struct
  >   3 [@@platform native]
  > end
  > EOF

  $ ./standalone.exe -impl input_primitive.ml | ocamlformat - --enable-outside-detected-project --impl
  include struct
    2 [@@platform js]
  end
  
  include struct
    3 [@@platform native]
  end

  $ ./standalone.exe -impl input_primitive.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    2 [@@platform js]
  end
  
  include struct
    3 [@@platform native]
  end

Pstr_type

  $ cat > input_type.ml << EOF
  > type point = { x : int; y : int } [@@platform js]
  > type color = Red | Green | Blue [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_type.ml | ocamlformat - --enable-outside-detected-project --impl
  type color = Red | Green | Blue [@@platform native]

  $ ./standalone.exe -impl input_type.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type point = { x : int; y : int } [@@platform js]

Pstr_recmodule

  $ cat > input_recmodule.ml << EOF
  > module rec M = struct
  >   let x = 42
  > end [@@platform js]
  > module rec M = struct
  >   let x = 44
  > end [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_recmodule.ml | ocamlformat - --enable-outside-detected-project --impl
  module rec M = struct
    let x = 44
  end
  [@@platform native]

  $ ./standalone.exe -impl input_recmodule.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module rec M = struct
    let x = 42
  end
  [@@platform js]

Pstr_class

  $ cat > input_class.ml << EOF
  > class virtual ['a] base x = object
  >   method get = x
  > end [@@platform js]
  > class derived = object
  >   inherit base 42
  > end [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_class.ml | ocamlformat - --enable-outside-detected-project --impl
  class derived =
    object
      inherit base 42
    end [@@platform native]

  $ ./standalone.exe -impl input_class.ml -js | ocamlformat - --enable-outside-detected-project --impl
  class virtual ['a] base x =
    object
      method get = x
    end [@@platform js]

Pstr_class_type

  $ cat > input_class_type.ml << EOF
  > class type base = object
  >   method get : int
  > end [@@platform js]
  > class type derived = object
  >   inherit base
  > end [@@platform native]
  > EOF

  $ ./standalone.exe -impl input_class_type.ml | ocamlformat - --enable-outside-detected-project --impl
  class type derived = object
    inherit base
  end [@@platform native]

  $ ./standalone.exe -impl input_class_type.ml -js | ocamlformat - --enable-outside-detected-project --impl
  class type base = object
    method get : int
  end [@@platform js]
