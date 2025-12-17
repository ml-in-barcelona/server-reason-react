/* Dream + server-reason-react Benchmark Server */
open Benchmark_scenarios;

let render_scenario = scenario_name => {
  switch (scenario_name) {
  | "trivial" => Some(ReactDOM.renderToStaticMarkup(<Trivial />))
  | "shallow" => Some(ReactDOM.renderToStaticMarkup(<ShallowTree />))
  | "deep10" => Some(ReactDOM.renderToStaticMarkup(<DeepTree.Depth10 />))
  | "deep25" => Some(ReactDOM.renderToStaticMarkup(<DeepTree.Depth25 />))
  | "deep50" => Some(ReactDOM.renderToStaticMarkup(<DeepTree.Depth50 />))
  | "deep100" => Some(ReactDOM.renderToStaticMarkup(<DeepTree.Depth100 />))
  | "wide10" => Some(ReactDOM.renderToStaticMarkup(<WideTree.Wide10 />))
  | "wide100" => Some(ReactDOM.renderToStaticMarkup(<WideTree.Wide100 />))
  | "wide500" => Some(ReactDOM.renderToStaticMarkup(<WideTree.Wide500 />))
  | "wide1000" => Some(ReactDOM.renderToStaticMarkup(<WideTree.Wide1000 />))
  | "table10" => Some(ReactDOM.renderToStaticMarkup(<Table.Table10 />))
  | "table50" => Some(ReactDOM.renderToStaticMarkup(<Table.Table50 />))
  | "table100" => Some(ReactDOM.renderToStaticMarkup(<Table.Table100 />))
  | "table500" => Some(ReactDOM.renderToStaticMarkup(<Table.Table500 />))
  | "props_small" =>
    Some(ReactDOM.renderToStaticMarkup(<PropsHeavy.Small />))
  | "props_medium" =>
    Some(ReactDOM.renderToStaticMarkup(<PropsHeavy.Medium />))
  | "props_large" =>
    Some(ReactDOM.renderToStaticMarkup(<PropsHeavy.Large />))
  | "ecommerce24" =>
    Some(ReactDOM.renderToStaticMarkup(<Ecommerce.Products24 />))
  | "ecommerce48" =>
    Some(ReactDOM.renderToStaticMarkup(<Ecommerce.Products48 />))
  | "ecommerce100" =>
    Some(ReactDOM.renderToStaticMarkup(<Ecommerce.Products100 />))
  | "dashboard" => Some(ReactDOM.renderToStaticMarkup(<Dashboard />))
  | "blog10" => Some(ReactDOM.renderToStaticMarkup(<Blog.Blog10 />))
  | "blog50" => Some(ReactDOM.renderToStaticMarkup(<Blog.Blog50 />))
  | "blog100" => Some(ReactDOM.renderToStaticMarkup(<Blog.Blog100 />))
  | "form" => Some(ReactDOM.renderToStaticMarkup(<Form />))
  | _ => None
  };
};

let scenario_list = [|
  ("trivial", "Trivial", "Baseline hello world"),
  ("shallow", "Shallow Tree", "5 levels deep with props"),
  ("deep10", "Deep Tree 10", "10 levels deep"),
  ("deep25", "Deep Tree 25", "25 levels deep"),
  ("deep50", "Deep Tree 50", "50 levels deep"),
  ("deep100", "Deep Tree 100", "100 levels deep"),
  ("wide10", "Wide Tree 10", "10 siblings"),
  ("wide100", "Wide Tree 100", "100 siblings"),
  ("wide500", "Wide Tree 500", "500 siblings"),
  ("wide1000", "Wide Tree 1000", "1000 siblings"),
  ("table10", "Table 10", "10 row data table"),
  ("table50", "Table 50", "50 row data table"),
  ("table100", "Table 100", "100 row data table"),
  ("table500", "Table 500", "500 row data table"),
  ("props_small", "Props Small", "10 heavy components"),
  ("props_medium", "Props Medium", "50 heavy components"),
  ("props_large", "Props Large", "Large table with many attrs"),
  ("ecommerce24", "E-commerce 24", "24 product cards"),
  ("ecommerce48", "E-commerce 48", "48 product cards"),
  ("ecommerce100", "E-commerce 100", "100 product cards"),
  ("dashboard", "Dashboard", "Analytics dashboard"),
  ("blog10", "Blog 10", "Blog with 10 comments"),
  ("blog50", "Blog 50", "Blog with 50 comments"),
  ("blog100", "Blog 100", "Blog with 100 comments"),
  ("form", "Form", "Complex multi-step form"),
|];

let port =
  switch (Sys.getenv_opt("PORT")) {
  | Some(p) => int_of_string(p)
  | None => 3000
  };

let disable_logger =
  switch (Sys.getenv_opt("DISABLE_LOGGER")) {
  | Some("1" | "true") => true
  | _ => false
  };

let () = {
  let handler =
    Dream.router([
      Dream.get("/", request => {
        let scenario_name =
          switch (Dream.query(request, "scenario")) {
          | Some(s) => s
          | None => "table100"
          };

        switch (render_scenario(scenario_name)) {
        | Some(html) =>
          let full_html =
            Printf.sprintf(
              {|<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">%s</div></body></html>|},
              html,
            );
          Dream.html(full_html);
        | None =>
          Dream.respond(
            ~status=`Not_Found,
            "Unknown scenario: " ++ scenario_name,
          )
        };
      }),
      Dream.get("/health", _ => {
        let pid = Unix.getpid();
        Dream.json(
          Printf.sprintf(
            {|{"status":"ok","framework":"dream-native","pid":%d}|},
            pid,
          ),
        );
      }),
      Dream.get("/scenarios", _ => {
        let json =
          Array.fold_left(
            (acc, (key, name, desc)) => {
              let item =
                Printf.sprintf(
                  {|{"key":"%s","name":"%s","description":"%s"}|},
                  key,
                  name,
                  desc,
                );
              if (acc == "[") {
                acc ++ item;
              } else {
                acc ++ "," ++ item;
              };
            },
            "[",
            scenario_list,
          )
          ++ "]";
        Dream.json(json);
      }),
    ]);

  let app = disable_logger ? handler : Dream.logger(handler);
  Dream.run(~port, ~interface="0.0.0.0", app);
};
