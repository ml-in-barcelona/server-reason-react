/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.send.pipe: T.t]
  external addSelectionChangeEventListener:
    ([@mel.as "selectionchange"] _, Dom.focusEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addSelectionChangeEventListenerWithOptions:
    (
      [@mel.as "selectionchange"] _,
      Dom.focusEvent => unit,
      {
        .
        "capture": bool,
        "once": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "addEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external addSelectionChangeEventListenerUseCapture:
    (
      [@mel.as "selectionchange"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeSelectionChangeEventListener:
    ([@mel.as "selectionchange"] _, Dom.focusEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeSelectionChangeEventListenerWithOptions:
    (
      [@mel.as "selectionchange"] _,
      Dom.focusEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeSelectionChangeEventListenerUseCapture:
    (
      [@mel.as "selectionchange"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";
};
