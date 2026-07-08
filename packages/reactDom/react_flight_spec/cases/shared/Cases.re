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
  case("element_keys", Element_keys.app),
  case("element_key_on_root", Element_key_on_root.app),
  case("element_empty_props", Element_empty_props.app),
  case("element_void", Element_void.app),
  case("deep_nesting", Deep_nesting.app),
  case("large_array", Large_array.app),
  case("children_mixed", Children_mixed.app),
  case("children_null", Children_null.app),
  case("children_numbers", Children_numbers.app),
  case("fragment_nested", Fragment_nested.app),
  case("props_primitives", Props_primitives.app),
  case("props_float", Props_float.app),
  case("props_boolean_attributes", Props_boolean_attributes.app),
  case("props_style", Props_style.app),
  case("props_style_order", Props_style_order.app),
  case("props_aria", Props_aria.app),
  case("props_aria_current", Props_aria_current.app),
  case("props_aria_booleanish", Props_aria_booleanish.app),
  case("text_unicode", Text_unicode.app),
  case("text_json_specials", Text_json_specials.app),
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
  case("async_component_nested", Async_component_nested.app),
  case("async_component_root_resolved", Async_component_root_resolved.app),
  case("async_component_root_rejected", Async_component_root_rejected.app),
  case("suspense_immediate", Suspense_immediate.app),
  case("suspense_pending", Suspense_pending.app),
  case("suspense_two_boundaries", Suspense_two_boundaries.app),
  case("suspense_nested", Suspense_nested.app),
  case("suspense_inner_pending", Suspense_inner_pending.app),
  case("suspense_no_fallback", Suspense_no_fallback.app),
  case("suspense_null_fallback", Suspense_null_fallback.app),
  case("suspense_with_key", Suspense_with_key.app),
  case("suspense_resolution_order", Suspense_resolution_order.app),
  case("suspense_multiple_children", Suspense_multiple_children.app),
  case("suspense_deeply_nested", Suspense_deeply_nested.app),
  case("promise_prop", Promise_prop.app),
  case("promise_prop_two", Promise_prop_two.app),
  case("promise_prop_resolved", Promise_prop_resolved.app),
  case("promise_prop_rejected", Promise_prop_rejected.app),
  case("promise_resolving_to_element", Promise_resolving_to_element.app),
  case("promise_prop_shared", Promise_prop_shared.app),
  case(
    "promise_shared_across_components",
    Promise_shared_across_components.app,
  ),
  case("error_component", Error_component.app),
  case("error_in_root_chain", Error_in_root_chain.app),
  case("error_row_reference", Error_row_reference.app),
  case("error_in_suspense_sync", Error_in_suspense_sync.app),
  case("error_in_async_component", Error_in_async_component.app),
];
