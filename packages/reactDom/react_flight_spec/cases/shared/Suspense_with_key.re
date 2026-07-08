/* A keyed Suspense boundary: the key lands in the element tuple's key slot,
   not in props. */
let app = () =>
  <React.Suspense
    key="boundary" fallback={<span> {React.string("loading")} </span>}>
    <div> {React.string("keyed")} </div>
  </React.Suspense>;
