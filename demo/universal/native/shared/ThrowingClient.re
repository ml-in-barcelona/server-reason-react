/* Demonstrates a client component whose server render fails: the Suspense
   boundary lives inside the client tree, so the server flushes it in errored
   form (<!--$!--> template with the error detail in dev) instead of a silent
   blank, and the browser retries rendering it client-side, where it succeeds. */

module Inner = {
  [@react.component]
  let make = () => {
    switch%platform () {
    | Server => failwith("ThrowingClient: intentional server-side error")
    | Client =>
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
  <React.Suspense fallback={React.string("Loading...")}> <Inner /> </React.Suspense>;
};
