module Await = {
  [@react.component]
  let make = (~content: Js.Promise.t(React.element)) =>
    React.Experimental.usePromise(content);
};

[@react.client.component]
let make = (~content: Js.Promise.t(React.element)) =>
  <section>
    <h2 className="hn-comments-heading"> {React.string("Discussion")} </h2>
    <React.Suspense
      fallback={
        <div className="hn-state hn-loading">
          <Spinner active=true label="Loading discussion" />
          <span> {React.string("Loading discussion")} </span>
        </div>
      }>
      <Await content />
    </React.Suspense>
  </section>;
