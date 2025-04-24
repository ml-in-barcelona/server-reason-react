let globalStyles =
  Printf.sprintf(
    {js|
  html, body, #root {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
    background-color: %s;
  }

  * {
    font-family: -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    box-sizing: border-box;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }
|js},
    Theme.Color.gray2,
  );

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
      <style
        type_="text/css"
        dangerouslySetInnerHTML={"__html": globalStyles}
      />
      <link rel="stylesheet" href="/static/demo/output.css" />
      {switch (script) {
       | None => React.null
       | Some(src) => <script type_="module" src />
       }}
    </head>
    <body> <div id="root"> children </div> </body>
  </html>;
};
