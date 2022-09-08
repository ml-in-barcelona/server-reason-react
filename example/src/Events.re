open Bindings;
open React.Dom.Dsl;
open Html;

type coords = {
  x: int,
  y: int,
};

module Title = {
  [@react.component]
  let make = (~children) => {
    <h5 style=React.Dom.Style.(make([|margin("15px 0 0")|]))> children </h5>;
  };
};

[@react.component]
let make = () => {
  let (coords, setCoords) = React.use_state(() => {x: 0, y: 0});
  let (inputText, setInputText) = React.use_state(() => "");
  <div>
    <h5> {"text input via \"onChange\"" |> React.string} </h5>
    <input
      onChange={event => {
        let value = React.Event.Form.target(event) |> Window.value;
        setInputText(_ => value);
      }}
      value=inputText
    />
    <h5> {"form submission via \"onSubmit\"" |> React.string} </h5>
    <form
      onSubmit={event => {
        React.Event.Form.prevent_default(event);
        switch (Window.get) {
        | None => ()
        | Some(w) =>
          Window.alert(
            w,
            "Quoteth Shakespeare, \"You cad! " ++ inputText ++ "\"",
          )
        };
      }}>
      <input
        onChange={event => {
          let value = React.Event.Form.target(event) |> Window.value;
          setInputText(_ => value);
        }}
        style=React.Dom.Style.(make([|margin_right("15px")|]))
        value=inputText
      />
      <button type_="submit"> {"submit dis" |> React.string} </button>
    </form>
    <h5> {"mouse movement via \"onMouseMove\"" |> React.string} </h5>
    <div>
      <img
        src="https://cdn.glitch.com/ed95e263-69d5-4c3b-aed2-d85713f4aef9%2Fdoggo.jpeg?v=1563384185147"
        onMouseMove={event => {
          let (x, y) =
            React.Event.Mouse.(screen_x(event), screen_y(event));
          setCoords(_ => {{x, y}});
        }}
      />
      <div>
        {string_of_int(coords.x)
         ++ "px / "
         ++ string_of_int(coords.y)
         ++ "px"
         |> React.string}
      </div>
    </div>
  </div>;
};
