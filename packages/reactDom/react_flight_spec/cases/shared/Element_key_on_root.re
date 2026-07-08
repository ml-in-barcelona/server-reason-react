/* A key on the root element: serialized in the key slot of the root row's
   tuple even though nothing iterates over it. */
let app = () => <div key="root-key"> {React.string("keyed root")} </div>;
