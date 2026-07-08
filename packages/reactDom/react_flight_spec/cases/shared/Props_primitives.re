/* string / int / bool props on a host element. Float props live in
   Props_float; null-valued host props cannot be expressed by typed JSX
   (both ppxs), so that coverage lives in Client_component_with_props via
   the Spec prop constructors.

   Prop order: srr serializes props in JSX source order (like real JS JSX
   object literals), but the melange side goes through reason-react's
   [domProps] record, whose field *declaration* order dictates the JS object
   key order. The source below lists props in reason-react's declaration
   order so both sides emit identical bytes. */
let app = () =>
  <input defaultValue="hello" tabIndex=42 disabled=true type_="text" />;
