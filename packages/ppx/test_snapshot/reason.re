let _ = [%browser_only Webapi.Dom.getElementById("foo")];

let%browser_only loadInitialText = () => {
  setHtmlFetchState(Loading);
};

let%browser_only loadInitialText = argument1 => {
  setHtmlFetchState(Loading);
};

let%browser_only loadInitialText = (argument1, argument2) => {
  setHtmlFetchState(Loading);
};

let make = () => {
  let _ = [%browser_only Webapi.Dom.getElementById("foo")];

  let%browser_only loadInitialText = () => {
    setHtmlFetchState(Loading);
  };

  let%browser_only loadInitialText = argument1 => {
    setHtmlFetchState(Loading);
  };

  let%browser_only loadInitialText = (argument1, argument2) => {
    setHtmlFetchState(Loading);
  };

  React.createElement("div");
};
