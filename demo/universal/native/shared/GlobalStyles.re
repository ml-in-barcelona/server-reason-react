let string =
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
let make = () => {
  <style type_="text/css" dangerouslySetInnerHTML={"__html": string} />;
};
