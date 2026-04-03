[@react.component]
let make = () => {
  let content = <div> {React.string("Ready")} </div>;

  <React.Suspense fallback={React.string("Loading...")}>
    content
  </React.Suspense>;
};
