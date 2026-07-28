/* Async sections resolve via Lwt.return on purpose: the benchmark measures render cost, not waiting. */

module Item = {
  [@react.component]
  let make = (~id) => {
    <li className="p-2 border-b">
      {React.string(Printf.sprintf("Async item %d", id))}
    </li>;
  };
};

module AsyncSection = {
  [@react.async.component]
  let make = (~offset) => {
    Lwt.return(
      <ul className="divide-y">
        {React.array(
           Array.init(
             10,
             i => {
               let id = offset + i;
               <Item key={Int.to_string(id)} id />;
             },
           ),
         )}
      </ul>,
    );
  };
};

module Boundaries3 = {
  let section = (~label, ~offset) =>
    <React.Suspense fallback={<span> {React.string(label)} </span>}>
      <AsyncSection offset />
    </React.Suspense>;

  [@react.component]
  let make = () => {
    <div className="grid gap-4 p-4">
      {section(~label="Loading section 1", ~offset=0)}
      {section(~label="Loading section 2", ~offset=10)}
      {section(~label="Loading section 3", ~offset=20)}
    </div>;
  };
};

[@react.component]
let make = () => <Boundaries3 />;
