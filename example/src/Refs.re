open Bindings;
open Js_of_ocaml;
open React.Dom.Dsl;
open Html;

module FancyLink = {
  [@react.component]
  let make =
    React.Dom.forward_ref((~href, ~repo, ref) =>
      <a ref_=ref href className="FancyLink"> {repo |> React.string} </a>
    );
};

[@react.component]
let make = () => {
  let (show, setShow) = React.use_state(() => true);
  /* You can now get a ref directly to the DOM button: */
  let ref =
    React.Dom.Ref.callback_dom_ref(ref => {
      Console.log(Js.string("Ref is:"));
      Console.log(ref);
    });
  <>
    <button
      key="toggle"
      onClick={_ => setShow(s => !s)}
      style=React.Dom.Style.(make([|margin_right("15px")|]))>
      {"Toggle fancy link" |> React.string}
    </button>
    {show
       ? <FancyLink
           href="https://github.com/ml-in-barcelona/native-react/"
           key="fancy-link"
           repo="native-react GitHub repo"
           ref
         />
       : React.null}
    <p>
      {"Open the console to see the value of the ref changing." |> React.string}
    </p>
  </>;
};
