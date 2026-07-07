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

let all: list(case) = [
  case("element_basic", Element_basic.app, ~xfail=seven_tuple_elements),
  case("element_nested", Element_nested.app, ~xfail=seven_tuple_elements),
  case("props_primitives", Props_primitives.app, ~xfail=seven_tuple_elements),
  case("fragment", Fragment_basic.app, ~xfail=seven_tuple_elements),
  case("text_encoding", Text_encoding.app, ~xfail=seven_tuple_elements),
];
