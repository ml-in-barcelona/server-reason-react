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
                  <a href={e.path}>
                    /* onClick={event => {
                         ReactEvent.Mouse.preventDefault(event);
                         ReactRouter.push(e.path);
                       }} */
                     {e.title |> s} </a>
                </li>
              })
           |> React.list}
        </ul>
      </nav>
    </div>
  </div>;

/* let lowerWithChildrenComplex2 =
   <div className="content-wrapper">
     <div className="content">
       {let example =
          examples
          |> List.find_opt(e => {
               e.path
               == (List.nth_opt(url.path, 0) |> Option.value(~default=""))
             })
          |> Option.value(~default=firstExample);
        <div>
          <h2> {example.title |> s} </h2>
          <h4> {"Rendered component" |> s} </h4>
          {example.element}
          <h4> {"Code" |> s} </h4>
          {example.code}
        </div>}
     </div>
   </div>; */

let nestedElement = <Foo.Bar a=1 b="1" />;

/* [@react.component]
   let make = (~title, ~children) => {
     <div> ...{[<span> {title |> s} </span>, ...children]} </div>;
   }; */

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

module Row = {
  [@react.component]
  let make = (~left, ~right) =>
    <>
      <div className="md:w-1/3"> left </div>
      <div className="md:w-2/3"> right </div>
    </>;
};

[@react.component]
let make = (~children) => {
  <div className="flex xs:justify-center overflow-hidden">
    <>
      <div
        className="mt-8 md:mt-32 mx-8 md:mx-32 min-w-md lg:align-center w-full px-4 md:px-8 max-w-2xl">
        children
      </div>
    </>
  </div>;
};
