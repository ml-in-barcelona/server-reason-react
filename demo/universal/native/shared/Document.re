[@react.component]
let make = (~children, ~script=?) => {
  <html>
    <head>
      <meta charSet="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title> {React.string("Server Reason React demo")} </title>
      <link
        rel="shortcut icon"
        href="https://reasonml.github.io/img/icon_50.png"
      />
      <GlobalStyles />
      <link rel="stylesheet" href="/output.css" />
      {switch (script) {
       | None => React.null
       | Some(src) => <script type_="module" src />
       }}
    </head>
    <body> <div id="root"> children </div> </body>
  </html>;
};
