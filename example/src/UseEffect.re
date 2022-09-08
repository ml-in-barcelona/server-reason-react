open Bindings;
open React.Dom.Dsl;
open Html;

[@react.component]
let make = (~count) => {
  open Js_of_ocaml_lwt;
  React.use_effect1(
    () => {
      open Lwt;
      open Lwt_js;
      bind(
        sleep(1.),
        () => {
          Console.log(
            "count changed 1 sec ago! Value is: " ++ string_of_int(count),
          );
          return();
        },
      )
      |> ignore;
      Some(
        () =>
          Console.log(
            "Unmounting effect for value: " ++ string_of_int(count),
          ),
      );
    },
    [|count|],
  );

  React.use_effect_always(
    ~before_render=true,
    () => {
      Console.log("use_layout_effect: component updated");
      None;
    },
  );

  <div>
    {"UseEffect: printing delayed counts on the console since 2019 :)"
     |> React.string}
  </div>;
};
