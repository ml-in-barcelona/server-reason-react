open Ppx_deriving_json_runtime.Primitives;

[@react.component]
let make =
    (
      ~string: string,
      ~int: int,
      ~float: float,
      ~bool_true: bool,
      ~bool_false: bool,
      ~string_array: [@deriving json] array(string),
      ~string_list: [@deriving json] list(string),
      ~object_: Js.Json.t,
    ) => {
  <div>
    <code>
      <pre> {React.string("string - ")} {React.string(string)} </pre>
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
        {React.string(Js.Json.stringify(object_))}
      </pre>
    </code>
  </div>;
};

let make_client = props => {
  make({
    "string": string_of_json(props##string),
    "int": int_of_json(props##int),
    "float": float_of_json(props##float),
    "bool_true": bool_of_json(props##bool_true),
    "bool_false": bool_of_json(props##bool_false),
    "string_array": array_of_json(string_of_json, props##string_array),
    "string_list": list_of_json(string_of_json, props##string_list),
    "object_": props##object_,
  });
};

/*
 let make_client = props => {
   React.jsx(
     make,
     makeProps(
       ~string=string_of_json(props##string),
       ~int=int_of_json(props##int),
       ~float=float_of_json(props##float),
       ~bool_true=bool_of_json(props##bool_true),
       ~bool_false=bool_of_json(props##bool_false),
       ~string_array=array_of_json(string_of_json, props##string_array),
       ~string_list=list_of_json(string_of_json, props##string_list),
       ~object_=props##object_,
       (),
     ),
   );
 };
  */
