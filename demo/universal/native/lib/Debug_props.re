[@warning "-33"];

open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make =
    (
      ~string: string,
      ~int: int,
      ~float: float,
      ~bool_true: bool,
      ~bool_false: bool,
      ~string_list: list(string),
      ~header: option(React.element),
      ~children: React.element,
      ~promise: Js.Promise.t(string),
    ) => {
  <div className="text-white">
    {switch (header) {
     | Some(header) => <header> header </header>
     | None => React.null
     }}
    <br />
    <code>
      <pre>
        <span> {React.string("string")} </span>
        <span> {React.string(string)} </span>
      </pre>
      <pre>
        <span> {React.string("int")} </span>
        <span> {React.int(int)} </span>
      </pre>
      <pre>
        <span> {React.string("float")} </span>
        <span> {React.float(float)} </span>
      </pre>
      <br />
      <pre>
        <span> {React.string("bool_true")} </span>
        <span> {React.string(bool_true ? "true" : "false")} </span>
      </pre>
      <br />
      <pre>
        <span> {React.string("bool_false")} </span>
        <span> {React.string(bool_false ? "true" : "false")} </span>
      </pre>
      <br />
      <pre>
        <span> {React.string("string_list")} </span>
        <p>
          {string_list
           |> Array.of_list
           |> Array.map(item => <span key=item> {React.string(item)} </span>)
           |> React.array}
        </p>
      </pre>
      <br />
      <pre> <span> {React.string("React.element")} </span> children </pre>
      <br />
      <pre>
        <span> {React.string("Promise")} </span>
        <br />
        <Promise_renderer promise />
      </pre>
    </code>
  </div>;
};
