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
  case("client_ref_dedup", Client_ref_dedup.app),
  case("client_ref_two_modules", Client_ref_two_modules.app),
  case(
    "client_ref_same_module_two_names",
    Client_ref_same_module_two_names.app,
  ),
  case("client_with_children", Client_with_children.app),
  case("client_nested_in_client", Client_nested_in_client.app),
  case("client_props_kitchen_sink", Client_props_kitchen_sink.app),
  case("client_prop_array_and_object", Client_prop_array_and_object.app),
  case("model_null", Model_null.app),
  case("suspense_immediate", Suspense_immediate.app),
  case("suspense_pending", Suspense_pending.app),
  case("suspense_two_boundaries", Suspense_two_boundaries.app),
  case("promise_prop", Promise_prop.app),
];
