[@react.client.component]
let make = (~initial: int => int) => {
  <button onClick={_ => initial(1)} />;
};
