[@react.client.component]
let make = (~initial: int => int) => {
  <button onClick={_ => initial(1)} />;
};

// to avoid unused error on "make"
let _ = make;
