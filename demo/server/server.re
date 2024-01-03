/**

  This is a demo of a HTTP server that demostrates the possibility of Html_of_jsx.

  It uses `tiny_httpd` to keep the dependencies to a minimum. It also contains a bunch of utilities to generate styles.

*/
module Httpd = Tiny_httpd;
module Httpd_dir = Tiny_httpd_dir;

let globalStyles = {js|
  html, body, #root {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
  }

  * {
    font-family: -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    box-sizing: border-box;
  }
|js};

module Page = {
  [@react.component]
  let make = (~children) => {
    <html>
      <head>
        <meta charSet="UTF-8" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0"
        />
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
        <script type_="module" src="/static/demo/client/bundle.js" />
      </head>
      <body> <div id="root"> children </div> </body>
    </html>;
  };
};

module Link = {
  [@react.component]
  let make = (~href, ~children) => {
    let (useState, setState) = React.useState(() => false);

    React.useEffect0(() => {
      setState(_prev => !useState);

      None;
    });

    <a
      onClick={_e => print_endline("clicked")}
      className="font-medium text-blue-600 hover:underline flex items-center"
      href>
      {React.string(children)}
      <svg
        className="w-3 h-3 ms-2 rtl:rotate-180"
        ariaHidden=true
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 14 10">
        <path
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
          d="M1 5h12m0 0L9 1m4 4L9 9"
        />
      </svg>
    </a>;
  };
};

module Home = {
  [@react.component]
  let make = () => {
    <div className="py-16 px-12">
      <h1 className="font-bold text-4xl">
        {React.string("Home page of the demos")}
      </h1>
      <br />
      <ul className="gap-1 flex flex-col">
        <li>
          <Link href="/markup"> "Tiny app with renderToStaticMarkup" </Link>
        </li>
        <li> <Link href="/string"> "Tiny app with renderToString" </Link> </li>
      </ul>
    </div>;
  };
};

module Not_found = {
  [@react.component]
  let make = (~path) => {
    <div className="p-12">
      <Spacer bottom=4>
        <h1 className="font-bold text-5xl"> {React.string("Not found")} </h1>
      </Spacer>
      <span className="text-xl font-bold"> {React.string("Error 404")} </span>
      <span className="text-xl"> {React.string(" · ")} </span>
      <span className="text-xl"> {React.string("The requested URL")} </span>
      <span
        className="bg-slate-200 mx-2 py-1 px-3 no-underline rounded-full font-sans font-semibold">
        {React.string(path)}
      </span>
      <span className="text-xl">
        {React.string("was not found on this server.")}
      </span>
    </div>;
  };
};

let () = {
  let server = Httpd.create();
  let addr = Httpd.addr(server);
  let port = Httpd.port(server);

  Httpd.add_route_handler(
    ~meth=`GET,
    server,
    Httpd.Route.(exact("markup") @/ string @/ return),
    (_name, _req) => {
      let html = ReactDOM.renderToStaticMarkup(<Page> <App /> </Page>);
      Httpd.Response.make_string(Ok(html));
    },
  );
  Httpd.add_route_handler(
    ~meth=`GET,
    server,
    Httpd.Route.(exact("string") @/ return),
    _req => {
      let html = ReactDOM.renderToString(<Page> <App /> </Page>);
      Httpd.Response.make_string(Ok(html));
    },
  );

  /*
   TODO: Render to stream
    Dream.get("/stream", _request =>
           Dream.stream(
             ~headers=[("Content-Type", "text/html")],
             response_stream => {
               let (stream, _) =
                 ReactDOM.renderToLwtStream(<Page> <Comments.App /> </Page>);

               Lwt_stream.iter_s(
                 data => {
                   let%lwt () = Dream.write(response_stream, data);
                   Dream.flush(response_stream);
                 },
                 stream,
               );
             },
           )
         ),

   Httpd.add_route_handler_stream(
        ~meth=`GET,
        server,
        Httpd.Route.(exact("stream") @/ return),
        req => {
          let (_stream, _close) =
            ReactDOM.renderToLwtStream(
              <Page scripts=["/static/app.js"]> <App /> </Page>,
            );
          Lwt_stream.iter_s(
               data => {
                 let%lwt () = Dream.write(response_stream, data);
                 Dream.flush(response_stream);
               },
               stream,
             );
          Tiny_httpd_stream.iter(write, req.Request.body);
          let a = Httpd.Byte_stream.of_string("asdf");
          Httpd.Response.make_stream(Ok(a));
        },
      ); */

  Httpd_dir.add_dir_path(
    server,
    ~prefix="static",
    ~dir="_build/default/demo/client/app",
    ~config=
      Httpd_dir.config(
        ~download=true,
        ~upload=false,
        ~dir_behavior=Httpd_dir.Index_or_lists,
        (),
      ),
  );

  Httpd.set_top_handler(
    server,
    req => {
      let html =
        ReactDOM.renderToString(<Page> <Not_found path={req.path} /> </Page>);
      Httpd.Response.make_string(Ok(html));
    },
  );

  Httpd.add_route_handler(
    server,
    Httpd.Route.(return),
    _req => {
      let html = ReactDOM.renderToString(<Page> <Home /> </Page>);
      Httpd.Response.make_string(Ok(html));
    },
  );

  switch (
    Httpd.run(
      server,
      ~after_init=() => {
        Esbuild.build(
          ~entry_point="demo/client/index.js",
          ~outfile="demo/client/bundle.js",
          (),
        );
        Printf.printf("Listening on http://%s:%d\n%!", addr, port);
      },
    )
  ) {
  | Ok () => ()
  | Error(e) => raise(e)
  };
};
