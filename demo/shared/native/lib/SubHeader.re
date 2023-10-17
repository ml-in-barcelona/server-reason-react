module Cosis = {
  [@react.component]
  let make = (~onClick) => {
    <div onClick />;
  };
};

[@react.component]
let make = () => {
  let%browser_only onClick = _event => {
    Js.log("asfd");
  };

  React.useEffect0(() => {
    let _ = onClick();
    let _ = onClick();
    let _ = onClick();

    None;
  });

  <div>
    <Cosis onClick />
    <form>
      <label>
        {React.string("Name:")}
        <input type_="text" name="name" />
      </label>
      <input type_="submit" value="Submit" />
    </form>
  </div>;
};
