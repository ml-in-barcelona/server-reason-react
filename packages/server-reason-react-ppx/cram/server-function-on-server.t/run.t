  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune build

  $ dune describe pp input.re
  [@ocaml.ppx.context
    {
      tool_name: "ppx_driver",
      include_dirs: [],
      load_path: [],
      open_modules: [],
      for_package: None,
      debug: false,
      use_threads: false,
      use_vmthreads: false,
      recursive_types: false,
      principal: false,
      transparent_modules: false,
      unboxed_types: false,
      unsafe_string: false,
      cookies: [],
    }
  ];
  include Melange_json.Primitives;
  
  include {
            [@react.server.function]
            let simpleResponse = {
              Runtime.id: "111391064",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            let simpleResponseRouteHandler = args => {
              let (name, age) =
                switch (args) {
                | [name, age] =>
                  let name = string_of_json(name);
                  let age = int_of_json(age);
                  (name, age);
                | _ => failwith("server-reason-react: invalid arguments")
                };
              try(
                simpleResponse.call(~name, ~age)
                |> Lwt.map(response => React.Json(string_to_json(response)))
              ) {
              | e => Lwt.fail(e)
              };
            };
          };
  
  include {
            [@react.server.function]
            let otherServerFunction = {
              Runtime.id: "56688875",
              call: (~name: string, ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            let otherServerFunctionRouteHandler = args => {
              let name =
                switch (args) {
                | [name] =>
                  let name = string_of_json(name);
                  name;
                | _ => failwith("server-reason-react: invalid arguments")
                };
              try(
                otherServerFunction.call(~name, ())
                |> Lwt.map(response => React.Json(string_to_json(response)))
              ) {
              | e => Lwt.fail(e)
              };
            };
          };
  
  include {
            [@react.server.function]
            let anotherServerFunction = {
              Runtime.id: "337953788",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            let anotherServerFunctionRouteHandler = args =>
              try(
                anotherServerFunction.call()
                |> Lwt.map(response => React.Json(string_to_json(response)))
              ) {
              | e => Lwt.fail(e)
              };
          };

