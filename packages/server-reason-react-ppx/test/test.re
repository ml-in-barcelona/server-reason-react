let test = (title, fn) => (title, [Alcotest.test_case("", `Quick, fn)]);

let assert_string = (left, right) => {
  Alcotest.check(Alcotest.string, "should be equal", right, left);
};

let tag = () => {
  assert_string(ReactDOM.renderToStaticMarkup(<div />), {|<div></div>|});
};

let empty_attribute = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(<div className="" />),
    {|<div class=""></div>|},
  );
};

let bool_attribute = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(<div hidden=true />),
    {|<div hidden></div>|},
  );
};

let bool_attributes = () => {
  let input =
    <input type_="checkbox" name="cheese" checked=true disabled=false />;
  assert_string(
    ReactDOM.renderToStaticMarkup(input),
    {|<input type="checkbox" name="cheese" checked />|},
  );
};

let innerhtml = () => {
  let p = <p> {React.string("text")} </p>;
  assert_string(ReactDOM.renderToStaticMarkup(p), "<p>text</p>");
};

let int_attribute = () => {
  let div = <div tabIndex=1 />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div tabindex="1"></div>|},
  );
};

let style_attribute = () => {
  let div =
    <div style={ReactDOM.Style.make(~backgroundColor="gainsboro", ())} />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div style="background-color:gainsboro"></div>|},
  );
};

let ref_attribute = () => {
  let divRef = React.useRef(Js.Nullable.null);
  let div = <div ref={React.Ref.domRef(divRef)} />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let link_as_attribute = () => {
  let link = <link as_="image" rel="preload" href="https://sancho.dev/blog" />;
  assert_string(
    ReactDOM.renderToStaticMarkup(link),
    {|<link as="image" rel="preload" href="https://sancho.dev/blog" />|},
  );
};

let innerhtml_attribute = () => {
  let app = <div dangerouslySetInnerHTML={"__html": "foo"} />;
  assert_string(ReactDOM.renderToStaticMarkup(app), {|<div>foo</div>|});
};

let innerhtml_attribute_complex = () => {
  let app =
    <div dangerouslySetInnerHTML={"__html": {|console.log("Lola")|}} />;
  assert_string(
    ReactDOM.renderToStaticMarkup(app),
    {|<div>console.log("Lola")</div>|},
  );
};

let int_opt_attribute_some = () => {
  let tabIndex = Some(1);
  let div = <div ?tabIndex />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div tabindex="1"></div>|},
  );
};

let int_opt_attribute_none = () => {
  let tabIndex = None;
  let div = <div ?tabIndex />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let fragment = () => {
  let app = <> <div className="md:w-1/3" /> <div className="md:w-2/3" /> </>;
  assert_string(
    ReactDOM.renderToStaticMarkup(app),
    {|<div class="md:w-1/3"></div><div class="md:w-2/3"></div>|},
  );
};

let fragment_with_key = () => {
  let app =
    <React.Fragment key="asd">
      <div className="md:w-1/3" />
      <div className="md:w-2/3" />
    </React.Fragment>;
  assert_string(
    ReactDOM.renderToStaticMarkup(app),
    {|<div class="md:w-1/3"></div><div class="md:w-2/3"></div>|},
  );
};

module Container = {
  [@react.component]
  let make = (~children) => <div> children </div>;
};

let children_uppercase = () => {
  let component = <Container> <span /> </Container>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    {|<div><span></span></div>|},
  );
};

let children_lowercase = () => {
  let component = <div> <span /> </div>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    {|<div><span></span></div>|},
  );
};

let string_opt_attribute_some = () => {
  let className = Some("foo");
  let div = <div ?className />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="foo"></div>|},
  );
};

let string_opt_attribute_none = () => {
  let className = None;
  let div = <div ?className />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let bool_opt_attribute_some = () => {
  let hidden = Some(true);
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div hidden></div>|});
};

let bool_opt_attribute_none = () => {
  let hidden = None;
  let div = <div ?hidden />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let style_opt_attribute_some = () => {
  let style = Some(ReactDOM.Style.make(~backgroundColor="gainsboro", ()));
  let div = <div ?style />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div style="background-color:gainsboro"></div>|},
  );
};

let style_opt_attribute_none = () => {
  let style = None;
  let div = <div ?style />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let ref_opt_attribute_some = () => {
  let divRef = React.useRef(Js.Nullable.null);
  let ref = Some(React.Ref.domRef(divRef));
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let ref_opt_attribute_none = () => {
  let ref = None;
  let div = <div ?ref />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let onClick_empty = () => {
  let onClick = Some(_ => print_endline("clicked"));
  let div = <div ?onClick />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let svg_1 = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        width="24px"
        height="24px">
        <path
          d="M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z"
        />
      </svg>,
    ),
    {|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24px" height="24px"><path d="M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z"></path></svg>|},
  );
};

let svg_2 = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <svg
        width="100"
        height="100"
        xmlns="http://www.w3.org/2000/svg"
        xmlnsXlink="http://www.w3.org/1999/xlink"
        version="1.1"
        baseProfile="full"
        viewBox="0 0 100 100"
        preserveAspectRatio="xMidYMid meet"
        zoomAndPan="magnify"
        fill="#000000"
        fillOpacity="0.8"
        stroke="#000000"
        strokeOpacity="0.8"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeMiterlimit="4"
        strokeDasharray="5,5"
        strokeDashoffset="2"
        opacity="0.8"
        color="red"
        enableBackground="accumulate"
        patternUnits="userSpaceOnUse"
        gradientUnits="userSpaceOnUse"
        gradientTransform="rotate(45)"
        filter="url(#myFilter)"
        transform="rotate(45 50 50)">
        <defs>
          <filter id="myFilter">
            <feGaussianBlur in_="SourceGraphic" stdDeviation="3" />
          </filter>
        </defs>
      </svg>,
    ),
    {|<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg" xmlnsXlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" zoomAndPan="magnify" fill="#000000" fill-opacity="0.8" stroke="#000000" stroke-opacity="0.8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="4" stroke-dasharray="5,5" stroke-dashoffset="2" opacity="0.8" color="red" enable-background="accumulate" patternUnits="userSpaceOnUse" gradientUnits="userSpaceOnUse" gradientTransform="rotate(45)" filter="url(#myFilter)" transform="rotate(45 50 50)"><defs><filter id="myFilter"><feGaussianBlur in="SourceGraphic" stdDeviation="3"></feGaussianBlur></filter></defs></svg>|},
  );
};

let booleanish_props_with_ppx = () => {
  /* This is just a few examples */
  let div =
    <div
      spellCheck=false
      ariaDisabled=true
      ariaHidden=false
      ariaExpanded=false
      draggable=true
    />;

  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div spellcheck="false" aria-disabled="true" aria-hidden="false" aria-expanded="false" draggable="true"></div>|},
  );
};

let booleanish_props_without_ppx = () => {
  let div =
    React.createElement(
      "div",
      ReactDOM.domProps(
        ~spellCheck=false,
        ~ariaDisabled=true,
        ~ariaHidden=false,
        ~ariaExpanded=false,
        ~draggable=true,
        (),
      ),
      [],
    );

  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div spellcheck="false" draggable="true" aria-expanded="false" aria-hidden="false" aria-disabled="true"></div>|},
  );
};

module Component = {
  [@react.component]
  let make = (~children: React.element, ~cosas as _) => {
    <div> children </div>;
  };
};

let children_one_element = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <Component cosas=true> <span /> </Component>,
    ),
    {|<div><span></span></div>|},
  );
};
let children_multiple_elements = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <Component cosas=false> <div> <span /> </div> <span /> </Component>,
    ),
    {|<div><div><span></span></div><span></span></div>|},
  );
};

module Text = {
  module Tag = {
    type t =
      | H1;

    let unwrap =
      fun
      | H1 => "h1";
  };

  [@react.component]
  let make = (~tagType, ~children: React.element) => {
    ReactDOM.createDOMElementVariadic(
      tagType |> Tag.unwrap,
      ~props=
        ReactDOM.domProps(
          ~className="foo",
          ~style=ReactDOM.Style.make(~display="none", ()),
          (),
        ),
      React.Children.toArray(children),
    );
  };
};

let create_element_variadic = () => {
  let component = <Text tagType=Text.Tag.H1> {React.string("Hello")} </Text>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    {|<h1 style="display:none" class="foo">Hello</h1>|},
  );
};

let aria_props = () => {
  let component =
    <h1 ariaHidden=true ariaLabel="send email" ariaAtomic=true>
      {React.string("Hello")}
    </h1>;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    {|<h1 aria-hidden="true" aria-label="send email" aria-atomic="true">Hello</h1>|},
  );
};

module Optional_prop = {
  [@react.component]
  let make = () => {
    let target = None;

    <a href="/" ?target> {React.string("...")} </a>;
  };
};

let optional_prop = () => {
  let component = <Optional_prop />;
  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    {|<a href="/">...</a>|},
  );
};

let context = React.createContext(10);

module ContextProvider = {
  include React.Context;
  let make = React.Context.provider(context);
};

module ContextConsumer = {
  [@react.component]
  let make = () => {
    let value = React.useContext(context);
    <section> {React.int(value)} </section>;
  };
};

let context = () => {
  let component =
    <ContextProvider value=20> <ContextConsumer /> </ContextProvider>;

  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<section>20</section>",
  );
};

let context_2 = () => {
  let component =
    <ContextProvider value=30> <ContextConsumer /> </ContextProvider>;

  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<section>30</section>",
  );
};

let multiple_contexts = () => {
  let _component =
    <ContextProvider value=20> <ContextConsumer /> </ContextProvider>;

  let component =
    <ContextProvider value=30> <ContextConsumer /> </ContextProvider>;

  assert_string(
    ReactDOM.renderToStaticMarkup(component),
    "<section>30</section>",
  );
};

Alcotest.run(
  "server-reason-react.ppx",
  [
    test("tag", tag),
    test("empty_attribute", empty_attribute),
    test("bool_attribute", bool_attribute),
    test("bool_attributes", bool_attributes),
    test("innerhtml", innerhtml),
    test("int_attribute", int_attribute),
    test("svg_1", svg_1),
    test("svg_2", svg_2),
    test("booleanish_props_with_ppx", booleanish_props_with_ppx),
    test("booleanish_props_without_ppx", booleanish_props_without_ppx),
    test("style_attribute", style_attribute),
    test("ref_attribute", ref_attribute),
    test("link_as_attribute", link_as_attribute),
    test("inner_html_attribute", innerhtml_attribute),
    test("inner_html_attribute_complex", innerhtml_attribute_complex),
    test("int_opt_attr_some", int_opt_attribute_some),
    test("int_opt_attribute_none", int_opt_attribute_none),
    test("string_opt_attribute_some", string_opt_attribute_some),
    test("string_opt_attribute_none", string_opt_attribute_none),
    test("bool_opt_attribute_some", bool_opt_attribute_some),
    test("bool_opt_attribute_none", bool_opt_attribute_none),
    test("style_opt_attribute_some", style_opt_attribute_some),
    test("style_opt_attribute_none", style_opt_attribute_none),
    test("ref_opt_attribute_some", ref_opt_attribute_some),
    test("ref_opt_attribute_none", ref_opt_attribute_none),
    test("fragment", fragment),
    test("fragment_with_key", fragment_with_key),
    test("children_uppercase", children_uppercase),
    test("children_lowercase", children_lowercase),
    test("event_onClick", onClick_empty),
    test("children_one_element", children_one_element),
    test("children_multiple_elements", children_multiple_elements),
    test("create_element_variadic", create_element_variadic),
    test("aria_props", aria_props),
    test("optional_prop", optional_prop),
    test("context", context),
    test("context_2", context_2),
    test("multiple_contexts", multiple_contexts),
  ],
);
