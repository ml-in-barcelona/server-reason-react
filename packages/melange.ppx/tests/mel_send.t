Labelled args with @@mel.send
  $ cat > input.ml << EOF
  > external init : string -> param:int -> string = "init" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let init : string -> param:int -> string =
   fun _ ~param:_ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "init")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Labelled and unlabelled args with @@mel.obj

  $ cat > input.ml << EOF
  > external makeInitParam : onLoad:string -> unit -> < onLoad : string > = "" [@@mel.obj]
  > let onLoad = (makeInitParam ~onLoad:"ready" ())##onLoad
  > external makeOptional : ?retries:int -> unit -> < retries : int option > = "" [@@mel.obj]
  > let retries = (makeOptional ())##retries
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let makeInitParam : onLoad:string -> unit -> < onLoad : string > =
   fun ~onLoad _ ->
    let __js_obj_cell_0 = Stdlib.ref onLoad in
    let __js_obj =
      object
        method onLoad = !__js_obj_cell_0
      end
    in
    (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
         [
           Js.Obj.Internal.deferred_entry ~method_name:"onLoad" ~js_name:"onLoad"
             ~present:true __js_obj_cell_0;
         ])
      : < onLoad : string >)
  
  let onLoad = (makeInitParam ~onLoad:"ready" ())#onLoad
  
  let makeOptional : ?retries:int -> unit -> < retries : int option > =
   fun ?retries _ ->
    let __js_obj_cell_0 = Stdlib.ref retries in
    let __js_obj_present_0 =
      match retries with None -> false | Some _ -> true
    in
    let __js_obj =
      object
        method retries = !__js_obj_cell_0
      end
    in
    (Js.Obj.Internal.register_deferred_abstract __js_obj (fun () ->
         [
           Js.Obj.Internal.deferred_entry ~method_name:"retries"
             ~js_name:"retries" ~present:__js_obj_present_0 __js_obj_cell_0;
         ])
      : < retries : int option >)
  
  let retries = (makeOptional ())#retries

  $ cat > main.ml << EOF
  > module Js = struct
  >   module Obj = struct
  >     module Internal = struct
  >       type entry = unit
  >       let deferred_entry ~method_name:_ ~js_name:_ ~present:_ _cell = ()
  >       let register_deferred_abstract obj (_ : unit -> entry list) = Stdlib.Obj.magic obj
  >     end
  >   end
  > end
  > EOF
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml


mel.send

  $ cat > input.ml << EOF
  > type t
  > external fillStyle : t -> 'a = "fillStyle" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let fillStyle : t -> 'a =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "fillStyle")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
