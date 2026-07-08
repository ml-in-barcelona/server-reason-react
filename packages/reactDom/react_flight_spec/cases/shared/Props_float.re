/* Float props on a host element (the aria value attributes are the only
   float-typed host props shared by both ppxs). Covers fractional and
   integral floats: React serializes numbers the way JSON.stringify does,
   so 100.0 crosses the wire as 100, and 0.5 as 0.5.

   Props are listed in reason-react's [domProps] declaration order (see the
   note in Props_primitives.re). */
let app = () => <div ariaValuemax=100.0 ariaValuemin=0.5 ariaValuenow=25.0 />;
