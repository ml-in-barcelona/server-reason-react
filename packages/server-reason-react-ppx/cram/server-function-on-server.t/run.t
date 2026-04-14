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
              Runtime.id: "244965410",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "244965410",
              Body(
                args => {
                  let name =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withLabelledArg.call(~name, ~age)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
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
              Runtime.id: "150260642",
              call: (~name: string="Lola", age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "150260642",
              Body(
                args => {
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
                  try(
                    withLabelledArgAndUnlabeledArg.call(~name?, age)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
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
              Runtime.id: "72909839",
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
              "72909839",
              Body(
                args => {
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
                  try(
                    withOptionalArg.call(~name?, ())
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
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
              Runtime.id: "1038516267",
              call: (~name: string="Lola", ()) => (
                Lwt.return(Printf.sprintf("Hello, %s", name)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "1038516267",
              Body(
                args => {
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
                  try(
                    withOptionalDefaultArg.call(~name?, ())
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
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
              Runtime.id: "543207864",
              call: (name: string, age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "543207864",
              Body(
                args => {
                  let name =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withUnlabeledArg.call(name, age)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
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
              Runtime.id: "376840710",
              call: () => (Lwt.return("Hello, world!"): Js.Promise.t(string)),
            };
            FunctionReferences.register(
              "376840710",
              Body(
                args =>
                  try(
                    withNoArgs.call()
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormData = {
              Runtime.id: "519042066",
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
              "519042066",
              FormData(
                (_, formData) =>
                  try(
                    withFormData.call(formData)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  },
              ),
            );
          };
  
  include {
            let withFormDataArgs = {
              Runtime.id: "762631116",
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
              "762631116",
              FormData(
                (args, formData) => {
                  let country =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFormDataArgs.call(country, formData)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withFormDataLabelledAndUnlabeledArgs = {
              Runtime.id: "305946000",
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
              "305946000",
              FormData(
                (args, formData) => {
                  let country =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFormDataLabelledAndUnlabeledArgs.call(
                      country,
                      ~formData,
                    )
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withFormDataLabelledAndLabelledArgs = {
              Runtime.id: "836441764",
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
              "836441764",
              FormData(
                (args, formData) => {
                  let country =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFormDataLabelledAndLabelledArgs.call(
                      ~country,
                      ~formData,
                    )
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withFormDataUnlabelledAndLabelledArgs = {
              Runtime.id: "1042320905",
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
              "1042320905",
              FormData(
                (args, formData) => {
                  let country =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFormDataUnlabelledAndLabelledArgs.call(
                      ~country,
                      formData,
                    )
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "271541692",
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
              "271541692",
              FormData(
                (args, formData) => {
                  let country =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFormDataAndArgsDifferentOrder.call(formData, country)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withReturnTypeOnSeparateLine = {
              Runtime.id: "311524135",
              call: (~name: string, ~age: int) => (
                Lwt.return(
                  Printf.sprintf("Hello %s, you are %d years old", name, age),
                ):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "311524135",
              Body(
                args => {
                  let name =
                    try(
                      Melange_json.Primitives.string_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withReturnTypeOnSeparateLine.call(~name, ~age)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withCharArg = {
              Runtime.id: "730655028",
              call: (~letter: char) => (
                Js.Promise.resolve(String.make(1, letter)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "730655028",
              Body(
                args => {
                  let letter =
                    try(
                      (
                        json => {
                          let s = Melange_json.Primitives.string_of_json(json);
                          if (String.length(s) == 1) {
                            s.[0];
                          } else {
                            Melange_json.of_json_error(
                              ~json,
                              "expected a single-character string",
                            );
                          };
                        }
                      )(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withCharArg.call(~letter)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withResultArg = {
              Runtime.id: "290632052",
              call: (~result: result(string, string)) => (
                switch (result) {
                | Ok(s) => Js.Promise.resolve(s)
                | Error(e) => Js.Promise.resolve(e)
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "290632052",
              Body(
                args => {
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
                  try(
                    withResultArg.call(~result)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withTuple2Arg = {
              Runtime.id: "868487122",
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
              "868487122",
              Body(
                args => {
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
                  try(
                    withTuple2Arg.call(~pair)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withTuple5Arg = {
              Runtime.id: "593992612",
              call: (~data: (string, int, float, bool, char)) => (
                {
                  let (name, _age, _score, _active, _letter) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "593992612",
              Body(
                args => {
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
                                  let s =
                                    Melange_json.Primitives.string_of_json(
                                      json,
                                    );
                                  if (String.length(s) == 1) {
                                    s.[0];
                                  } else {
                                    Melange_json.of_json_error(
                                      ~json,
                                      "expected a single-character string",
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
                  try(
                    withTuple5Arg.call(~data)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withTuple6Arg = {
              Runtime.id: "825335486",
              call: (~data: (string, int, float, bool, char, int64)) => (
                {
                  let (name, _age, _score, _active, _letter, _id) = data;
                  Js.Promise.resolve(name);
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "825335486",
              Body(
                args => {
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
                                  let s =
                                    Melange_json.Primitives.string_of_json(
                                      json,
                                    );
                                  if (String.length(s) == 1) {
                                    s.[0];
                                  } else {
                                    Melange_json.of_json_error(
                                      ~json,
                                      "expected a single-character string",
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
                  try(
                    withTuple6Arg.call(~data)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withBoolArg = {
              Runtime.id: "992749241",
              call: (~flag: bool) => (
                Js.Promise.resolve(flag ? "yes" : "no"): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "992749241",
              Body(
                args => {
                  let flag =
                    try(
                      Melange_json.Primitives.bool_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withBoolArg.call(~flag)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withFloatArg = {
              Runtime.id: "204801789",
              call: (~score: float) => (
                Js.Promise.resolve(Js.Float.toString(score)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "204801789",
              Body(
                args => {
                  let score =
                    try(
                      Melange_json.Primitives.float_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withFloatArg.call(~score)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withInt64Arg = {
              Runtime.id: "161188939",
              call: (~big: int64) => (
                Js.Promise.resolve(Int64.to_string(big)): Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "161188939",
              Body(
                args => {
                  let big =
                    try(
                      Melange_json.Primitives.int64_of_json(
                        Stdlib.Array.unsafe_get(args, 0),
                      )
                    ) {
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
                  try(
                    withInt64Arg.call(~big)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withListArg = {
              Runtime.id: "704022741",
              call: (~names: list(string)) => (
                Js.Promise.resolve(String.concat(", ", names)):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "704022741",
              Body(
                args => {
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
                  try(
                    withListArg.call(~names)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withArrayArg = {
              Runtime.id: "979987442",
              call: (~ids: array(int)) => (
                Js.Promise.resolve(string_of_int(Array.length(ids))):
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "979987442",
              Body(
                args => {
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
                  try(
                    withArrayArg.call(~ids)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withOptionIntArg = {
              Runtime.id: "114809194",
              call: (~count: option(int)=?, ()) => (
                switch (count) {
                | Some(n) => Js.Promise.resolve(string_of_int(n))
                | None => Js.Promise.resolve("none")
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "114809194",
              Body(
                args => {
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
                  try(
                    withOptionIntArg.call(~count?, ())
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withNestedListOptionArg = {
              Runtime.id: "986464429",
              call: (~items: list(option(string))) => (
                {
                  let _ = items;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "986464429",
              Body(
                args => {
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
                  try(
                    withNestedListOptionArg.call(~items)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
  
  include {
            let withNestedResultListArg = {
              Runtime.id: "575616680",
              call: (~data: result(list(int), string)) => (
                {
                  let _ = data;
                  Js.Promise.resolve("ok");
                }:
                  Js.Promise.t(string)
              ),
            };
            FunctionReferences.register(
              "575616680",
              Body(
                args => {
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
                  try(
                    withNestedResultListArg.call(~data)
                    |> Lwt.map(response =>
                         RSC.to_model(RSC.Primitives.string_to_rsc(response))
                       )
                  ) {
                  | e => Lwt.fail(e)
                  };
                },
              ),
            );
          };
