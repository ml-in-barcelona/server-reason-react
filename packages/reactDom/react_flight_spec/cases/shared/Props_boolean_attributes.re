/* Boolean attributes: the Flight model carries the raw prop value, so
   disabled=false crosses the wire as "disabled":false — React does NOT drop
   false-valued props from the payload (dropping happens later, in the DOM
   renderer). */
let app = () =>
  <form> <input disabled=true /> <input disabled=false /> </form>;
