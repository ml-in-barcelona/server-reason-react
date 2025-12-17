/* Scenario: Deep Tree
      50+ levels deep component tree
      Purpose: Test deep recursion and call stack performance
   */

module Wrapper = {
  [@react.component]
  let make = (~depth, ~maxDepth, ~children) => {
    let percentage = float_of_int(depth) /. float_of_int(maxDepth) *. 100.0;
    <div
      className={Printf.sprintf("depth-%d", depth)}
      dataTestid={Printf.sprintf("level-%d", depth)}
      style={ReactDOM.Style.make(
        ~paddingLeft="2px",
        ~borderLeft="1px solid rgba(0,0,0,0.1)",
        (),
      )}>
      <span className="text-xs text-gray-400">
        {React.string(Printf.sprintf("Level %d (%.0f%%)", depth, percentage))}
      </span>
      children
    </div>;
  };
};

let rec renderDepth = (current, max) =>
  if (current >= max) {
    <div className="leaf-node bg-green-100 p-2 rounded">
      <strong> {React.string("Leaf Node")} </strong>
      <p className="text-sm">
        {React.string(Printf.sprintf("Reached depth %d", current))}
      </p>
    </div>;
  } else {
    <Wrapper depth=current maxDepth=max>
      {renderDepth(current + 1, max)}
    </Wrapper>;
  };

/* Different depth variants for comparison */
module Depth10 = {
  [@react.component]
  let make = () => renderDepth(0, 10);
};

module Depth25 = {
  [@react.component]
  let make = () => renderDepth(0, 25);
};

module Depth50 = {
  [@react.component]
  let make = () => renderDepth(0, 50);
};

module Depth100 = {
  [@react.component]
  let make = () => renderDepth(0, 100);
};

[@react.component]
let make = () => <Depth50 />;
