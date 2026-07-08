/* An explicit fallback={React.null} is NOT the same as an absent fallback
   prop: React keeps the key and serializes it as "fallback":null, while a
   missing prop is omitted from the props object entirely (see
   suspense_no_fallback). */
let app = () =>
  <React.Suspense fallback=React.null>
    <div> {React.string("null fallback")} </div>
  </React.Suspense>;
