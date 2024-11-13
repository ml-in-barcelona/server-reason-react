let handler = _request => {
  let app =
    <Document>
      <div className={Cx.make(["py-16", "px-12"])}>
        <Spacer bottom=8>
          <h1
            className={Cx.make([
              "font-bold text-4xl",
              Theme.text(Theme.Color.white),
            ])}>
            {React.string("Home of the demos")}
          </h1>
        </Spacer>
        <Router.Menu />
      </div>
    </Document>;

  Dream.html(ReactDOM.renderToStaticMarkup(app));
};
