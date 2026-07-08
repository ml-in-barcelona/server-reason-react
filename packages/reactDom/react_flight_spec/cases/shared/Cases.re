/* The single-source registry of spec cases. Compiled both natively (rendered
   by ReactServerDOM.render_model) and via melange (rendered by the real
   react-server-dom-webpack in generate.mjs).

   [xfail]: Some(reason) marks a KNOWN divergence between srr and React. The
   conformance runner asserts that those cases DO mismatch, so they flip
   loudly once fixed. generate.mjs ignores the annotation. */

type case = {
  name: string,
  render: unit => React.element,
  xfail: option(string),
};

let case = (~xfail=?, name: string, render: unit => React.element): case => {
  name,
  render,
  xfail,
};

let all: list(case) = [
  case("element_basic", Element_basic.app),
  case("element_nested", Element_nested.app),
  case("props_primitives", Props_primitives.app),
  case("props_float", Props_float.app),
  case("fragment", Fragment_basic.app),
  case("text_encoding", Text_encoding.app),
  case("client_component_basic", Client_component_basic.app),
  case("client_component_with_props", Client_component_with_props.app),
  case("suspense_immediate", Suspense_immediate.app),
  case("suspense_pending", Suspense_pending.app),
  case("suspense_two_boundaries", Suspense_two_boundaries.app),
  case("suspense_nested", Suspense_nested.app),
  case("suspense_inner_pending", Suspense_inner_pending.app),
  case(
    "suspense_no_fallback",
    Suspense_no_fallback.app,
    ~xfail=
      {|srr serializes a missing Suspense fallback as "fallback":null; React omits the prop entirely: {"children":...}|},
  ),
  case("suspense_with_key", Suspense_with_key.app),
  case("suspense_resolution_order", Suspense_resolution_order.app),
  case("suspense_multiple_children", Suspense_multiple_children.app),
  case("suspense_deeply_nested", Suspense_deeply_nested.app),
  case("promise_prop", Promise_prop.app),
  case(
    "error_component",
    Error_component.app,
    ~xfail=
      {|a sync throw at the ROOT errors the root task itself in React (single row 0:E{...}); srr outlines the error and emits 1:E{...} then 0:"$L1"|},
  ),
  case(
    "error_row_reference",
    Error_row_reference.app,
    ~xfail=
      {|row ORDER: React flushes E rows after model rows (0: then 1:E); srr pushes the outlined error row before completing the root row (1:E then 0:). Row contents match, including the "$L1" reference|},
  ),
  case(
    "error_in_suspense_sync",
    Error_in_suspense_sync.app,
    ~xfail=
      {|row ORDER: React flushes E rows after model rows (1: 0: 2:E); srr emits the error row before the root row (1: 2:E 0:). Row contents match, including the "$L2" children reference|},
  ),
  case("error_in_async_component", Error_in_async_component.app),
];
