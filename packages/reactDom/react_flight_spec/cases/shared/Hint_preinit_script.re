/* preinit(href, {as: "script"}) emits `:HX"<href>"` (the [src, options]
   tuple form only appears when options survive trimming). */
module App = {
  [@react.component]
  let make = () => {
    Spec.preinit_script(~href="/main.js");
    <div> {React.string("initialized")} </div>;
  };
};

let app = () => <App />;
