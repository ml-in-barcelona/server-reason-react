module Nested = {
  [@react.client.component]
  let make =
      (
        ~initial: int,
        ~lola: lola,
        ~children: React.element,
        ~promise: Js.Promise.t(string),
      ) => {
    let value = React.Experimental.use(promise);
    <div>
      {React.string(lola.name)}
      {React.int(initial)}
      children
      {React.string(value)}
    </div>;
  };
};
