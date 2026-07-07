/* string / int / bool props on a host element. Typed JSX (both ppxs) cannot
   express float or null-valued host props; that coverage lives in
   Client_component_with_props via the Spec prop constructors. */
let app = () =>
  <input type_="text" defaultValue="hello" tabIndex=42 disabled=true />;
