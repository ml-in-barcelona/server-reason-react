[@react.client.component]
let make = (~initial: Runtime.React.server_function(int => Js.Promise.t(int))) => {
  <button onClick={_ => {initial.call(1) |> ignore}} />;
};

// to avoid unused error on "make"
let _ = make;
