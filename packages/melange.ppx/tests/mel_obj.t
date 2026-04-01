Transform mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    let __js_obj_cell_0, __js_obj_entry_0 =
      Js.Obj.Internal.slot_ref ~method_name:"lola" ~js_name:"lola" ~present:true
        33
    in
    let __js_obj_cell_1, __js_obj_entry_1 =
      Js.Obj.Internal.slot_ref ~method_name:"cositas" ~js_name:"cositas"
        ~present:true "hola"
    in
    let __js_obj =
      object
        method lola = !__js_obj_cell_0
        method cositas = !__js_obj_cell_1
      end
    in
    Js.Obj.Internal.register_structural __js_obj
      [ __js_obj_entry_0; __js_obj_entry_1 ]

  $ cat > main.ml << EOF
  > module Js = struct
  >   module Obj = struct
  >     module Internal = struct
  >       type entry = unit
  >       let slot_ref ~method_name:_ ~js_name:_ ~present:_ value = (ref value, ())
  >       let register_structural obj _ = obj
  >     end
  >   end
  > end
  > EOF
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Transform nested mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = [%mel.obj { value = "hola" }]}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    let __js_obj_cell_0, __js_obj_entry_0 =
      Js.Obj.Internal.slot_ref ~method_name:"lola" ~js_name:"lola" ~present:true
        33
    in
    let __js_obj_cell_1, __js_obj_entry_1 =
      Js.Obj.Internal.slot_ref ~method_name:"cositas" ~js_name:"cositas"
        ~present:true
        (let __js_obj_cell_0, __js_obj_entry_0 =
           Js.Obj.Internal.slot_ref ~method_name:"value" ~js_name:"value"
             ~present:true "hola"
         in
         let __js_obj =
           object
             method value = !__js_obj_cell_0
           end
         in
         Js.Obj.Internal.register_structural __js_obj [ __js_obj_entry_0 ])
    in
    let __js_obj =
      object
        method lola = !__js_obj_cell_0
        method cositas = !__js_obj_cell_1
      end
    in
    Js.Obj.Internal.register_structural __js_obj
      [ __js_obj_entry_0; __js_obj_entry_1 ]

  $ cat > main.ml << EOF
  > module Js = struct
  >   module Obj = struct
  >     module Internal = struct
  >       type entry = unit
  >       let slot_ref ~method_name:_ ~js_name:_ ~present:_ value = (ref value, ())
  >       let register_structural obj _ = obj
  >     end
  >   end
  > end
  > EOF
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml


Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj "hola"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] Js.t objects requires a record literal"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] Js.t objects requires a record
         literal
  [2]

Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj { Lola.cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] Js.t objects only support labels as keys"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] Js.t objects only support labels as
         keys
  [2]
