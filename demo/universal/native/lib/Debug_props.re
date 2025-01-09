[@warning "-33"];

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
      ~header: option(React.element)=?,
      ~children: React.element,
    ) => {
  <div className="text-white">
    {switch (header) {
     | Some(header) => <header> header </header>
     | None => React.null
     }}
    <br />
    <code>
      <pre>
        <span> {React.string("string - ")} </span>
        <span> {React.string(string)} </span>
      </pre>
      <pre>
        <span> {React.string("int - ")} </span>
        <span> {React.int(int)} </span>
      </pre>
      <pre>
        <span> {React.string("float - ")} </span>
        <span> {React.float(float)} </span>
      </pre>
      <pre>
        <span> {React.string("bool_true - ")} </span>
        <span> {React.string(bool_true ? "true" : "false")} </span>
      </pre>
      <pre>
        <span> {React.string("bool_false - ")} </span>
        <span> {React.string(bool_false ? "true" : "false")} </span>
      </pre>
      <pre>
        <span> {React.string("string_list - ")} </span>
        <p>
          {string_list
           |> Array.of_list
           |> Array.map(item => <span> {React.string(item)} </span>)
           |> React.array}
        </p>
      </pre>
      <pre>
        <span> {React.string("string_array - ")} </span>
        <p>
          {string_array
           |> Array.map(item => <span> {React.string(item)} </span>)
           |> React.array}
        </p>
      </pre>
    </code>
    <br />
    children
  </div>;
};
