/* Scenario: Suspense Tree
      Multiple Suspense boundaries whose async components resolve immediately
      (Lwt.return based, no sleeps) so benchmarks measure render cost only.
      Purpose: Exercise the streaming/RSC Suspense machinery
   */

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
  [@react.component]
  let make = () => {
    <div className="grid gap-4 p-4">
      <React.Suspense
        fallback={<span> {React.string("Loading section 1")} </span>}>
        <AsyncSection offset=0 />
      </React.Suspense>
      <React.Suspense
        fallback={<span> {React.string("Loading section 2")} </span>}>
        <AsyncSection offset=10 />
      </React.Suspense>
      <React.Suspense
        fallback={<span> {React.string("Loading section 3")} </span>}>
        <AsyncSection offset=20 />
      </React.Suspense>
    </div>;
  };
};

[@react.component]
let make = () => <Boundaries3 />;
