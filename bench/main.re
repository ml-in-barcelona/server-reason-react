open Core;
open Core_bench;

module App = {
  [@react.component]
  let make = () => {
    <div className=["py-16 px-12"]>
      <h1 className="font-bold text-4xl">
        {React.string("Home of the demos")}
      </h1>
      <ul className="flex flex-col gap-4">
        <li>
          <a href="https://sancho.dev">
            {React.string("https://sancho.dev")}
          </a>
        </li>
        <li>
          <a href="https://sancho.dev">
            {React.string("https://sancho.dev")}
          </a>
        </li>
        <li>
          <a href="https://sancho.dev">
            {React.string("https://sancho.dev")}
          </a>
        </li>
      </ul>
    </div>;
  };
};

let bench_static =
  Bench.Test.create(~name="Parse static", () =>
    ReactDOM.renderToStaticMarkup(<App />)
  );

Command_unix.run @@ Bench.make_command([bench_static]);
