let make = () => {
  let%browser_only loadInitialText = () => {
    setHtmlFetchState(Loading);
    WcApi.fetchHTML(WcConstants.initialText)
    ->Promise.flatMap(html =>
        onChange(html->WcStringHelpers.htmlToText)->Promise.resolved
      )
    ->Promise.Js.catch(_ => setHtmlFetchState(Error)->Promise.resolved)
    ->ignore;
  };

  let%browser_only loadInitialText = (argument1, argument2) => {
    setHtmlFetchState(Loading);
    WcApi.fetchHTML(WcConstants.initialText)
    ->Promise.flatMap(html =>
        onChange(html->WcStringHelpers.htmlToText)->Promise.resolved
      )
    ->Promise.Js.catch(_ => setHtmlFetchState(Error)->Promise.resolved)
    ->ignore;
  };

  React.createElement("div");
};
