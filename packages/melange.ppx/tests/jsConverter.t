Basic regular variant
  $ cat > input.ml << EOF
  > type action = Click | Submit | Cancel [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type action = Click | Submit | Cancel [@@deriving jsConverter]
  
  include struct
    let _ = fun (_ : action) -> ()
    let actionToJs x = match x with Click -> 0 | Submit -> 1 | Cancel -> 2
    let _ = actionToJs
    let actionFromJs x = match x with 0 -> Some Click | 1 -> Some Submit | 2 -> Some Cancel | _ -> None
    let _ = actionFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Regular variant with @mel.as
  $ cat > input.ml << EOF
  > type action = Click | Submit [@mel.as 3] | Cancel [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type action = Click | Submit [@mel.as 3] | Cancel [@@deriving jsConverter]
  
  include struct
    let _ = fun (_ : action) -> ()
    let actionToJs x = match x with Click -> 0 | Submit -> 3 | Cancel -> 4
    let _ = actionToJs
    let actionFromJs x = match x with 0 -> Some Click | 3 -> Some Submit | 4 -> Some Cancel | _ -> None
    let _ = actionFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Basic polymorphic variant
  $ cat > input.ml << EOF
  > type state = [\`Idle | \`Loading | \`Error] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type state = [ `Idle | `Loading | `Error ] [@@deriving jsConverter]
  
  include struct
    let _ = fun (_ : state) -> ()
    let stateToJs x = match x with `Idle -> "Idle" | `Loading -> "Loading" | `Error -> "Error"
    let _ = stateToJs
  
    let stateFromJs x =
      match x with "Idle" -> Some `Idle | "Loading" -> Some `Loading | "Error" -> Some `Error | _ -> None
  
    let _ = stateFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Polymorphic variant with @mel.as
  $ cat > input.ml << EOF
  > type state = [\`Idle | \`Loading [@mel.as "loading"] | \`Error] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type state = [ `Idle | `Loading [@mel.as "loading"] | `Error ] [@@deriving jsConverter]
  
  include struct
    let _ = fun (_ : state) -> ()
    let stateToJs x = match x with `Idle -> "Idle" | `Loading -> "loading" | `Error -> "Error"
    let _ = stateToJs
  
    let stateFromJs x =
      match x with "Idle" -> Some `Idle | "loading" -> Some `Loading | "Error" -> Some `Error | _ -> None
  
    let _ = stateFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Regular variant with newType
  $ cat > input.ml << EOF
  > type action = Click | Submit [@@deriving jsConverter { newType }]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type action = Click | Submit [@@deriving jsConverter { newType }]
  
  include struct
    let _ = fun (_ : action) -> ()
  
    type nonrec abs_action = int
  
    let actionToJs x = match x with Click -> 0 | Submit -> 1
    let _ = actionToJs
    let actionFromJs x = match x with 0 -> Click | 1 -> Submit
    let _ = actionFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Polymorphic variant with newType
  $ cat > input.ml << EOF
  > type state = [\`Idle | \`Loading] [@@deriving jsConverter { newType }]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type state = [ `Idle | `Loading ] [@@deriving jsConverter { newType }]
  
  include struct
    let _ = fun (_ : state) -> ()
  
    type nonrec abs_state = string
  
    let stateToJs x = match x with `Idle -> "Idle" | `Loading -> "Loading"
    let _ = stateToJs
    let stateFromJs x = match x with "Idle" -> `Idle | "Loading" -> `Loading
    let _ = stateFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Error: variant with payload
  $ cat > input.ml << EOF
  > type action = Click | Submit of int [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 20-35:
  1 | type action = Click | Submit of int [@@deriving jsConverter]
                          ^^^^^^^^^^^^^^^
  Error: [@@deriving jsConverter] does not support variant constructors with payloads

Error: polymorphic variant with payload
  $ cat > input.ml << EOF
  > type state = [\`Idle | \`Loading of int] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 22-37:
  1 | type state = [`Idle | `Loading of int] [@@deriving jsConverter]
                          ^^^^^^^^^^^^^^^
  Error: [@@deriving jsConverter] does not support polymorphic variant constructors with payloads

Signature generation for regular variant
  $ cat > input.mli << EOF
  > type action = Click | Submit | Cancel [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type action = Click | Submit | Cancel [@@deriving jsConverter]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val actionToJs : action -> int
    val actionFromJs : int -> action option
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation for polymorphic variant
  $ cat > input.mli << EOF
  > type state = [\`Idle | \`Loading] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type state = [ `Idle | `Loading ] [@@deriving jsConverter]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    val stateToJs : state -> string
    val stateFromJs : string -> state option
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Signature generation with newType
  $ cat > input.mli << EOF
  > type action = Click | Submit [@@deriving jsConverter { newType }]
  > EOF

  $ ./standalone.exe -intf input.mli | ocamlformat - --enable-outside-detected-project --intf
  type action = Click | Submit [@@deriving jsConverter { newType }]
  
  include sig
    [@@@ocaml.warning "-32"]
  
    type abs_action
  
    val actionToJs : action -> abs_action
    val actionFromJs : abs_action -> action
  end
  [@@ocaml.doc "@inline"] [@@merlin.hide]

Multiple type declarations with 'and'
  $ cat > input.ml << EOF
  > type a = A1 | A2
  > and b = B1 | B2 [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type a = A1 | A2
  and b = B1 | B2 [@@deriving jsConverter]
  
  include struct
    let _ = fun (_ : a) -> ()
    let _ = fun (_ : b) -> ()
    let aToJs x = match x with A1 -> 0 | A2 -> 1
    let _ = aToJs
    let aFromJs x = match x with 0 -> Some A1 | 1 -> Some A2 | _ -> None
    let _ = aFromJs
    let bToJs x = match x with B1 -> 0 | B2 -> 1
    let _ = bToJs
    let bFromJs x = match x with 0 -> Some B1 | 1 -> Some B2 | _ -> None
    let _ = bFromJs
  end [@@ocaml.doc "@inline"] [@@merlin.hide]

Error: empty variant
  $ cat > input.ml << EOF
  > type empty = | [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 0-39:
  1 | type empty = | [@@deriving jsConverter]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving jsConverter] cannot be used on empty variant types

Error: duplicate @mel.as values
  $ cat > input.ml << EOF
  > type dup = A [@mel.as 1] | B [@mel.as 1] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 0-65:
  1 | type dup = A [@mel.as 1] | B [@mel.as 1] [@@deriving jsConverter]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving jsConverter] has duplicate value 1 - each constructor must map to a unique integer

Error: open polymorphic variant
  $ cat > input.ml << EOF
  > type open_poly = [> \`A | \`B] [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 17-28:
  1 | type open_poly = [> `A | `B] [@@deriving jsConverter]
                       ^^^^^^^^^^^
  Error: [@@deriving jsConverter] does not support open polymorphic variants

Error: record type
  $ cat > input.ml << EOF
  > type person = { name: string; age: int } [@@deriving jsConverter]
  > EOF

  $ ./standalone.exe -impl input.ml 2>&1
  File "input.ml", line 1, characters 0-65:
  1 | type person = { name: string; age: int } [@@deriving jsConverter]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: [@@deriving jsConverter] only supports variant types and polymorphic variant types
