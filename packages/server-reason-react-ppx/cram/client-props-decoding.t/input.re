open Melange_json.Primitives;

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
