/* Suspense without a fallback prop: React omits the key entirely from the
   props object ({"children":...}, no "fallback"). Contrast with
   suspense_null_fallback where an explicit fallback={React.null} keeps the
   key as "fallback":null. */
let app = () =>
  <React.Suspense>
    <div> {React.string("no fallback")} </div>
  </React.Suspense>;
