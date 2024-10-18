[@react.component]
let make = () =>
  <html>
    <body>
      <h1> {React.string(Js.String.toLowerCase("Hello World"))} </h1>
      <p> {React.string("This is an example")} </p>
    </body>
  </html>;
