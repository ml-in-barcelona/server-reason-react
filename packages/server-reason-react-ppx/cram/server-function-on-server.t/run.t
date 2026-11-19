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
              Runtime.id: "input#withLabelledArg",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withLabelledArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
                                Stdlib.Array.unsafe_get(args, 1)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withLabelledArgAndUnlabeledArg",
              call: (~name: string="Lola", age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withLabelledArgAndUnlabeledArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
                                Stdlib.Array.unsafe_get(args, 1)
                                |> Yojson.Basic.to_string,
                              ),
                            ),
                          )
                        };
                      withLabelledArgAndUnlabeledArg.call(~name?, age)
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
              Runtime.id: "input#withOptionalArg",
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
              "input#withOptionalArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withOptionalDefaultArg",
              call: (~name: string="Lola", ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withOptionalDefaultArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
                              ),
                            ),
                          )
                        };
                      withOptionalDefaultArg.call(~name?, ())
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
              Runtime.id: "input#withUnlabeledArg",
              call: (name: string, age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withUnlabeledArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
                                Stdlib.Array.unsafe_get(args, 1)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withNoArgs",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            FunctionReferences.register(
              "input#withNoArgs",
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
              Runtime.id: "input#withFormData",
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
              "input#withFormData",
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
              Runtime.id: "input#withFormDataArgs",
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
              "input#withFormDataArgs",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFormDataLabelledAndUnlabeledArgs",
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
              "input#withFormDataLabelledAndUnlabeledArgs",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFormDataLabelledAndLabelledArgs",
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
              "input#withFormDataLabelledAndLabelledArgs",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFormDataUnlabelledAndLabelledArgs",
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
              "input#withFormDataUnlabelledAndLabelledArgs",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFormDataAndArgsDifferentOrder",
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
              "input#withFormDataAndArgsDifferentOrder",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withReturnTypeOnSeparateLine",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withReturnTypeOnSeparateLine",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
                                Stdlib.Array.unsafe_get(args, 1)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withCharArg",
              call: (~letter: char) => (
                Js.Promise.resolve(String.make(1, letter)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withCharArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withResultArg",
              call: (~result: result(string, string)) => (
                switch (result) {
                | Ok(s) => Js.Promise.resolve(s)
                | Error(e) => Js.Promise.resolve(e)
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withResultArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withTuple2Arg",
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
              "input#withTuple2Arg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withTuple5Arg",
              call: (~data: (string, int, float, bool, char)) => (
                {
                  let (name, _age, _score, _active, _letter) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withTuple5Arg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withTuple6Arg",
              call: (~data: (string, int, float, bool, char, int64)) => (
                {
                  let (name, _age, _score, _active, _letter, _id) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withTuple6Arg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withBoolArg",
              call: (~flag: bool) => (
                Js.Promise.resolve(flag ? "yes" : "no"): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withBoolArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFloatArg",
              call: (~score: float) => (
                Js.Promise.resolve(Js.Float.toString(score)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withFloatArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withInt64Arg",
              call: (~big: int64) => (
                Js.Promise.resolve(Int64.to_string(big)): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withInt64Arg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withListArg",
              call: (~names: list(string)) => (
                Js.Promise.resolve(String.concat(", ", names)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withListArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withArrayArg",
              call: (~ids: array(int)) => (
                Js.Promise.resolve(string_of_int(Array.length(ids))):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withArrayArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withOptionIntArg",
              call: (~count: option(int)=?, ()) => (
                switch (count) {
                | Some(n) => Js.Promise.resolve(string_of_int(n))
                | None => Js.Promise.resolve("none")
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withOptionIntArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withNestedListOptionArg",
              call: (~items: list(option(string))) => (
                {
                  let _ = items;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withNestedListOptionArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withNestedResultListArg",
              call: (~data: result(list(int), string)) => (
                {
                  let _ = data;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "input#withNestedResultListArg",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
              Runtime.id: "input#withFormDataNamedFd",
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
              "input#withFormDataNamedFd",
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
              Runtime.id: "input#withFormDataNamedFdAndArgs",
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
              "input#withFormDataNamedFdAndArgs",
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
                                Stdlib.Array.unsafe_get(args, 0)
                                |> Yojson.Basic.to_string,
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
