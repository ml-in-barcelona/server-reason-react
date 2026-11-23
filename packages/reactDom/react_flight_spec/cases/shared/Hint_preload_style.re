module App = {
  [@react.component]
  let make = () => {
    Spec.preload(~href="/style.css", ~as_="style", ());
    <div> {React.string("styled")} </div>;
  };
};

let app = () => <App />;
