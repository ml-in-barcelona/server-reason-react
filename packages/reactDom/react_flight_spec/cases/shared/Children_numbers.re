/* Numeric children through React.int / React.float. React serializes number
   children as JSON numbers (42, 3.14); anything srr stringifies eagerly
   will show up as a divergence here. */
let app = () =>
  <ul>
    <li> {React.int(42)} </li>
    <li> {React.float(3.14)} </li>
    <li> {React.int(0)} </li>
    <li> {React.float(100.0)} </li>
  </ul>;
