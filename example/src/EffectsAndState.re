open Bindings;
open React.Dom.Dsl;
open Html;

type action =
  | Increment
  | Decrement;

let reducer = (state, action) =>
  switch (action) {
  | Increment => state + 1
  | Decrement => state - 1
  };

let space = {
  " " |> React.string;
};

[@react.component]
let make = (~name="Billy", ~children=?) => {
  let (count, setCount) = React.use_state(() => 0);
  let (state, dispatch) = React.use_reducer(~init=() => 0, reducer);

  <div>
    <UseEffect count />
    <p>
      {"Hello from EffectsAndState component, " ++ name ++ "!" |> React.string}
    </p>
    <button
      onClick={_ => {
        Console.log("Click!");
        setCount(c => c + 1);
      }}>
      {"Count: " ++ string_of_int(count) |> React.string}
    </button>
    space
    <button onClick={_ => dispatch @@ Decrement}>
      {"Dec" |> React.string}
    </button>
    space
    <span> {string_of_int(state) |> React.string} </span>
    space
    <button onClick={_ => dispatch @@ Increment}>
      {"Inc" |> React.string}
    </button>
    space
    {switch (children) {
     | Some(c) => <div> c </div>
     | None => React.null
     }}
  </div>;
};
