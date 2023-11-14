  $ cat > input.re << EOF
  > let%browser_only discard: Js.Promise.t(unit) => unit = value => ignore(value);
  > 
  > let make = () => {
  >   let%browser_only discard: Js.Promise.t(unit) => unit = value => ignore(value);
  >   ();
  > };
  > 
  > EOF

  $ refmt --print ml input.re > input.ml

  $ ./standalone.exe -impl input.ml -js | refmt --parse ml --print re
  let discard: Js.Promise.t(unit) => unit = value => ignore(value);
  let make = () => {
    let discard: Js.Promise.t(unit) => unit = value => ignore(value);
    ();
  };

  $ ./standalone.exe -impl input.ml | refmt --parse ml --print re
  [@warning "-27-32"]
  let discard:
    [@alert
      browser_only(
        "This expression is marked to only run on the browser where JavaScript can run. You can only use it inside a let%browser_only function.",
      )
    ] (
      Js.Promise.t(unit) => unit
    ) =
    [@alert "-browser_only"]
    (value => Runtime.fail_impossible_action_in_ssr("discard"));
  let make = () => {
    [@warning "-26-27"]
    [@alert "-browser_only"]
    let discard = value => Runtime.fail_impossible_action_in_ssr("discard");
    ();
  };
