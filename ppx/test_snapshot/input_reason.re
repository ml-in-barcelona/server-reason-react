let lower = <div />;
let lower_with_empty_attr = <div className="" />;
let lower_with_style =
  <div style={ReactDOM.Style.make(~backgroundColor="gainsboro", ())} />;
let lower_inner_html = <div dangerouslySetInnerHTML={"__html": text} />;
let lower_opt_attr = <div ?tabIndex />;
let upper = <Input />;

module React_component_without_props = {
  [@react.component]
  let make = (~lola, ~cosis) => {
    Js.log(cosis);

    <div> {React.string(lola)} </div>;
  };
};

let upper = <React_component_without_props lola="flores" />;

// Components

[@react.component]
let make = (~name="") => {
  <>
    <div> {React.string("First " ++ name)} </div>
    <Hello one="1"> {React.string("2nd " ++ name)} </Hello>
  </>;
};

module Memo = {
  [@react.component]
  let make =
    React.memo((~a) => {
      <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>
    });
};

module MemoCustomCompareProps = {
  [@react.component]
  let make =
    React.memo(
      (~a) => {
        <div> {Printf.sprintf("`a` is %d", a) |> React.string} </div>
      },
      (prevPros, nextProps) => false,
    );
};

let fragment = foo => [@bla] <> foo </>;

let polyChildrenFragment = (foo, bar) => <> foo bar </>;
let nestedFragment = (foo, bar, baz) => <> foo <> bar baz </> </>;

let nestedFragmentWithlower = foo => <> <div> foo </div> </>;

let upper = <Upper />;

let upperWithProp = <Upper count />;

let upperWithChild = foo => <Upper> foo </Upper>;

let upperWithChildren = (foo, bar) => <Upper> foo bar </Upper>;

let lower = <div />;

let lowerWithChildAndProps = foo =>
  <a tabIndex=1 href="https://example.com"> foo </a>;

let lowerWithChildren = (foo, bar) => <lower> foo bar </lower>;

let lowerWithChildrenComplex =
  <div className="flex-container">
    <div className="sidebar">
      <h2 className="title"> {"jsoo-react" |> s} </h2>
      <nav className="menu">
        <ul>
          {examples
           |> List.map(e => {
                <li key={e.path}>
                  <a
                    href={e.path}
                    onClick={event => {
                      ReactEvent.Mouse.preventDefault(event);
                      ReactRouter.push(e.path);
                    }}>
                    {e.title |> s}
                  </a>
                </li>
              })
           |> React.list}
        </ul>
      </nav>
    </div>
  </div>;

let nestedElement = <Foo.Bar a=1 b="1" />;

let t = <FancyButton ref=buttonRef> <div /> </FancyButton>;

let t = <button ref className="FancyButton"> children </button>;

[@react.component]
let make =
  React.forwardRef((~children, ~ref) => {
    <button ref className="FancyButton"> children </button>
  });

let testAttributes =
  <div translate="yes">
    <picture id="idpicture">
      <img src="picture/img.png" alt="test picture/img.png" id="idimg" />
      <source type_="image/webp" src="picture/img1.webp" />
      <source type_="image/jpeg" src="picture/img2.jpg" />
    </picture>
  </div>;

let randomElement = <text dx="1 2" dy="3 4" />;

[@react.component]
let make = (~name, ~isDisabled=?) => {
  let onClick = event => Js.log(event);
  <button name onClick disabled=isDisabled />;
};

[@react.component]
let make = (~name="joe") => {
  <div> {Printf.sprintf("`name` is %s", name) |> React.string} </div>;
};

module App = {
  [@react.component]
  let make = () => {
    <html>
      <head> <title> {React.string("SSR React")} </title> </head>
      <body>
        <div> <h1> {React.string("Wat")} </h1> </div>
        <script src="/static/client.js" />
      </body>
    </html>;
  };
};

/* It shoudn't remove this :/ */
let () = Dream.run();
let l = 33;

module Page = {
  [@react.component]
  let make = (~children, ~moreProps) => {
    <html>
      <head>
        <title> {React.string("SSR React " ++ moreProps)} </title>
      </head>
      <body>
        <div id="root"> children </div>
        <script src="/static/client.js" />
      </body>
    </html>;
  };
};

let upperWithChildren =
  <Page moreProps="hgalo"> <h1> {React.string("Yep")} </h1> </Page>;

module Container = {
  [@react.component]
  let make = (~children) => {
    <div> children </div>;
  };
};

let lower_child_static = <div> <span /> </div>;
let lower_child_ident = <div> lolaspa </div>;
let lower_child_ident = <div> <App /> </div>;

let upper_child_expr = <Div> {React.int(1)} </Div>;
let upper_child_lower = <Div> <span /> </Div>;
let upper_child_ident = <Div> lola </Div>;

<MyComponent
  booleanAttribute=true
  stringAttribute="string"
  intAttribute=1
  forcedOptional=?{Some("hello")}
  onClick={send(handleClick)}>
  <div> "hello" </div>
</MyComponent>;

<p> {React.string(greeting)} </p>;

/* module External = {
     [@react.component] [@otherAttribute "bla"]
     external component: (~a: int, ~b: string) => React.element =
       {|require("my-react-library").MyReactComponent|};
   };

   module type X_int = {let x: int;};

   module Func = (M: X_int) => {
     let x = M.x + 1;
     [@react.component]
     let make = (~a, ~b, _) => {
       print_endline("This function should be named `Test$Func`", M.x);
       <div />;
     };
   }; */
