[@react.client.component]
let make = () => {
  <section>
    <h1> {React.string("lola")} </h1>
    <p> {React.int(1)} </p>
    <div> {React.string("children")} </div>
  </section>;
};

// to avoid unused error on "make"
let _ = make;
