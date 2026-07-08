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
  case(
    "children_numbers",
    Children_numbers.app,
    ~xfail=
      {|React.int/React.float children cross the wire as JSON numbers (42, 3.14, 100) in React, but srr's React.int/React.float eagerly stringify into Text at construction, emitting JSON strings ("42", "3.14", and "100." via string_of_float)|},
  ),
  case("fragment_nested", Fragment_nested.app),
  case("props_primitives", Props_primitives.app),
  case("props_float", Props_float.app),
  case("props_boolean_attributes", Props_boolean_attributes.app),
  case("props_style", Props_style.app),
  case(
    "props_style_order",
    Props_style_order.app,
    ~xfail=
      {|React preserves the style object's insertion order ({"backgroundColor":...,"color":...}); srr's ReactDOM.Style.make prepends properties in declaration order, emitting the keys reversed ({"color":...,"backgroundColor":...})|},
  ),
  case("props_aria", Props_aria.app),
  case(
    "props_aria_current",
    Props_aria_current.app,
    ~xfail=
      {|React emits "aria-current"; srr serializes it as "ariaCurrent" — the only aria attribute in DomProps.ml whose jsxName is camelCase instead of the hyphenated wire name|},
  ),
  case(
    "props_aria_booleanish",
    Props_aria_booleanish.app,
    ~xfail=
      {|React keeps raw booleans in the payload ("aria-atomic":false,"aria-hidden":true); srr stringifies booleanish aria props at JSX construction ("aria-atomic":"false","aria-hidden":"true")|},
  ),
  case("text_unicode", Text_unicode.app),
  case("text_json_specials", Text_json_specials.app),
  case("fragment", Fragment_basic.app),
  case("text_encoding", Text_encoding.app),
  case("client_component_basic", Client_component_basic.app),
  case("client_component_with_props", Client_component_with_props.app),
  case("suspense_immediate", Suspense_immediate.app),
  case("suspense_pending", Suspense_pending.app),
  case("suspense_two_boundaries", Suspense_two_boundaries.app),
  case("promise_prop", Promise_prop.app),
];
