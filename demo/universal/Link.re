[@react.component]
let make = (~url, ~txt) => {
  <a
    className="text-blue-500 hover:text-blue-800"
    href=url
    onClick={e => {
      React.Event.Mouse.preventDefault(
        e,
        /* ReasonReactRouter.push(url); */
      )
    }}>
    {React.string(txt)}
  </a>;
};

[@platform js]
module T = {
  let t = Js.Json.string("foo");
};

[@platform native]
module T = {
  let t: string = "foo";
};

let t = T.t;
