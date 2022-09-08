type action =
  | Clicked(int, int);

let reducer = (state, action) =>
  switch (action) {
  | Clicked(x, y) => [(x, y), ...state]
  };

[@react.component]
let make = () => {
  let (state, dispatch) = React.use_reducer(~init=[], reducer);
  <div
    style=React.Dom.Style.(make([|color("#ff5544"), fontSize("68px")|]))
    onClick={event => {
      dispatch @@
      React.Event.Mouse.(Clicked(event |> clientX, event |> clientY))
    }}>
    {"Hello" |> React.string}
    {"Pos: "
     ++ String.concat(
          "\n",
          state
          |> List.map(((x, y)) =>
               string_of_int(x) ++ ", " ++ string_of_int(y)
             ),
        )
     |> React.string}
  </div>;
};
