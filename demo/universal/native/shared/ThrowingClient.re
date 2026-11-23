module Inner = {
  [@react.component]
  let make = () => {
    switch%platform () {
    | Native => failwith("ThrowingClient: intentional server-side error")
    | Melange =>
      <p className="font-mono text-green-400">
        {React.string(
           "Recovered: the client re-rendered this boundary after the server render errored",
         )}
      </p>
    };
  };
};

[@react.client.component]
let make = () => {
  <React.Suspense fallback={React.string("Loading...")}>
    <Inner />
  </React.Suspense>;
};
