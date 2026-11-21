module App = {
  [@react.component]
  let make = () => {
    Spec.preload(~href="/before-ref.css", ~as_="style", ());
    <div>
      {Spec.client_component(
         ~importModule="spec/Button.js",
         ~importName="default",
         (),
       )}
    </div>;
  };
};

let app = () => <App />;
