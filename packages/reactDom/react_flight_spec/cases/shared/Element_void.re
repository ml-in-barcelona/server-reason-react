/* Void elements: the Flight payload has no notion of self-closing tags, so
   <br/> and <input/> are ordinary elements whose props lack children. */
let app = () => <div> <br /> <input type_="text" /> <hr /> </div>;
