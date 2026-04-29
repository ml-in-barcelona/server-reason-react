Tests that the same algorithm works on Reason syntax (.re files).

  $ cat > input.re << EOF
  > let%browser_only handleClick = (event, ~target, callback) => {
  >   target |> callback;
  >   event;
  > };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

With -js, args are preserved as-is.

  $ ../standalone.exe -impl input.ml -js | refmt --parse ml --print re
  let handleClick = (event, ~target, callback) => {
    target |> callback;
    event;
  };

Without -js, all args are preserved with let-chain references.

  $ ../standalone.exe -impl input.ml | refmt --parse ml --print re > output.re

  $ cat output.re
  [@warning "-26-27-32-33"]
  let [@alert
        browser_only(
          "This expression is marked to only run on the browser where JavaScript can run. You can only use it inside a let%browser_only function.",
        )
      ]
      handleClick =
    [@alert "-browser_only"]
    (
      (event, ~target, callback) => {
        let _ = event;
        let _ = target;
        let _ = callback;
        Runtime.fail_impossible_action_in_ssr("handleClick");
      }
    );
