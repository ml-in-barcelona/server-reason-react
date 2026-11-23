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
