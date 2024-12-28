open Ppx_deriving_json_runtime.Primitives;

let make =
    (
      ~string: string,
      ~int: int,
      ~float: float,
      ~bool_true: bool,
      ~bool_false: bool,
      ~string_array: [@deriving json] array(string),
      ~string_list: [@deriving json] list(string),
      ~object_: Yojson.Basic.t,
      (),
    ) => {
  React.Client_component({
    import_module: __FILE__,
    import_name: "",
    props: [
      ("string", React.Json(string_to_json(string))),
      ("int", React.Json(int_to_json(int))),
      ("float", React.Json(float_to_json(float))),
      ("bool_true", React.Json(bool_to_json(bool_true))),
      ("bool_false", React.Json(bool_to_json(bool_false))),
      (
        "string_array",
        React.Json(array_to_json(string_to_json, string_array)),
      ),
      (
        "string_list",
        React.Json(list_to_json(string_to_json, string_list)),
      ),
      ("object_", React.Json(object_)),
    ],
    client:
      <div>
        <code>
          {React.createElement(
             "pre",
             [],
             [React.string("string - "), React.string(string)],
           )}
          <pre> {React.string("int - ")} {React.int(int)} </pre>
          <pre> {React.string("float - ")} {React.float(float)} </pre>
          <pre>
            {React.string("bool_true - ")}
            {React.string(bool_true ? "true" : "false")}
          </pre>
          <pre>
            {React.string("bool_false - ")}
            {React.string(bool_false ? "true" : "false")}
          </pre>
          <pre>
            {React.string("string_list - ")}
            {string_list
             |> Array.of_list
             |> Array.map(item =>
                  <span key=item>
                    {React.string(item)}
                    {React.string(" ")}
                  </span>
                )
             |> React.array}
          </pre>
          <pre>
            {React.string("string_array - ")}
            {string_array
             |> Array.map(item =>
                  <span key=item>
                    {React.string(item)}
                    {React.string(" ")}
                  </span>
                )
             |> React.array}
          </pre>
          <pre>
            {React.string("object_ - ")}
            {React.string(Yojson.Basic.to_string(object_))}
          </pre>
        </code>
      </div>,
  });
};
