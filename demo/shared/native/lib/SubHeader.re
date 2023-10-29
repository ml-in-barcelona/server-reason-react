module Cosis = {
  [@react.component]
  let make = (~onClick) => {
    <div
      onClick={_ => {
        Js.log("asdfs");
        onClick();
      }}
    />;
  };
};

[@react.component]
let make = () => {
  let%browser_only onClick = _event => {
    Js.log("asfd");
  };

  React.useEffect0(() => {
    let _ = onClick();

    None;
  });

  React.useEffect1(
    () => {
      let _ = onClick();
      let _ = onClick();

      None;
    },
    [|onClick|],
  );

  /* <Cosis onClick /> */
  <div>
    <form>
      <label>
        {React.string("Name:")}
        <input
          onKeyPress=[%browser_only
            _ => {
              Js.log("key pressed");
            }
          ]
          type_="text"
          name="name"
        />
      </label>
      <input type_="submit" value="Submit" />
    </form>
  </div>;
};
