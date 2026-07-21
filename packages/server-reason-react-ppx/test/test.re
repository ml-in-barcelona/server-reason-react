/* Since we use -nopervasives to ensure ppx doesn't use the auto-opened Stdlib, we need to define some functions manually */
let (/.) = (a, b) => Stdlib.(a /. b);
let (-.) = (a, b) => Stdlib.(a -. b);
let (>=) = (a, b) => Stdlib.(a >= b);
let (|>) = (a, f) => f(a);

let test = (title, fn) => (
  title,
  [Alcotest_lwt.test_case("", `Quick, (_switch, ()) => Lwt.return(fn()))],
);

let sleep = (~ms) => {
  let%lwt () = Lwt_unix.sleep(Stdlib.Int.to_float(ms) /. 1000.0);
  Lwt.return();
};

let test_lwt = (title, fn) => {
  let test_case = (_switch, ()) => {
    let start = Unix.gettimeofday();
    let timeout = {
      let%lwt () = sleep(~ms=20);
      Alcotest.failf("Test '%s' timed out", title);
    };

    let%lwt test_promise = Lwt.pick([fn(), timeout]);
    let epsilon = 0.001;
    let duration = Unix.gettimeofday() -. start;
    if (Stdlib.abs_float(duration) >= epsilon) {
      Stdlib.Printf.printf(
        "\027[1m\027[33m[WARNING]\027[0m Test '%s' took %.3f seconds\n",
        title,
        duration,
      );
    } else {
      ();
    };
    Lwt.return(test_promise);
  };

  (title, [Alcotest_lwt.test_case("", `Quick, test_case)]);
};

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

let style_attribute_escaping = () => {
  /* A quoted CSS value (e.g. a font-family) must be HTML-escaped so it can't
     terminate the style="..." attribute early. This inline literal is folded
     by the PPX static-skeleton path (extract_static_style). */
  let div =
    <div
      style={ReactDOM.Style.make(~fontFamily={|"Ahrefs", sans-serif|}, ())}
    />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div style="font-family:&quot;Ahrefs&quot;, sans-serif"></div>|},
  );
};

let style_attribute_escaping_dynamic = () => {
  /* A non-literal style is emitted as a PPX Writer hole that serializes at
     render time; the quoted value must be escaped there too. */
  let style = ReactDOM.Style.make(~fontFamily={|"Ahrefs", sans-serif|}, ());
  let div = <div style />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div style="font-family:&quot;Ahrefs&quot;, sans-serif"></div>|},
  );
};

let ref_attribute = () => {
  let div = <div />;
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
  let app = <div dangerouslySetInnerHTML={ "__html": "foo" } />;
  assert_string(ReactDOM.renderToStaticMarkup(app), {|<div>foo</div>|});
};

let innerhtml_attribute_complex = () => {
  let app =
    <div dangerouslySetInnerHTML={ "__html": {|console.log("Lola")|} } />;
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
  let _divRef = React.useRef(Js.Nullable.null);
  let div = <div />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let ref_opt_attribute_none = () => {
  let div = <div />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let onClick_empty = () => {
  let onClick = Some(_ => Stdlib.print_endline("clicked"));
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
    {|<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" zoomAndPan="magnify" fill="#000000" fill-opacity="0.8" stroke="#000000" stroke-opacity="0.8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="4" stroke-dasharray="5,5" stroke-dashoffset="2" opacity="0.8" color="red" enable-background="accumulate" patternUnits="userSpaceOnUse" gradientUnits="userSpaceOnUse" gradientTransform="rotate(45)" filter="url(#myFilter)" transform="rotate(45 50 50)"><defs><filter id="myFilter"><feGaussianBlur in="SourceGraphic" stdDeviation="3"></feGaussianBlur></filter></defs></svg>|},
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

module FunctionReferences: ReactServerDOM.FunctionReferences = {
  type t = Stdlib.Hashtbl.t(string, ReactServerDOM.server_function);

  let registry = Stdlib.Hashtbl.create(10);
  let register = Stdlib.Hashtbl.add(registry);
  let get = Stdlib.Hashtbl.find_opt(registry);
};

module ServerFunction = {
  [@react.server.function]
  let simpleResponse = (~name: string, ~age: int): Js.Promise.t(string) => {
    Lwt.return(
      Stdlib.Printf.sprintf("Hello %s, you are %d years old", name, age),
    );
  };

  [@react.server.function]
  let withFormData = (~formData: Js.FormData.t): Js.Promise.t(string) => {
    let name =
      Js.FormData.get(formData, "name")
      |> (
        fun
        | `String(name) => name
      );
    let age =
      Js.FormData.get(formData, "age")
      |> (
        fun
        | `String(age) => age
      );

    Lwt.return(
      Stdlib.Printf.sprintf("Hello %s, you are %s years old", name, age),
    );
  };

  [@react.server.function]
  let withFormDataAndArgs =
      (role: string, ~formData: Js.FormData.t): Js.Promise.t(string) => {
    let name =
      Js.FormData.get(formData, "name")
      |> (
        fun
        | `String(name) => name
      );

    Lwt.return(
      Stdlib.Printf.sprintf("Hello %s, your role is %s", name, role),
    );
  };
};

let server_function = () => {
  let%lwt response =
    ServerFunction.simpleResponse.call(~name="John", ~age=30);
  assert_string(response, "Hello John, you are 30 years old");
  Lwt.return_unit;
};
let server_function_reference = () => {
  let%lwt route_response =
    FunctionReferences.get(ServerFunction.simpleResponse.id)
    |> (
      fun
      | Some(Body(handler)) => handler([|`String("John"), `Int(30)|])
      | _ => assert(false)
    );

  switch (route_response) {
  | React.Model.Json(json) =>
    assert_string(
      Melange_json.Primitives.string_of_json(json),
      "Hello John, you are 30 years old",
    );
    Lwt.return_unit;
  | _ => Stdlib.failwith("Expected a JSON response")
  };
};

let server_function_reference_args_error = () => {
  (
    try(
      FunctionReferences.get(ServerFunction.simpleResponse.id)
      |> (
        fun
        | Some(Body(handler)) => handler([|`String("John"), `Int(30)|])
        | _ => assert(false)
      )
      |> Stdlib.ignore
    ) {
    | Failure(error) =>
      assert_string(
        error,
        "server-reason-react: error on decoding argument 'age'. EXPECTED: int, RECEIVED: \"30\"",
      )
      |> Stdlib.ignore
    }
  )
  |> Stdlib.ignore;
  Lwt.return_unit;
};

let server_function_reference_form_data = () => {
  let%lwt response =
    FunctionReferences.get(ServerFunction.withFormData.id)
    |> (
      fun
      | Some(FormData(handler)) => {
          let form_data = Js.FormData.make();
          Js.FormData.append(form_data, "name", `String("John"));
          Js.FormData.append(form_data, "age", `String("30"));
          handler([||], form_data);
        }
      | _ => assert(false)
    );

  switch (response) {
  | React.Model.Json(json) =>
    assert_string(
      Melange_json.Primitives.string_of_json(json),
      "Hello John, you are 30 years old",
    );
    Lwt.return_unit;
  | _ => Stdlib.failwith("Expected a JSON response")
  };
};

let server_function_reference_form_data_and_args = () => {
  let%lwt response =
    FunctionReferences.get(ServerFunction.withFormDataAndArgs.id)
    |> (
      fun
      | Some(FormData(handler)) => {
          let form_data = Js.FormData.make();
          Js.FormData.append(form_data, "name", `String("John"));
          handler([|`String("Developer")|], form_data);
        }
      | _ => assert(false)
    );

  switch (response) {
  | React.Model.Json(json) =>
    assert_string(
      Melange_json.Primitives.string_of_json(json),
      "Hello John, your role is Developer",
    );
    Lwt.return_unit;
  | _ => Stdlib.failwith("Expected a JSON response")
  };
};

/* Text-separator protocol: renderToString must delimit adjacent text nodes
   with <!-- --> (react-dom parity — hydration splits merged text nodes at
   those comments), renderToStaticMarkup must not. These shapes go through
   the PPX static-analysis fast path (React.Static / React.Writer), which
   used to drop the separators (ahrefs/WEB-844: hydration error #418 on
   every element with adjacent text children). */

let text_separator_static_literals = () => {
  let el = <span> {React.string("beyond")} {React.string(" ")} </span>;
  assert_string(
    ReactDOM.renderToString(el),
    {|<span>beyond<!-- --> </span>|},
  );
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>beyond </span>|});
};

let text_separator_dynamic_strings = () => {
  let a = "beyond";
  let b = " ";
  let el = <span> {React.string(a)} {React.string(b)} </span>;
  assert_string(
    ReactDOM.renderToString(el),
    {|<span>beyond<!-- --> </span>|},
  );
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>beyond </span>|});
};

let text_separator_static_then_dynamic = () => {
  let b = "dynamic";
  let el = <span> {React.string("static")} {React.string(b)} </span>;
  assert_string(
    ReactDOM.renderToString(el),
    {|<span>static<!-- -->dynamic</span>|},
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(el),
    {|<span>staticdynamic</span>|},
  );
};

let text_separator_int_children = () => {
  let n = 2;
  let el = <span> {React.int(1)} {React.int(n)} </span>;
  assert_string(ReactDOM.renderToString(el), {|<span>1<!-- -->2</span>|});
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>12</span>|});
};

let text_separator_element_breaks_run = () => {
  let a = "a";
  let el = <span> {React.string(a)} <i /> {React.string("b")} </span>;
  assert_string(ReactDOM.renderToString(el), {|<span>a<i></i>b</span>|});
  assert_string(
    ReactDOM.renderToStaticMarkup(el),
    {|<span>a<i></i>b</span>|},
  );
};

module Text_separator_msg = {
  [@react.component]
  let make = (~text) => React.string(text);
};

let text_separator_component_holes = () => {
  /* Two adjacent component holes both rendering text: the runtime threads
     the text state across the holes (prev_text ref). */
  let el =
    <span>
      <Text_separator_msg text="a" />
      <Text_separator_msg text="b" />
    </span>;
  assert_string(ReactDOM.renderToString(el), {|<span>a<!-- -->b</span>|});
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>ab</span>|});
};

let text_separator_component_then_text = () => {
  /* Component hole ending with text followed by a text child. */
  let el = <span> <Text_separator_msg text="a" /> {React.string("b")} </span>;
  assert_string(ReactDOM.renderToString(el), {|<span>a<!-- -->b</span>|});
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>ab</span>|});
};

module Text_separator_heading = {
  /* The ahrefs.com LandingHero H1 shape: a component whose children mix a
     text run and a trailing element, passed as a single dynamic hole into
     a static-optimizable wrapper. The adjacency lives inside the hole's
     subtree, exercising write_element_to_buffer's internal threading. */
  [@react.component]
  let make = (~children) => <span className="text"> children </span>;
};

let text_separator_inside_single_hole = () => {
  let children =
    React.list([React.string("beyond"), React.string(" "), <i />]);
  let el =
    <h1 className="heading">
      <Text_separator_heading> children </Text_separator_heading>
    </h1>;
  assert_string(
    ReactDOM.renderToString(el),
    {|<h1 class="heading"><span class="text">beyond<!-- --> <i></i></span></h1>|},
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(el),
    {|<h1 class="heading"><span class="text">beyond <i></i></span></h1>|},
  );
};

let text_separator_empty_strings = () => {
  /* Empty text nodes participate in the text run like the tree renderer's
     Text "": they emit nothing but still delimit. */
  let empty = "";
  let static_empty = <span> {React.string("")} {React.string("a")} </span>;
  let dynamic_empty =
    <span> {React.string(empty)} {React.string("a")} </span>;
  let tree =
    React.createElement("span", [], [React.string(""), React.string("a")]);
  assert_string(
    ReactDOM.renderToString(static_empty),
    ReactDOM.renderToString(tree),
  );
  assert_string(
    ReactDOM.renderToString(dynamic_empty),
    ReactDOM.renderToString(tree),
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(static_empty),
    ReactDOM.renderToStaticMarkup(tree),
  );
};

module Text_separator_wrapped = {
  [@react.component]
  let make = (~text) => <b> {React.string(text)} </b>;
};

let text_separator_component_ending_in_element = () => {
  /* A component hole ending with an element followed by text: no separator
     (the threaded state must come back as markup, not text). */
  let el =
    <span> <Text_separator_wrapped text="a" /> {React.string("b")} </span>;
  assert_string(ReactDOM.renderToString(el), {|<span><b>a</b>b</span>|});
};

let text_separator_float_holes = () => {
  /* Float children stay on the variant-tree path (Dynamic_element); their
     text runs must still thread through the holes. */
  let f = 1.5;
  let el = <span> {React.float(f)} {React.string("x")} </span>;
  assert_string(ReactDOM.renderToString(el), {|<span>1.5<!-- -->x</span>|});
  assert_string(ReactDOM.renderToStaticMarkup(el), {|<span>1.5x</span>|});
};

let text_separator_stream = () => {
  /* renderToStream has renderToString semantics: Writer subtrees must emit
     the separators there too. */
  let a = "a";
  let el = <span> {React.string(a)} {React.string("b")} </span>;
  let%lwt (stream, _abort) = ReactDOM.renderToStream(el);
  let%lwt content = Lwt_stream.to_list(stream);
  assert_string(
    Stdlib.String.concat("", content),
    {|<span>a<!-- -->b</span>|},
  );
  Lwt.return();
};

let suspense_markers_inside_optimized_subtree = () => {
  /* Suspense boundaries inside a Writer-optimized subtree must keep their
     <!--$--> hydration markers and match the tree renderer byte-for-byte
     (the write fast path used to drop them). */
  let content = <div> {React.string("ok")} </div>;
  let suspense =
    <React.Suspense fallback={<span> {React.string("loading")} </span>}>
      content
    </React.Suspense>;
  let optimized = <section> suspense </section>;
  let tree = React.createElement("section", [], [suspense]);
  assert_string(
    ReactDOM.renderToString(optimized),
    {|<section><!--$--><div>ok</div><!--/$--></section>|},
  );
  assert_string(
    ReactDOM.renderToString(optimized),
    ReactDOM.renderToString(tree),
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(optimized),
    ReactDOM.renderToStaticMarkup(tree),
  );
};

let text_separator_matches_unoptimized_tree = () => {
  /* The optimized Writer/Static output must be byte-identical to the
     variant-tree renderer's output for the same children. */
  let a = "beyond";
  let optimized = <span> {React.string(a)} {React.string(" ")} </span>;
  let tree =
    React.createElement("span", [], [React.string(a), React.string(" ")]);
  assert_string(
    ReactDOM.renderToString(optimized),
    ReactDOM.renderToString(tree),
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(optimized),
    ReactDOM.renderToStaticMarkup(tree),
  );
};

let styles_attribute = () => {
  let styles = (
    "some-class-name",
    ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
  );
  let div = <div styles />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="some-class-name" style="background-color:gainsboro"></div>|},
  );
};

let styles_attribute_optional = () => {
  let styles = None;
  let div = <div ?styles />;
  assert_string(ReactDOM.renderToStaticMarkup(div), {|<div></div>|});
};

let styles_attribute_optional_some = () => {
  let styles =
    Some((
      "some-class-name",
      ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
    ));
  let div = <div ?styles />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="some-class-name" style="background-color:gainsboro"></div>|},
  );
};

let styles_attribute_optional_some_with_class = () => {
  let styles =
    Some((
      "some-class-name",
      ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
    ));
  let div = <div className="lola" ?styles />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="some-class-name lola" style="background-color:gainsboro"></div>|},
  );
};

let styles_attribute_optional_some_with_style = () => {
  let styles =
    Some((
      "some-class-name",
      ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
    ));
  let div = <div style={ReactDOM.Style.make(~color="white", ())} ?styles />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="some-class-name" style="color:white;background-color:gainsboro"></div>|},
  );
};

let styles_attribute_optional_some_with_class_and_style = () => {
  let styles =
    Some((
      "some-class-name",
      ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
    ));
  let div =
    <div
      className="lola"
      style={ReactDOM.Style.make(~color="white", ())}
      ?styles
    />;
  assert_string(
    ReactDOM.renderToStaticMarkup(div),
    {|<div class="some-class-name lola" style="color:white;background-color:gainsboro"></div>|},
  );
};

/* Regression: expected-type propagation for optional host-element props.
   `Shadowed_none.None` shadows option's `None` (mirroring ahkit's
   `roundness`). The Writer fast path must annotate the optional attribute
   scrutinee with its concrete option type; otherwise the bare `None` in
   `disabled ? None : Some(href)` resolves to `Shadowed_none.None` and this
   module fails to type-check. This whole module not compiling *is* the
   regression — see docs/srr-styled-ppx-jsx-type-propagation-fix-plan.md. */
module Shadowed_none = {
  type roundness =
    | Full
    | None;

  /* Build both constructors so the shadow is genuine (not a pattern-only
     constructor) and we don't trip the unused-constructor warning. */
  let _variants = [Full, None];

  let link = (~href, ~disabled) =>
    <a href=?{disabled ? None : Some(href)}> {React.string("x")} </a>;

  let link_with_styles = (~href, ~disabled, ~styles) =>
    <a styles href=?{disabled ? None : Some(href)}> {React.string("x")} </a>;
};

let optional_prop_with_shadowed_none = () => {
  assert_string(
    ReactDOM.renderToStaticMarkup(
      Shadowed_none.link(~href="/blog", ~disabled=false),
    ),
    {|<a href="/blog">x</a>|},
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(
      Shadowed_none.link(~href="/blog", ~disabled=true),
    ),
    {|<a>x</a>|},
  );
};

let optional_prop_with_shadowed_none_and_styles = () => {
  let styles = ("klass", ReactDOM.Style.make(~color="red", ()));
  assert_string(
    ReactDOM.renderToStaticMarkup(
      Shadowed_none.link_with_styles(~href="/blog", ~disabled=false, ~styles),
    ),
    {|<a class="klass" style="color:red" href="/blog">x</a>|},
  );
};

module Memo_plain = {
  [@react.component]
  let make = (~a) =>
    <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>;
};

module Memo_inline = {
  [@react.component]
  let make =
    React.memo((~a) =>
      <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>
    );
};

module Memo_wrapping_make = {
  [@react.component]
  let make = (~a) =>
    <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>;
  let make = React.memo(make);
};

module Memo_custom_compare_inline = {
  [@react.component]
  let make =
    React.memoCustomCompareProps(
      (~a) => <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>,
      (_prevProps, _nextProps) => false,
    );
};

module Memo_custom_compare_wrapping_make = {
  [@react.component]
  let make = (~a) =>
    <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>;
  let make =
    React.memoCustomCompareProps(make, (_prevProps, _nextProps) => false);
};

let memo_renders_like_the_unmemoized_component = () => {
  let expected = ReactDOM.renderToStaticMarkup(<Memo_plain a="foo" />);
  assert_string(
    ReactDOM.renderToStaticMarkup(<Memo_inline a="foo" />),
    expected,
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(<Memo_wrapping_make a="foo" />),
    expected,
  );
};

let memo_custom_compare_renders_like_the_unmemoized_component = () => {
  let expected = ReactDOM.renderToStaticMarkup(<Memo_plain a="foo" />);
  assert_string(
    ReactDOM.renderToStaticMarkup(<Memo_custom_compare_inline a="foo" />),
    expected,
  );
  assert_string(
    ReactDOM.renderToStaticMarkup(
      <Memo_custom_compare_wrapping_make a="foo" />,
    ),
    expected,
  );
};

Alcotest_lwt.run(
  "server-reason-react.ppx",
  [
    test("tag", tag),
    test(
      "memo_renders_like_the_unmemoized_component",
      memo_renders_like_the_unmemoized_component,
    ),
    test(
      "memo_custom_compare_renders_like_the_unmemoized_component",
      memo_custom_compare_renders_like_the_unmemoized_component,
    ),
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
    test("style_attribute_escaping", style_attribute_escaping),
    test(
      "style_attribute_escaping_dynamic",
      style_attribute_escaping_dynamic,
    ),
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
    test("text_separator_static_literals", text_separator_static_literals),
    test("text_separator_dynamic_strings", text_separator_dynamic_strings),
    test(
      "text_separator_static_then_dynamic",
      text_separator_static_then_dynamic,
    ),
    test("text_separator_int_children", text_separator_int_children),
    test(
      "text_separator_element_breaks_run",
      text_separator_element_breaks_run,
    ),
    test("text_separator_component_holes", text_separator_component_holes),
    test(
      "text_separator_component_then_text",
      text_separator_component_then_text,
    ),
    test(
      "text_separator_inside_single_hole",
      text_separator_inside_single_hole,
    ),
    test(
      "text_separator_matches_unoptimized_tree",
      text_separator_matches_unoptimized_tree,
    ),
    test(
      "suspense_markers_inside_optimized_subtree",
      suspense_markers_inside_optimized_subtree,
    ),
    test("text_separator_empty_strings", text_separator_empty_strings),
    test(
      "text_separator_component_ending_in_element",
      text_separator_component_ending_in_element,
    ),
    test("text_separator_float_holes", text_separator_float_holes),
    test_lwt("text_separator_stream", text_separator_stream),
    test("styles_attribute", styles_attribute),
    test("styles_attribute_optional", styles_attribute_optional),
    test("styles_attribute_optional_some", styles_attribute_optional_some),
    test(
      "styles_attribute_optional_some_with_class",
      styles_attribute_optional_some_with_class,
    ),
    test(
      "styles_attribute_optional_some_with_style",
      styles_attribute_optional_some_with_style,
    ),
    test(
      "styles_attribute_optional_some_with_class_and_style",
      styles_attribute_optional_some_with_class_and_style,
    ),
    test(
      "optional_prop_with_shadowed_none",
      optional_prop_with_shadowed_none,
    ),
    test(
      "optional_prop_with_shadowed_none_and_styles",
      optional_prop_with_shadowed_none_and_styles,
    ),
    test_lwt("server_function", server_function),
    test_lwt("server_function_reference", server_function_reference),
    test_lwt(
      "server_function_reference_args_error",
      server_function_reference_args_error,
    ),
    test_lwt(
      "server_function_reference_form_data",
      server_function_reference_form_data,
    ),
    test_lwt(
      "server_function_reference_form_data_and_args",
      server_function_reference_form_data_and_args,
    ),
  ],
);
