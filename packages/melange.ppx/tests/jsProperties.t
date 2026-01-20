Basic jsProperties
  $ cat > input.ml << EOF
  > type person = { name: string; age: int } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; age : int } [@@deriving jsProperties]
  
  include struct
    let _ = fun (_ : person) -> ()
    let person ~name ~age = { name; age }
    let _ = person
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

jsProperties with @mel.optional
  $ cat > input.ml << EOF
  > type person = { name: string; age: int option [@mel.optional] } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; age : int option [@mel.optional] }
  [@@deriving jsProperties]
  
  include struct
    let _ = fun (_ : person) -> ()
    let person ~name ?age () = { name; age }
    let _ = person
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

jsProperties with multiple optional fields
  $ cat > input.ml << EOF
  > type config = { 
  >   host: string;
  >   port: int option [@mel.optional];
  >   debug: bool option [@mel.optional]
  > } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type config = {
    host : string;
    port : int option; [@mel.optional]
    debug : bool option; [@mel.optional]
  }
  [@@deriving jsProperties]
  
  include struct
    let _ = fun (_ : config) -> ()
    let config ~host ?port ?debug () = { host; port; debug }
    let _ = config
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Basic getSet
  $ cat > input.ml << EOF
  > type person = { name: string; age: int } [@@deriving getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; age : int } [@@deriving getSet]
  
  include struct
    let _ = fun (_ : person) -> ()
    let nameGet x = x.name
    let _ = nameGet
    let ageGet x = x.age
    let _ = ageGet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

getSet with mutable fields
  $ cat > input.ml << EOF
  > type person = { name: string; mutable age: int } [@@deriving getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; mutable age : int } [@@deriving getSet]
  
  include struct
    let _ = fun (_ : person) -> ()
    let nameGet x = x.name
    let _ = nameGet
    let ageGet x = x.age
    let _ = ageGet
    let ageSet x v = x.age <- v
    let _ = ageSet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

getSet with light mode
  $ cat > input.ml << EOF
  > type person = { name: string; mutable age: int } [@@deriving getSet { light }]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; mutable age : int } [@@deriving getSet { light }]
  
  include struct
    let _ = fun (_ : person) -> ()
    let name x = x.name
    let _ = name
    let age x = x.age
    let _ = age
    let ageSet x v = x.age <- v
    let _ = ageSet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Combined jsProperties and getSet
  $ cat > input.ml << EOF
  > type person = { name: string; mutable age: int } [@@deriving jsProperties, getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = { name : string; mutable age : int }
  [@@deriving jsProperties, getSet]
  
  include struct
    let _ = fun (_ : person) -> ()
    let person ~name ~age = { name; age }
    let _ = person
    let nameGet x = x.name
    let _ = nameGet
    let ageGet x = x.age
    let _ = ageGet
    let ageSet x v = x.age <- v
    let _ = ageSet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Combined jsProperties and getSet with optional and light
  $ cat > input.ml << EOF
  > type config = { 
  >   host: string;
  >   mutable port: int option [@mel.optional]
  > } [@@deriving jsProperties, getSet { light }]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type config = { host : string; mutable port : int option [@mel.optional] }
  [@@deriving jsProperties, getSet { light }]
  
  include struct
    let _ = fun (_ : config) -> ()
    let config ~host ?port () = { host; port }
    let _ = config
    let host x = x.host
    let _ = host
    let port x = x.port
    let _ = port
    let portSet x v = x.port <- v
    let _ = portSet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for jsProperties
  $ cat > input.mli << EOF
  > type person = { name: string; age: int } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type person = { name : string; age : int } [@@deriving jsProperties]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val person : name:string -> age:int -> person
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for jsProperties with optional
  $ cat > input.mli << EOF
  > type person = { name: string; age: int option [@mel.optional] } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type person = { name : string; age : int option [@mel.optional] }
  [@@deriving jsProperties]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val person : name:string -> ?age:int -> unit -> person
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for getSet
  $ cat > input.mli << EOF
  > type person = { name: string; mutable age: int } [@@deriving getSet]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type person = { name : string; mutable age : int } [@@deriving getSet]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val nameGet : person -> string
    val ageGet : person -> int
    val ageSet : person -> int -> unit
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for getSet with light mode
  $ cat > input.mli << EOF
  > type person = { name: string; mutable age: int } [@@deriving getSet { light }]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type person = { name : string; mutable age : int } [@@deriving getSet { light }]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val name : person -> string
    val age : person -> int
    val ageSet : person -> int -> unit
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for record with type parameter
  $ cat > input.mli << EOF
  > type 'a container = { value: 'a } [@@deriving jsProperties, getSet]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type 'a container = { value : 'a } [@@deriving jsProperties, getSet]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val container : value:'a -> 'a container
    val valueGet : 'a container -> 'a
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Error: jsProperties on variant type
  $ cat > input.ml << EOF
  > type action = Click | Submit [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 0-54:
  1 | type action = Click | Submit [@@deriving jsProperties]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@deriving jsProperties] can only be used on record types
  [1]

Error: getSet on variant type
  $ cat > input.ml << EOF
  > type action = Click | Submit [@@deriving getSet]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 0-48:
  1 | type action = Click | Submit [@@deriving getSet]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@deriving getSet] can only be used on record types
  [1]

Private types should not generate jsProperties constructor
  $ cat > input.ml << EOF
  > type person = private { name: string; age: int } [@@deriving jsProperties]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type person = private { name : string; age : int } [@@deriving jsProperties]
  
  include struct
    let _ = fun (_ : person) -> ()
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Single field record
  $ cat > input.ml << EOF
  > type single = { value: int } [@@deriving jsProperties, getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type single = { value : int } [@@deriving jsProperties, getSet]
  
  include struct
    let _ = fun (_ : single) -> ()
    let single ~value = { value }
    let _ = single
    let valueGet x = x.value
    let _ = valueGet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Record with type parameter
  $ cat > input.ml << EOF
  > type 'a container = { value: 'a } [@@deriving jsProperties, getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type 'a container = { value : 'a } [@@deriving jsProperties, getSet]
  
  include struct
    let _ = fun (_ : 'a container) -> ()
    let container ~value = { value }
    let _ = container
    let valueGet x = x.value
    let _ = valueGet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Mutually recursive types (generates shadowing bindings, matching melange behavior)
  $ cat > input.ml << EOF
  > type a = { x: int; b_ref: b option [@mel.optional] } [@@deriving jsProperties, getSet]
  > and b = { y: string; a_ref: a option [@mel.optional] } [@@deriving jsProperties, getSet]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type a = { x : int; b_ref : b option [@mel.optional] }
  [@@deriving jsProperties, getSet]
  
  and b = { y : string; a_ref : a option [@mel.optional] }
  [@@deriving jsProperties, getSet]
  
  include struct
    let _ = fun (_ : a) -> ()
    let _ = fun (_ : b) -> ()
    let a ~x ?b_ref () = { x; b_ref }
    let _ = a
    let b ~y ?a_ref () = { y; a_ref }
    let _ = b
    let xGet x = x.x
    let _ = xGet
    let b_refGet x = x.b_ref
    let _ = b_refGet
    let yGet x = x.y
    let _ = yGet
    let a_refGet x = x.a_ref
    let _ = a_refGet
    let a ~x ?b_ref () = { x; b_ref }
    let _ = a
    let b ~y ?a_ref () = { y; a_ref }
    let _ = b
    let xGet x = x.x
    let _ = xGet
    let b_refGet x = x.b_ref
    let _ = b_refGet
    let yGet x = x.y
    let _ = yGet
    let a_refGet x = x.a_ref
    let _ = a_refGet
  end [@@ocaml.doc "@inline"] [@@merlin.hide]
