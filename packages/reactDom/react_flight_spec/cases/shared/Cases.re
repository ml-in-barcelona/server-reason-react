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

let seven_tuple_elements = {|srr emits 7-tuple element rows ["$",tag,key,props,null,null,1]; React prod emits 4-tuples ["$",type,key,props]|};

let lazy_client_refs = {|; srr references client imports as "$1" while React prod uses lazy "$L1"|};

let outlined_suspense = {|; React outlines the suspense symbol as its own row (1:"$Sreact.suspense") and references it as "$1"; srr inlines "$Sreact.suspense" as the element type; children/fallback prop order also differs|};

let all: list(case) = [
  case("element_basic", Element_basic.app, ~xfail=seven_tuple_elements),
  case("element_nested", Element_nested.app, ~xfail=seven_tuple_elements),
  case(
    "props_primitives",
    Props_primitives.app,
    ~xfail=
      seven_tuple_elements
      ++ {|; srr serializes int props as JSON strings ("tabIndex":"42" vs 42) and orders props differently|},
  ),
  case("fragment", Fragment_basic.app, ~xfail=seven_tuple_elements),
  case(
    "text_encoding",
    Text_encoding.app,
    ~xfail=
      seven_tuple_elements
      ++ {|; srr does not $$-escape text starting with "$" ("$dollar" vs React's "$$dollar")|},
  ),
  case(
    "client_component_basic",
    Client_component_basic.app,
    ~xfail=seven_tuple_elements ++ lazy_client_refs,
  ),
  case(
    "client_component_with_props",
    Client_component_with_props.app,
    ~xfail=seven_tuple_elements ++ lazy_client_refs,
  ),
  case(
    "suspense_immediate",
    Suspense_immediate.app,
    ~xfail=seven_tuple_elements ++ outlined_suspense,
  ),
  case(
    "suspense_pending",
    Suspense_pending.app,
    ~xfail=seven_tuple_elements ++ outlined_suspense,
  ),
  case(
    "promise_prop",
    Promise_prop.app,
    ~xfail=seven_tuple_elements ++ lazy_client_refs,
  ),
];
