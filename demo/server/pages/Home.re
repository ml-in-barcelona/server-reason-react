let handler = _request => {
  let app =
    <Document>
      <div className={Cx.make(["py-16", "px-12"])}>
        <div className="mb-8">
          <h1
            className={Cx.make([
              "font-extrabold text-5xl",
              Theme.text(Theme.Color.Primary),
            ])}>
            {React.string("Demos for server-reason-react")}
          </h1>
          <div className="mt-8">
            <Text size=Medium>
              "This is a list of links to all the demos for server-reason-react's features"
            </Text>
            <br />
            <Text size=Medium>
              "If you want to learn more about server-reason-react, check out the "
            </Text>
            <Link.Text
              target="_blank"
              href="https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/index.html">
              "documentation"
            </Link.Text>
            <Text size=Medium> " or " </Text>
            <Link.Text
              target="_blank"
              href="https://github.com/ml-in-barcelona/server-reason-react">
              "repository"
            </Link.Text>
            <Text size=Medium> "." </Text>
          </div>
        </div>
        <Routes.Menu />
      </div>
    </Document>;

  Dream.html(ReactDOM.renderToStaticMarkup(app));
};
