let handler = (~element, request) => {
  let ssr =
    Dream.query(request, "ssr")
    |> Option.map(v => v == "false")
    |> Option.value(~default=true);

  DreamRSC.createFromRequest(
    ~disableSSR=!ssr,
    ~bootstrapModules=["/static/demo/Router.re.js"],
    React.Model.Element(element),
    request,
  );
};
