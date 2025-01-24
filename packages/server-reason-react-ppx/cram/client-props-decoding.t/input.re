open Ppx_deriving_json_runtime.Primitives;

[@warning "-27"];
[@react.client.component]
let make =
    (
      ~prop: int,
      ~lola: list(int),
      /* ~mona: array(float), */
      ~lolo: string,
      ~lili: bool,
      ~lulu: float,
      ~tuple2: (int, int),
      ~tuple3: (int, string, float),
    ) => React.null;

// to avoid unused error on "make"
let _ = make;
