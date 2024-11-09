let handler =
  Dream.error_template((_error, info, suggested) => {
    let status = Dream.status(suggested);
    let _code = Dream.status_to_int(status);
    let reason = Dream.status_to_string(status);
    Dream.html(
      ReactDOM.renderToStaticMarkup(
        <Document>
          <div className="py-16 px-12">
            <main>
              <Spacer bottom=8>
                <h1
                  className={Cx.make([
                    "font-bold text-5xl",
                    Theme.text(Theme.Color.white),
                  ])}>
                  {React.string(reason)}
                </h1>
              </Spacer>
              <pre className="overflow-scroll">
                <code
                  className="w-full text-sm sm:text-base inline-flex text-left items-center space-x-4 bg-orange-900 font-bold text-white rounded-lg p-4 pl-6">
                  {React.string(info)}
                </code>
              </pre>
            </main>
          </div>
        </Document>,
      ),
    );
  });
