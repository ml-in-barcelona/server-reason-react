/* Fragments returned from a Children.map callback take React's mapped keys:
   ".$<key>" for a keyed child, ".<index>" for an unkeyed one, and a
   "<result key>/" prefix when the fragment carries its own key. */
module Wrap = {
  [@react.component]
  let make = (~children) =>
    <ul>
      {React.Children.map(children, child =>
         <React.Fragment> child <hr /> </React.Fragment>
       )}
    </ul>;
};

module Prefix = {
  [@react.component]
  let make = (~children) =>
    <ol>
      {React.Children.map(children, child =>
         <React.Fragment key="x"> child <hr /> </React.Fragment>
       )}
    </ol>;
};

let app = () =>
  <div>
    <Wrap>
      <li key="a"> {React.string("alpha")} </li>
      <li> {React.string("beta")} </li>
    </Wrap>
    <Prefix> <li> {React.string("gamma")} </li> </Prefix>
  </div>;
