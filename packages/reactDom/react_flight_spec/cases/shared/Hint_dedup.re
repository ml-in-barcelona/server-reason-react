/* The same preload called twice in one request emits a single H row: React
   dedups per request on the key "L[<as>]<href>" ("D|<href>", "C|<cors>|<href>",
   "X|<src>" for the other kinds). A different `as` for the same href is a
   different key and emits again. */
module App = {
  [@react.component]
  let make = () => {
    Spec.preload(~href="/style.css", ~as_="style", ());
    Spec.preload(~href="/style.css", ~as_="style", ());
    Spec.preload(~href="/style.css", ~as_="fetch", ());
    <div> {React.string("deduped")} </div>;
  };
};

let app = () => <App />;
