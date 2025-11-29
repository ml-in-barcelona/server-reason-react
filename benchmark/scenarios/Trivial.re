/* Scenario: Trivial
      Baseline test - simplest possible component
      Purpose: Measure baseline overhead of React rendering
   */

[@react.component]
let make = () => <div> {React.string("Hello World")} </div>;
