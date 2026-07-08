/* Numeric children beyond 2^53: JavaScript prints integral doubles in full
   digits up to 1e21 and in exponent form from there. */
let app = () => <div> {React.float(9e18)} {React.float(1e21)} </div>;
