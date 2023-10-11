/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  let addSelectionChangeEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let addSelectionChangeEventListenerWithOptions =
      (
        _callback: Dom.focusEvent => unit,
        _options: {
          .
          "capture": bool,
          "once": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let addSelectionChangeEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeSelectionChangeEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();

  let removeSelectionChangeEventListenerWithOptions =
      (
        _callback: Dom.focusEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();

  let removeSelectionChangeEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
};
