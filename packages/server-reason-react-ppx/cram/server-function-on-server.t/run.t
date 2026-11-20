  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json-native server-reason-react.rsc-native)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx server-reason-react.rsc-native.ppx)))
  > EOF

  $ dune build

  $ ../dune-describe-pp.sh input.re
  module FunctionReferences: ReactServerDOM.FunctionReferences = {
    type t = Hashtbl.t(string, ReactServerDOM.server_function);
  
    let registry = Hashtbl.create(10);
    let register = Hashtbl.add(registry);
    let get = Hashtbl.find_opt(registry);
  };
  
  include {
            let withLabelledArg = {
              Runtime.id: "d795178b8ec4e7eb",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "d795178b8ec4e7eb",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 2 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withLabelledArg",
                                "2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        }
                      and age =
                        try(
                          Melange_json.Primitives.int_of_json(
                            Stdlib.Array.unsafe_get(args, 1),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "age",
                                "int",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 1),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withLabelledArg.call(~name, ~age)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "cc16d8dfbb02c5f1",
              call: (~name: string="Lola", age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "cc16d8dfbb02c5f1",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 2 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withLabelledArgAndUnlabeledArg",
                                "2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        }
                      and age =
                        try(
                          Melange_json.Primitives.int_of_json(
                            Stdlib.Array.unsafe_get(args, 1),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "age",
                                "int",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 1),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withLabelledArgAndUnlabeledArg.call(~name, age)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withOptionalArg = {
              Runtime.id: "759127163477eddf",
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
              "759127163477eddf",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withOptionalArg",
                                "1 to 2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          (
                            Melange_json.Primitives.option_of_json(
                              Melange_json.Primitives.string_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string option",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withOptionalArg.call(~name?, ())
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withOptionalDefaultArg = {
              Runtime.id: "e14a2f3233911fed",
              call: (~name: string="Lola", ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "e14a2f3233911fed",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withOptionalDefaultArg",
                                "1 to 2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withOptionalDefaultArg.call(~name, ())
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withUnlabeledArg = {
              Runtime.id: "4609c752f0fd4336",
              call: (name: string, age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "4609c752f0fd4336",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 2 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withUnlabeledArg",
                                "2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        }
                      and age =
                        try(
                          Melange_json.Primitives.int_of_json(
                            Stdlib.Array.unsafe_get(args, 1),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "age",
                                "int",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 1),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withUnlabeledArg.call(name, age)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withNoArgs = {
              Runtime.id: "35bf61b207c3c325",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            FunctionReferences.register(
              "35bf61b207c3c325",
              Body(
                args =>
                  try(
                    withNoArgs.call()
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormData = {
              Runtime.id: "7aaca06c4b5d839b",
              call: (formData: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let age =
                    Js.FormData.get(formData, "age")
                    |> (
                      fun
                      | `String(age) => age
                    );
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are %s years old", name, age),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "7aaca06c4b5d839b",
              FormData(
                (_, formData) =>
                  try(
                    withFormData.call(formData)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataArgs = {
              Runtime.id: "bdba0def36cec354",
              call: (country: string, formData: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let country = country;
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "bdba0def36cec354",
              FormData(
                (args, formData) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataArgs",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataArgs.call(country, formData)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataLabelledAndUnlabeledArgs = {
              Runtime.id: "ca4d6249058d6f72",
              call: (country: string, ~formData: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let country = country;
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "ca4d6249058d6f72",
              FormData(
                (args, formData) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataLabelledAndUnlabeledArgs",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataLabelledAndUnlabeledArgs.call(
                        country,
                        ~formData,
                      )
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataLabelledAndLabelledArgs = {
              Runtime.id: "35124443a9ca3e46",
              call: (~country: string, ~formData: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let country = country;
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "35124443a9ca3e46",
              FormData(
                (args, formData) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataLabelledAndLabelledArgs",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataLabelledAndLabelledArgs.call(
                        ~country,
                        ~formData,
                      )
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataUnlabelledAndLabelledArgs = {
              Runtime.id: "fb8fe6f5361d83d2",
              call: (~country: string, formData: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let country = country;
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "fb8fe6f5361d83d2",
              FormData(
                (args, formData) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataUnlabelledAndLabelledArgs",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataUnlabelledAndLabelledArgs.call(
                        ~country,
                        formData,
                      )
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "79fae9670eeb9c1b",
              call: (formData: Js.FormData.t, country: string) => (
                {
                  let name =
                    Js.FormData.get(formData, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  let country = country;
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "79fae9670eeb9c1b",
              FormData(
                (args, formData) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataAndArgsDifferentOrder",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataAndArgsDifferentOrder.call(formData, country)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withReturnTypeOnSeparateLine = {
              Runtime.id: "c0983d541835b2f6",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "c0983d541835b2f6",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 2 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withReturnTypeOnSeparateLine",
                                "2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let name =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "name",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        }
                      and age =
                        try(
                          Melange_json.Primitives.int_of_json(
                            Stdlib.Array.unsafe_get(args, 1),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "age",
                                "int",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 1),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withReturnTypeOnSeparateLine.call(~name, ~age)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withCharArg = {
              Runtime.id: "e9af9d26b2b5a532",
              call: (~letter: char) => (
                Js.Promise.resolve(String.make(1, letter)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "e9af9d26b2b5a532",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withCharArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let letter =
                        try(
                          (
                            json => {
                              let code =
                                Melange_json.Primitives.int_of_json(json);
                              if (code >= 0 && code <= 255) {
                                Stdlib.Char.chr(code);
                              } else {
                                Melange_json.of_json_error(
                                  ~json,
                                  "expected a char code from 0 to 255",
                                );
                              };
                            }
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "letter",
                                "char",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withCharArg.call(~letter)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withResultArg = {
              Runtime.id: "d2e977839904ede6",
              call: (~result: result(string, string)) => (
                switch (result) {
                | Ok(s) => Js.Promise.resolve(s)
                | Error(e) => Js.Promise.resolve(e)
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "d2e977839904ede6",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withResultArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let result =
                        try(
                          (
                            Melange_json.Primitives.result_of_json(
                              Melange_json.Primitives.string_of_json,
                              Melange_json.Primitives.string_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "result",
                                "(string, string) result",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withResultArg.call(~result)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withTuple2Arg = {
              Runtime.id: "14eaed19bdbca8ed",
              call: (~pair: (string, int)) => (
                {
                  let (name, age) = pair;
                  Js.Promise.resolve(
                    Printf.sprintf("Hello %s, you are %d years old", name, age),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "14eaed19bdbca8ed",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withTuple2Arg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let pair =
                        try(
                          (
                            json =>
                              switch (json) {
                              | `List([t0, t1]) => (
                                  Melange_json.Primitives.string_of_json(t0),
                                  Melange_json.Primitives.int_of_json(t1),
                                )
                              | _ =>
                                Melange_json.of_json_error(
                                  ~json,
                                  "expected a JSON array of length 2",
                                )
                              }
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "pair",
                                "(string * int)",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withTuple2Arg.call(~pair)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withTuple5Arg = {
              Runtime.id: "c3b3fb50d5709f8e",
              call: (~data: (string, int, float, bool, char)) => (
                {
                  let (name, _age, _score, _active, _letter) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "c3b3fb50d5709f8e",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withTuple5Arg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let data =
                        try(
                          (
                            json =>
                              switch (json) {
                              | `List([t0, t1, t2, t3, t4]) => (
                                  Melange_json.Primitives.string_of_json(t0),
                                  Melange_json.Primitives.int_of_json(t1),
                                  Melange_json.Primitives.float_of_json(t2),
                                  Melange_json.Primitives.bool_of_json(t3),
                                  (
                                    json => {
                                      let code =
                                        Melange_json.Primitives.int_of_json(
                                          json,
                                        );
                                      if (code >= 0 && code <= 255) {
                                        Stdlib.Char.chr(code);
                                      } else {
                                        Melange_json.of_json_error(
                                          ~json,
                                          "expected a char code from 0 to 255",
                                        );
                                      };
                                    }
                                  )(
                                    t4,
                                  ),
                                )
                              | _ =>
                                Melange_json.of_json_error(
                                  ~json,
                                  "expected a JSON array of length 5",
                                )
                              }
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "data",
                                "(string * int * float * bool * char)",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withTuple5Arg.call(~data)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withTuple6Arg = {
              Runtime.id: "c475ea7d2ed15c5f",
              call: (~data: (string, int, float, bool, char, int64)) => (
                {
                  let (name, _age, _score, _active, _letter, _id) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "c475ea7d2ed15c5f",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withTuple6Arg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let data =
                        try(
                          (
                            json =>
                              switch (json) {
                              | `List([t0, t1, t2, t3, t4, t5]) => (
                                  Melange_json.Primitives.string_of_json(t0),
                                  Melange_json.Primitives.int_of_json(t1),
                                  Melange_json.Primitives.float_of_json(t2),
                                  Melange_json.Primitives.bool_of_json(t3),
                                  (
                                    json => {
                                      let code =
                                        Melange_json.Primitives.int_of_json(
                                          json,
                                        );
                                      if (code >= 0 && code <= 255) {
                                        Stdlib.Char.chr(code);
                                      } else {
                                        Melange_json.of_json_error(
                                          ~json,
                                          "expected a char code from 0 to 255",
                                        );
                                      };
                                    }
                                  )(
                                    t4,
                                  ),
                                  Melange_json.Primitives.int64_of_json(t5),
                                )
                              | _ =>
                                Melange_json.of_json_error(
                                  ~json,
                                  "expected a JSON array of length 6",
                                )
                              }
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "data",
                                "(string * int * float * bool * char * int64)",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withTuple6Arg.call(~data)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withBoolArg = {
              Runtime.id: "defad4fc0b6197d9",
              call: (~flag: bool) => (
                Js.Promise.resolve(flag ? "yes" : "no"): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "defad4fc0b6197d9",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withBoolArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let flag =
                        try(
                          Melange_json.Primitives.bool_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "flag",
                                "bool",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withBoolArg.call(~flag)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFloatArg = {
              Runtime.id: "3a71c568a9f76459",
              call: (~score: float) => (
                Js.Promise.resolve(Js.Float.toString(score)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "3a71c568a9f76459",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFloatArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let score =
                        try(
                          Melange_json.Primitives.float_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "score",
                                "float",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFloatArg.call(~score)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withInt64Arg = {
              Runtime.id: "57b533d2311c9a24",
              call: (~big: int64) => (
                Js.Promise.resolve(Int64.to_string(big)): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "57b533d2311c9a24",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withInt64Arg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let big =
                        try(
                          Melange_json.Primitives.int64_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "big",
                                "int64",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withInt64Arg.call(~big)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withListArg = {
              Runtime.id: "af9277acf0958e63",
              call: (~names: list(string)) => (
                Js.Promise.resolve(String.concat(", ", names)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "af9277acf0958e63",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withListArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let names =
                        try(
                          (
                            Melange_json.Primitives.list_of_json(
                              Melange_json.Primitives.string_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "names",
                                "string list",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withListArg.call(~names)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withArrayArg = {
              Runtime.id: "d37c239ff74d84c5",
              call: (~ids: array(int)) => (
                Js.Promise.resolve(string_of_int(Array.length(ids))):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "d37c239ff74d84c5",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withArrayArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let ids =
                        try(
                          (
                            Melange_json.Primitives.array_of_json(
                              Melange_json.Primitives.int_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "ids",
                                "int array",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withArrayArg.call(~ids)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withOptionIntArg = {
              Runtime.id: "3e6320f309237d93",
              call: (~count: option(int)=?, ()) => (
                switch (count) {
                | Some(n) => Js.Promise.resolve(string_of_int(n))
                | None => Js.Promise.resolve("none")
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "3e6320f309237d93",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 2) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withOptionIntArg",
                                "1 to 2",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let count =
                        try(
                          (
                            Melange_json.Primitives.option_of_json(
                              Melange_json.Primitives.int_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "count",
                                "int option",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withOptionIntArg.call(~count?, ())
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withNestedListOptionArg = {
              Runtime.id: "e546234bdc88e0eb",
              call: (~items: list(option(string))) => (
                {
                  let _ = items;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "e546234bdc88e0eb",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withNestedListOptionArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let items =
                        try(
                          (
                            Melange_json.Primitives.list_of_json(
                              Melange_json.Primitives.option_of_json(
                                Melange_json.Primitives.string_of_json,
                              ),
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "items",
                                "string option list",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withNestedListOptionArg.call(~items)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withNestedResultListArg = {
              Runtime.id: "bfa6480d6c0fab22",
              call: (~data: result(list(int), string)) => (
                {
                  let _ = data;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "bfa6480d6c0fab22",
              Body(
                args =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withNestedResultListArg",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let data =
                        try(
                          (
                            Melange_json.Primitives.result_of_json(
                              Melange_json.Primitives.list_of_json(
                                Melange_json.Primitives.int_of_json,
                              ),
                              Melange_json.Primitives.string_of_json,
                            )
                          )(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "data",
                                "(int list, string) result",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withNestedResultListArg.call(~data)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataNamedFd = {
              Runtime.id: "4774b1f9a1189743",
              call: (fd: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(fd, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  Lwt.return(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "4774b1f9a1189743",
              FormData(
                (_, fd) =>
                  try(
                    withFormDataNamedFd.call(fd)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataNamedFdAndArgs = {
              Runtime.id: "2ff1173b01049e42",
              call: (country: string, fd: Js.FormData.t) => (
                {
                  let name =
                    Js.FormData.get(fd, "name")
                    |> (
                      fun
                      | `String(name) => name
                    );
                  Lwt.return(
                    Printf.sprintf("Hello %s, you are from %s", name, country),
                  );
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "2ff1173b01049e42",
              FormData(
                (args, fd) =>
                  try(
                    {
                      {
                        let length = Stdlib.Array.length(args);
                        if (length < 1 || length > 1) {
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: server function '%s' expects %s arguments, received %d",
                                "withFormDataNamedFdAndArgs",
                                "1",
                                length,
                              ),
                            ),
                          );
                        };
                      };
                      let country =
                        try(
                          Melange_json.Primitives.string_of_json(
                            Stdlib.Array.unsafe_get(args, 0),
                          )
                        ) {
                        | (
                            Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                            Stdlib.Sys.Break
                          ) as e =>
                          Stdlib.raise(e)
                        | _ =>
                          Stdlib.raise(
                            Invalid_argument(
                              Stdlib.Printf.sprintf(
                                "server-reason-react: error on decoding argument '%s'. EXPECTED: %s, RECEIVED: %s",
                                "country",
                                "string",
                                {
                                  let received =
                                    Yojson.Basic.to_string(
                                      Stdlib.Array.unsafe_get(args, 0),
                                    );
                                  if (Stdlib.String.length(received) > 200) {
                                    Stdlib.(++)(
                                      Stdlib.String.sub(received, 0, 200),
                                      "...",
                                    );
                                  } else {
                                    received;
                                  };
                                },
                              ),
                            ),
                          )
                        };
                      withFormDataNamedFdAndArgs.call(country, fd)
                      |> Lwt.map(response =>
                           RSC.to_model(RSC.Primitives.string_to_rsc(response))
                         );
                    }
                  ) {
                  | (
                      Stdlib.Out_of_memory | Stdlib.Stack_overflow |
                      Stdlib.Sys.Break
                    ) as e =>
                    Stdlib.raise(e)
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
