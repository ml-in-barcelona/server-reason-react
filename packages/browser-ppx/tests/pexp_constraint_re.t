  $ cat > input.re << EOF
  > let make = () => {
  >   let%browser_only discard: Js.Promise.t(unit) => unit = value => ignore(value);
  >   ();
  > };
  > 
  > let%browser_only reifyStyle = (type a, x: 'a): (style(a), a) => {
  >     let isCanvasGradient = _ => false;
  >     let isCanvasPattern = _ => false;
  >     
  >     (
  >       if (Js.typeof(x) == "string") {
  >         Obj.magic(String);
  >       } else if (isCanvasGradient(x)) {
  >         Obj.magic(Gradient);
  >       } else if (isCanvasPattern(x)) {
  >         Obj.magic(Pattern);
  >       } else {
  >         invalid_arg("Unknown canvas style kind. Known values are: String, CanvasGradient, CanvasPattern");
  >       },
  >       Obj.magic(x),
  >     );
  >   };
  > 
  > EOF

  $ refmt --print ml input.re > input.ml

  $ ./standalone.exe -impl input.ml -js | refmt --parse ml --print re
  let make = () => {
    let discard: Js.Promise.t(unit) => unit = value => ignore(value);
    ();
  };
  let reifyStyle = (type a, x: 'a): (style(a), a) => {
    let isCanvasGradient = _ => false;
    let isCanvasPattern = _ => false;
    (
      if (Js.typeof(x) == "string") {
        Obj.magic(String);
      } else if (isCanvasGradient(x)) {
        Obj.magic(Gradient);
      } else if (isCanvasPattern(x)) {
        Obj.magic(Pattern);
      } else {
        invalid_arg(
          "Unknown canvas style kind. Known values are: String, CanvasGradient, CanvasPattern",
        );
      },
      Obj.magic(x),
    );
  };

  $ ./standalone.exe -impl input.ml | refmt --parse ml --print re
  let make = () => {
    [@alert "-browser_only"]
    let discard = value => Runtime.fail_impossible_action_in_ssr("discard");
    ();
  };
  let reifyStyle = (type a, x: 'a): (style(a), a) => {
    let isCanvasGradient = _ => false;
    let isCanvasPattern = _ => false;
    (
      if (Js.typeof(x) == "string") {
        Obj.magic(String);
      } else if (isCanvasGradient(x)) {
        Obj.magic(Gradient);
      } else if (isCanvasPattern(x)) {
        Obj.magic(Pattern);
      } else {
        invalid_arg(
          "Unknown canvas style kind. Known values are: String, CanvasGradient, CanvasPattern",
        );
      },
      Obj.magic(x),
    );
  };
