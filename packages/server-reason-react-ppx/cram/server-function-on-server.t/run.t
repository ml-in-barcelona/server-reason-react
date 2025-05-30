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
            let withLabelledArg = {
              Runtime.id: "646124344",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            ReactServerDOM.FunctionReferences.(
              register(
                "646124344",
                Body(
                  args => {
                    let name =
                      try(string_of_json(args[0])) {
                      | _ =>
                        failwith(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        )
                      }
                    and age =
                      try(int_of_json(args[1])) {
                      | _ =>
                        failwith(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "age",
                            "int",
                            args[1] |> Yojson.Basic.to_string,
                          ),
                        )
                      };
                    try(
                      withLabelledArg.call(~name, ~age)
                      |> Lwt.map(response =>
                           React.Json(string_to_json(response))
                         )
                    ) {
                    | e => Lwt.fail(e)
                    };
                  },
                ),
              )
            );
          };
  
  include {
            [@react.server.function]
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "43607654",
              call: (~name: string="Lola", age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            ReactServerDOM.FunctionReferences.(
              register(
                "43607654",
                Body(
                  args => {
                    let name =
                      try((option_of_json(string_of_json))(args[0])) {
                      | _ =>
                        failwith(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string option",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        )
                      }
                    and age =
                      try(int_of_json(args[1])) {
                      | _ =>
                        failwith(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "age",
                            "int",
                            args[1] |> Yojson.Basic.to_string,
                          ),
                        )
                      };
                    try(
                      withLabelledArgAndUnlabeledArg.call(~name?, age)
                      |> Lwt.map(response =>
                           React.Json(string_to_json(response))
                         )
                    ) {
                    | e => Lwt.fail(e)
                    };
                  },
                ),
              )
            );
          };
  
  include {
            [@react.server.function]
            let withOptionalArg = {
              Runtime.id: "275062916",
              call: (~name: string="Lola", ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            ReactServerDOM.FunctionReferences.(
              register(
                "275062916",
                Body(
                  args => {
                    let name =
                      try((option_of_json(string_of_json))(args[0])) {
                      | _ =>
                        failwith(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string option",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        )
                      };
                    try(
                      withOptionalArg.call(~name?, ())
                      |> Lwt.map(response =>
                           React.Json(string_to_json(response))
                         )
                    ) {
                    | e => Lwt.fail(e)
                    };
                  },
                ),
              )
            );
          };
  
  include {
            [@react.server.function]
            let withNoArgs = {
              Runtime.id: "573178554",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            ReactServerDOM.FunctionReferences.(
              register(
                "573178554",
                Body(
                  args =>
                    try(
                      withNoArgs.call()
                      |> Lwt.map(response =>
                           React.Json(string_to_json(response))
                         )
                    ) {
                    | e => Lwt.fail(e)
                    },
                ),
              )
            );
          };
