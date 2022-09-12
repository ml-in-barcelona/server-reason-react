open ReactDom.Dsl;
open Html;

let s = React.string;

type example = {
  path: string,
  title: string,
  element: React.element,
  code: React.element,
  showTitle: bool,
};

let firstExample = {
  path: "hello-world-ocaml",
  title: "Hello World OCaml",
  element: <HelloWorldOCaml />,
  code: <Code text=[%blob "HelloWorldOCaml.ml"] />,
  showTitle: true,
};
let examples = [
  firstExample,
  {
    path: "hello-world-reason",
    title: "Hello World Reason",
    element: <HelloWorldReason />,
    code: <Code text=[%blob "HelloWorldReason.re"] />,
    showTitle: true,
  },
  {
    path: "events",
    title: "Events",
    element: <Events />,
    code: <Code text=[%blob "Events.re"] />,
    showTitle: true,
  },
  {
    path: "effects-and-state",
    title: "Effects and state",
    element: <EffectsAndState />,
    code:
      <>
        <p> {"EffectsAndState component:" |> s} </p>
        <Code text=[%blob "EffectsAndState.re"] />
        <p> {"UseEffect component:" |> s} </p>
        <Code text=[%blob "UseEffect.re"] />
      </>,
    showTitle: true,
  },
  {
    path: "refs",
    title: "Refs",
    element: <Refs />,
    code: <Code text=[%blob "Refs.re"] />,
    showTitle: true,
  },
  {
    path: "web-components",
    title: "Web Components",
    element:
      <div style=ReactDom.Style.(make([|height("50vw")|]))>
        <WebComponent />
      </div>,
    code: <Code text=[%blob "WebComponent.ml"] />,
    showTitle: true,
  },
  {
    path: "interfaces",
    title: "Interface files",
    element:
      <Interface
        key="inter"
        title="native-react PPX is not needed in interface files, as module signatures are the same as the original function, but including the `key` optional param.">
        React.null
      </Interface>,
    code:
      <div>
        <strong> {"Interface" |> s} </strong>
        <Code text=[%blob "Interface.rei"] />
        <strong> {"Implementation" |> s} </strong>
        <Code text=[%blob "Interface.re"] />
      </div>,
    showTitle: false,
  },
  {
    path: "bindings",
    title: "Bindings to JavaScript code",
    element:
      <p>
        {"Bindings can be written easily by using " |> s}
        <a href="https://github.com/LexiFi/gen_js_api" target="_blank">
          {"gen_js_api" |> s}
        </a>
        {"." |> s}
      </p>,
    code: <Code text=[%blob "Bindings.rei"] />,
    showTitle: false,
  },
  {
    path: "ppxs",
    title: "PPXs (preprocessing extensions)",
    element:
      <>
        <p>
          {"You have seen the embedded code snippets in the examples. The one below is from the Main component of this page."
           |> s}
          <code> {"Interface.re" |> s} </code>
          {"." |> s}
        </p>
        <p>
          {"These snippets always stay in sync with the code itself. The strings from the files get captured at compile time via a "
           |> s}
          <a
            href="https://victor.darvariu.me/jekyll/update/2018/06/19/ppx-tutorial.html"
            target="_blank">
            {"ppx" |> s}
          </a>
          {" (preprocessor extension) that is called " |> s}
          <a href="https://github.com/johnwhitington/ppx_blob" target="_blank">
            {"ppx_blob" |> s}
          </a>
          {" by calling " |> s}
          <code> {"<Code text=[%blob \"SomeComponent.re\"] />" |> s} </code>
          {". Then, we just pass that string to a component " |> s}
          <code> {"Code" |> s} </code>
          {"." |> s}
        </p>
        <p>
          {"Here is the implementation of" |> s}
          <code> {"Code.re" |> s} </code>
          {":" |> s}
        </p>
      </>,
    code: <Code text=[%blob "Code.re"] />,
    showTitle: false,
  },
];

[@react.component]
let make = () => {
  let url = React.Router.use_url();

  <div className="flex-container">
    <div className="sidebar">
      <h2 className="title"> {"native-react" |> s} </h2>
      <nav className="menu">
        <ul>
          ...{
               examples
               |> List.map(e => {
                    <li key={e.path}>
                      <a
                        href={e.path}
                        onClick={event => {
                          React.Event.Mouse.prevent_default(event);
                          React.Router.push(e.path);
                        }}>
                        {e.title |> s}
                      </a>
                    </li>
                  })
             }
        </ul>
      </nav>
    </div>
    <div className="content-wrapper">
      <div className="content">
        {let example =
           examples
           |> List.find_opt(e => {
                e.path
                == (
                     List.length(url.path) > 0
                       ? List.nth_opt(url.path, List.length(url.path) - 1)
                         |> Option.value(~default="")
                       : ""
                   )
              })
           |> Option.value(~default=firstExample);
         <div>
           <h2> {example.title |> s} </h2>
           {example.showTitle
              ? <h4> {"Rendered component" |> s} </h4> : React.null}
           {example.element}
           <h4> {"Code" |> s} </h4>
           {example.code}
         </div>}
      </div>
    </div>
  </div>;
};
