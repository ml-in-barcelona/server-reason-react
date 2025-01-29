let globalStyles = {js|
  html, body, #root {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
    background-color: #161615; /* Theme.Color.Gray12; */
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
|js};

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
      <script src="https://cdn.tailwindcss.com" />
      {switch (script) {
       | None => React.null
       | Some(src) => <script type_="module" src />
       }}
    </head>
    <body> <div id="root"> children </div> </body>
  </html>;
};
