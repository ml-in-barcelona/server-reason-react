let handler = _request => {
  let app =
    <Document>
      <div className={Cx.make(["py-16", "px-12"])}>
        <Spacer bottom=8>
          <h1
            className={Cx.make([
              "font-bold text-4xl",
              Theme.text(Theme.Color.Gray14),
            ])}>
            {React.string("demo for server-reason-react")}
          </h1>
          <Spacer top=2>
            <Text size=Medium>
              "This is a list of links to all the demos for server-reason-react's features."
            </Text>
            <br />
            <Text size=Medium>
              "Useful to manual test. If you want to learn more about server-reason-react, check out the "
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
              "source code"
            </Link.Text>
          </Spacer>
        </Spacer>
        <Router.Menu />
      </div>
    </Document>;

  Dream.html(ReactDOM.renderToStaticMarkup(app));
};
