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
  <code
    className="inline-flex text-left items-center space-x-4 bg-stone-800 text-slate-300 rounded-lg p-4 pl-6">
    <Stack gap=3>
      <Row gap=2>
        <span className="font-bold"> {React.string("string")} </span>
        <span> {React.string(string)} </span>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("int")} </span>
        <span> {React.int(int)} </span>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("float")} </span>
        <span> {React.float(float)} </span>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("bool_true")} </span>
        <span> {React.string(bool_true ? "true" : "false")} </span>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("bool_false")} </span>
        <span> {React.string(bool_false ? "true" : "false")} </span>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("string_list")} </span>
        <Row gap=2>
          {string_list
           |> Array.of_list
           |> Array.map(item => <span key=item> {React.string(item)} </span>)
           |> React.array}
        </Row>
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("React.element")} </span>
        children
      </Row>
      <Row gap=2>
        <span className="font-bold">
          {React.string("option(React.element)")}
        </span>
        {switch (header) {
         | Some(header) => <header> header </header>
         | None => React.null
         }}
      </Row>
      <Row gap=2>
        <span className="font-bold"> {React.string("Promise")} </span>
        <Promise_renderer promise />
      </Row>
    </Stack>
  </code>;
};
