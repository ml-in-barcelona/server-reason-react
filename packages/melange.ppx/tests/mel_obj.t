Transform mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    let __js_obj_cell_0 = Stdlib.ref 33 in
    let __js_obj_cell_1 = Stdlib.ref "hola" in
    let __js_obj =
      object
        method lola = !__js_obj_cell_0
        method cositas = !__js_obj_cell_1
      end
    in
    Js.Obj.Internal.register_deferred __js_obj (fun () ->
        [
          Js.Obj.Internal.deferred_entry ~method_name:"lola" ~js_name:"lola"
            ~present:true __js_obj_cell_0;
          Js.Obj.Internal.deferred_entry ~method_name:"cositas" ~js_name:"cositas"
            ~present:true __js_obj_cell_1;
        ])

  $ cat > main.ml << EOF
  > module Js = struct
  >   module Obj = struct
  >     module Internal = struct
  >       type entry = unit
  >       let deferred_entry ~method_name:_ ~js_name:_ ~present:_ _cell = ()
  >       let register_deferred obj (_ : unit -> entry list) = obj
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
    let __js_obj_cell_0 = Stdlib.ref 33 in
    let __js_obj_cell_1 =
      Stdlib.ref
        (let __js_obj_cell_0 = Stdlib.ref "hola" in
         let __js_obj =
           object
             method value = !__js_obj_cell_0
           end
         in
         Js.Obj.Internal.register_deferred __js_obj (fun () ->
             [
               Js.Obj.Internal.deferred_entry ~method_name:"value"
                 ~js_name:"value" ~present:true __js_obj_cell_0;
             ]))
    in
    let __js_obj =
      object
        method lola = !__js_obj_cell_0
        method cositas = !__js_obj_cell_1
      end
    in
    Js.Obj.Internal.register_deferred __js_obj (fun () ->
        [
          Js.Obj.Internal.deferred_entry ~method_name:"lola" ~js_name:"lola"
            ~present:true __js_obj_cell_0;
          Js.Obj.Internal.deferred_entry ~method_name:"cositas" ~js_name:"cositas"
            ~present:true __js_obj_cell_1;
        ])

  $ cat > main.ml << EOF
  > module Js = struct
  >   module Obj = struct
  >     module Internal = struct
  >       type entry = unit
  >       let deferred_entry ~method_name:_ ~js_name:_ ~present:_ _cell = ()
  >       let register_deferred obj (_ : unit -> entry list) = obj
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
