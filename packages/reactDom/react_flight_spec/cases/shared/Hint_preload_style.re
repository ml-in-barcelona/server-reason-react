/* preload(href, {as: "style"}) called during a server component render emits
   an id-less hint row `:HL["<href>","<as>"]` before the model rows of the
   same flush. The call must happen while rendering (inside a component):
   outside a request React falls back to the client dispatcher and emits
   nothing. */
module App = {
  [@react.component]
  let make = () => {
    Spec.preload(~href="/style.css", ~as_="style", ());
    <div> {React.string("styled")} </div>;
  };
};

let app = () => <App />;
