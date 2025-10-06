  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : string -> keycloak) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "keycloak")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Multiple args with optional

  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : ?z:int -> int -> foo:string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : ?z:int -> int -> foo:string -> keycloak) =
   fun ?z:_ ->
    fun _ ->
     fun ~foo:_ ->
      let () =
        Printf.printf
          {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
      in
      raise (Runtime.fail_impossible_action_in_ssr "keycloak")
  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Single type (invalid OCaml, but valid in Melange)

  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : keycloak = "default" [@@mel.module "keycloak-js"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  [%%ocaml.error
  "[server-reason-react.melange_ppx] There's an external with [%mel.module \
   \"...\"] in native, which should only happen in JavaScript. You need to \
   conditionally run it, either by not including it on native or via \
   let%browser_only/switch%platform. More info at \
   https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
  File "main.ml", line 26, characters 3-14:
  26 | [%%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] There's an external with
         [%mel.module "..."] in native, which should only happen in JavaScript.
         You need to conditionally run it, either by not including it on native
         or via let%browser_only/switch%platform. More info at
         https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html
  [2]

Assets with file not found

  $ cat > input.ml << EOF
  > external img : string = "default" [@@mel.module "does-not-exist.svg"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  File "input.ml", line 1:
  Error: I/O error: ./does-not-exist.svg: No such file or directory

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Webpack: assets like svg or images (payload to mel.module includes file extension)

  $ cat > input.ml << EOF
  > external img : string = "default" [@@mel.module "./image.svg"]
  > EOF

  $ cat > image.svg << EOF
  > <svg xmlns="http://www.w3.org/2000/svg" height="512" width="512"><g fill-rule="evenodd" clip-path="url(#a)"><path fill="#f00" d="M0 0h192v512h-192z"/><path d="M192 340.06h576v171.94h-576z"/><path fill="#fff" d="M192 172.7h576v169.65h-576z"/><path fill="#00732f" d="M192 0h576v172.7h-576z"/></g></svg>
  > EOF

  $ ./standalone.exe -impl input.ml -bundler webpack | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let img = "/1d876c8887ac1038.svg"

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Create folder for following tests

  $ mkdir foo

Webpack: assets like svg or images with paths outside current folder

  $ cat > foo/input.ml << EOF
  > external img : string = "default" [@@mel.module "../image.svg"]
  > EOF

  $ cat > image.svg << EOF
  > <svg xmlns="http://www.w3.org/2000/svg" height="512" width="512"><g fill-rule="evenodd" clip-path="url(#a)"><path fill="#f00" d="M0 0h192v512h-192z"/><path d="M192 340.06h576v171.94h-576z"/><path fill="#fff" d="M192 172.7h576v169.65h-576z"/><path fill="#00732f" d="M192 0h576v172.7h-576z"/></g></svg>
  > EOF

  $ ./standalone.exe -impl $(pwd)/foo/input.ml -bundler webpack | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let img = "/1d876c8887ac1038.svg"

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Esbuild: assets like svg or images (payload to mel.module includes file extension)

  $ cat > input.ml << EOF
  > external img : string = "default" [@@mel.module "./image.svg"]
  > EOF

  $ cat > image.svg << EOF
  > <svg xmlns="http://www.w3.org/2000/svg" height="512" width="512"><g fill-rule="evenodd" clip-path="url(#a)"><path fill="#f00" d="M0 0h192v512h-192z"/><path d="M192 340.06h576v171.94h-576z"/><path fill="#fff" d="M192 172.7h576v169.65h-576z"/><path fill="#00732f" d="M192 0h576v172.7h-576z"/></g></svg>
  > EOF

  $ ./standalone.exe -impl input.ml -bundler esbuild | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let img = "/image-DWDWZCEH.svg"

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Esbuild: assets like svg or images with paths outside current folder

  $ cat > foo/input.ml << EOF
  > external img : string = "default" [@@mel.module "../image.svg"]
  > EOF

  $ cat > image.svg << EOF
  > <svg xmlns="http://www.w3.org/2000/svg" height="512" width="512"><g fill-rule="evenodd" clip-path="url(#a)"><path fill="#f00" d="M0 0h192v512h-192z"/><path d="M192 340.06h576v171.94h-576z"/><path fill="#fff" d="M192 172.7h576v169.65h-576z"/><path fill="#00732f" d="M192 0h576v172.7h-576z"/></g></svg>
  > EOF

  $ ./standalone.exe -impl $(pwd)/foo/input.ml -bundler esbuild | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let img = "/image-DWDWZCEH.svg"

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

With prefix

  $ cat > foo/input.ml << EOF
  > external img : string = "default" [@@mel.module "../demo.txt"]
  > EOF

  $ cat > demo.txt << EOF
  > hello
  > EOF

  $ ./standalone.exe -impl $(pwd)/foo/input.ml -bundler esbuild -prefix /foo/bar | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let img = "/foo/bar/demo-4TAZDUER.txt"

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
