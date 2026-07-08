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
  case(
    "async_component_nested",
    Async_component_nested.app,
    ~xfail=
      {|React retries a suspended task in place: an async component at the task root resolves into its own row (0:["$","div",...,"$L1"]) and only the NESTED async component is outlined. srr outlines every async component, emitting 0:"$L1" and shifting the chain to rows 1 ("$L2") and 2|},
  ),
  case("suspense_immediate", Suspense_immediate.app),
  case("suspense_pending", Suspense_pending.app),
  case("suspense_two_boundaries", Suspense_two_boundaries.app),
  case("promise_prop", Promise_prop.app),
  case("promise_prop_two", Promise_prop_two.app),
  case("promise_resolving_to_element", Promise_resolving_to_element.app),
  case(
    "promise_prop_shared",
    Promise_prop_shared.app,
    ~xfail=
      {|React dedups a shared thenable via writtenObjects: {"left":"$@2","right":"$@2"} with a single resolution row 2. srr wraps each prop in its own Model.Promise and never dedups, emitting {"left":"$@2","right":"$@3"} plus two identical resolution rows (3 streams before 2)|},
  ),
];
