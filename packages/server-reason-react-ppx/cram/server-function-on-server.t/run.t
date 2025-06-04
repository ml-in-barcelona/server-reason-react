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
  open Melange_json.Primitives;
  
  module FunctionReferences: ReactServerDOM.FunctionReferences = {
    type t = Hashtbl.t(string, ReactServerDOM.server_function);
  
    let registry = Hashtbl.create(10);
    let register = Hashtbl.add(registry);
    let get = Hashtbl.find_opt(registry);
  };
  
  include {
            let withLabelledArg = {
              Runtime.id: "515397179",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "515397179",
              Body(
                args => {
                  let name =
                    try(string_of_json(args[0])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        ),
                      )
                    }
                  and age =
                    try(int_of_json(args[1])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "age",
                            "int",
                            args[1] |> Yojson.Basic.to_string,
                          ),
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
            );
          };
  
  include {
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "896610790",
              call: (~name: string="Lola", age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "896610790",
              Body(
                args => {
                  let name =
                    try((option_of_json(string_of_json))(args[0])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string option",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        ),
                      )
                    }
                  and age =
                    try(int_of_json(args[1])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "age",
                            "int",
                            args[1] |> Yojson.Basic.to_string,
                          ),
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
            );
          };
  
  include {
            let withOptionalArg = {
              Runtime.id: "949714301",
              call: (~name: option(string)=?, ()) => (
                {
                  let name =
                    switch (name) {
                    | Some(name) => name
                    | None => "Lola"
                    };
                  Lwt.return(Printf.sprintf("Hello, %s", name));
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "949714301",
              Body(
                args => {
                  let name =
                    try((option_of_json(string_of_json))(args[0])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string option",
                            args[0] |> Yojson.Basic.to_string,
                          ),
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
            );
          };
  
  include {
            let withOptionalDefaultArg = {
              Runtime.id: "285929146",
              call: (~name: string="Lola", ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "285929146",
              Body(
                args => {
                  let name =
                    try((option_of_json(string_of_json))(args[0])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string option",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        ),
                      )
                    };
                  try(
                    withOptionalDefaultArg.call(~name?, ())
                    |> Lwt.map(response =>
                         React.Json(string_to_json(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withUnlabeledArg = {
              Runtime.id: "604196953",
              call: (name: string, age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "604196953",
              Body(
                args => {
                  let name =
                    try(string_of_json(args[0])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "name",
                            "string",
                            args[0] |> Yojson.Basic.to_string,
                          ),
                        ),
                      )
                    }
                  and age =
                    try(int_of_json(args[1])) {
                    | _ =>
                      raise(
                        Invalid_argument(
                          Printf.sprintf(
                            "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                            "age",
                            "int",
                            args[1] |> Yojson.Basic.to_string,
                          ),
                        ),
                      )
                    };
                  try(
                    withUnlabeledArg.call(name, age)
                    |> Lwt.map(response =>
                         React.Json(string_to_json(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withNoArgs = {
              Runtime.id: "363520221",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            FunctionReferences.register(
              "363520221",
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
            );
          };
