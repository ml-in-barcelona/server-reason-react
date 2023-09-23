module Impl = (T: {
                 type t;
               }) => {
  external asEventTarget: T.t => Dom.eventTarget = "%identity";

  [@mel.send.pipe: T.t]
  external addEventListener: (string, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addEventListenerWithOptions:
    (
      string,
      Dom.event => unit,
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
  external addEventListenerUseCapture:
    (string, Dom.event => unit, [@mel.as {json|true|json}] _) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeEventListener: (string, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeEventListenerWithOptions:
    (
      string,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeEventListenerUseCapture:
    (string, Dom.event => unit, [@mel.as {json|true|json}] _) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external dispatchEvent: Dom.event_like('a) => bool = "dispatchEvent";

  /**
   *  non-standard event-specific functions
   */
  /* UI */
  [@mel.send.pipe: T.t]
  external addLoadEventListener:
    ([@mel.as "load"] _, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addLoadEventListenerWithOptions:
    (
      [@mel.as "load"] _,
      Dom.event => unit,
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
  external addLoadEventListenerUseCapture:
    ([@mel.as "load"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeLoadEventListener:
    ([@mel.as "load"] _, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeLoadEventListenerWithOptions:
    (
      [@mel.as "load"] _,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeLoadEventListenerUseCapture:
    ([@mel.as "load"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addUnloadEventListener:
    ([@mel.as "unload"] _, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addUnloadEventListenerWithOptions:
    (
      [@mel.as "unload"] _,
      Dom.event => unit,
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
  external addUnloadEventListenerUseCapture:
    ([@mel.as "unload"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeUnloadEventListener:
    ([@mel.as "unload"] _, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeUnloadEventListenerWithOptions:
    (
      [@mel.as "unload"] _,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeUnloadEventListenerUseCapture:
    ([@mel.as "unload"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addAbortEventListener:
    ([@mel.as "abort"] _, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addAbortEventListenerWithOptions:
    (
      [@mel.as "abort"] _,
      Dom.event => unit,
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
  external addAbortEventListenerUseCapture:
    ([@mel.as "abort"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeAbortEventListener:
    ([@mel.as "abort"] _, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeAbortEventListenerWithOptions:
    (
      [@mel.as "abort"] _,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeAbortEventListenerUseCapture:
    ([@mel.as "abort"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addErrorEventListener:
    ([@mel.as "error"] _, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addErrorEventListenerWithOptions:
    (
      [@mel.as "error"] _,
      Dom.event => unit,
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
  external addErrorEventListenerUseCapture:
    ([@mel.as "error"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeErrorEventListener:
    ([@mel.as "error"] _, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeErrorEventListenerWithOptions:
    (
      [@mel.as "error"] _,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeErrorEventListenerUseCapture:
    ([@mel.as "error"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addSelectEventListener:
    ([@mel.as "select"] _, Dom.event => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addSelectEventListenerWithOptions:
    (
      [@mel.as "select"] _,
      Dom.event => unit,
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
  external addSelectEventListenerUseCapture:
    ([@mel.as "select"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeSelectEventListener:
    ([@mel.as "select"] _, Dom.event => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeSelectEventListenerWithOptions:
    (
      [@mel.as "select"] _,
      Dom.event => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeSelectEventListenerUseCapture:
    ([@mel.as "select"] _, Dom.event => unit, [@mel.as {json|true|json}] _) =>
    unit =
    "removeEventListener";

  /* Focus */

  [@mel.send.pipe: T.t]
  external addBlurEventListener:
    ([@mel.as "blur"] _, Dom.focusEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addBlurEventListenerWithOptions:
    (
      [@mel.as "blur"] _,
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
  external addBlurEventListenerUseCapture:
    (
      [@mel.as "blur"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeBlurEventListener:
    ([@mel.as "blur"] _, Dom.focusEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeBlurEventListenerWithOptions:
    (
      [@mel.as "blur"] _,
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
  external removeBlurEventListenerUseCapture:
    (
      [@mel.as "blur"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addFocusEventListener:
    ([@mel.as "focus"] _, Dom.focusEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addFocusEventListenerWithOptions:
    (
      [@mel.as "focus"] _,
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
  external addFocusEventListenerUseCapture:
    (
      [@mel.as "focus"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusEventListener:
    ([@mel.as "focus"] _, Dom.focusEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusEventListenerWithOptions:
    (
      [@mel.as "focus"] _,
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
  external removeFocusEventListenerUseCapture:
    (
      [@mel.as "focus"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addFocusInEventListener:
    ([@mel.as "focusin"] _, Dom.focusEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addFocusInEventListenerWithOptions:
    (
      [@mel.as "focusin"] _,
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
  external addFocusInEventListenerUseCapture:
    (
      [@mel.as "focusin"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusInEventListener:
    ([@mel.as "focusin"] _, Dom.focusEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusInEventListenerWithOptions:
    (
      [@mel.as "focusin"] _,
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
  external removeFocusInEventListenerUseCapture:
    (
      [@mel.as "focusin"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addFocusOutEventListener:
    ([@mel.as "focusout"] _, Dom.focusEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addFocusOutEventListenerWithOptions:
    (
      [@mel.as "focusout"] _,
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
  external addFocusOutEventListenerUseCapture:
    (
      [@mel.as "focusout"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusOutEventListener:
    ([@mel.as "focusout"] _, Dom.focusEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeFocusOutEventListenerWithOptions:
    (
      [@mel.as "focusout"] _,
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
  external removeFocusOutEventListenerUseCapture:
    (
      [@mel.as "focusout"] _,
      Dom.focusEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Mouse */

  [@mel.send.pipe: T.t]
  external addClickEventListener:
    ([@mel.as "click"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addClickEventListenerWithOptions:
    (
      [@mel.as "click"] _,
      Dom.mouseEvent => unit,
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
  external addClickEventListenerUseCapture:
    (
      [@mel.as "click"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeClickEventListener:
    ([@mel.as "click"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeClickEventListenerWithOptions:
    (
      [@mel.as "click"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeClickEventListenerUseCapture:
    (
      [@mel.as "click"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDblClickEventListener:
    ([@mel.as "dblclick"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDblClickEventListenerWithOptions:
    (
      [@mel.as "dblclick"] _,
      Dom.mouseEvent => unit,
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
  external addDblClickEventListenerUseCapture:
    (
      [@mel.as "dblclick"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDblClickEventListener:
    ([@mel.as "dblclick"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDblClickEventListenerWithOptions:
    (
      [@mel.as "dblclick"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDblClickEventListenerUseCapture:
    (
      [@mel.as "dblclick"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseDownEventListener:
    ([@mel.as "mousedown"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseDownEventListenerWithOptions:
    (
      [@mel.as "mousedown"] _,
      Dom.mouseEvent => unit,
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
  external addMouseDownEventListenerUseCapture:
    (
      [@mel.as "mousedown"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseDownEventListener:
    ([@mel.as "mousedown"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseDownEventListenerWithOptions:
    (
      [@mel.as "mousedown"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseDownEventListenerUseCapture:
    (
      [@mel.as "mousedown"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseEnterEventListener:
    ([@mel.as "mouseenter"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseEnterEventListenerWithOptions:
    (
      [@mel.as "mouseenter"] _,
      Dom.mouseEvent => unit,
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
  external addMouseEnterEventListenerUseCapture:
    (
      [@mel.as "mouseenter"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseEnterEventListener:
    ([@mel.as "mouseenter"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseEnterEventListenerWithOptions:
    (
      [@mel.as "mouseenter"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseEnterEventListenerUseCapture:
    (
      [@mel.as "mouseenter"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseMoveEventListener:
    ([@mel.as "mousemove"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseMoveEventListenerWithOptions:
    (
      [@mel.as "mousemove"] _,
      Dom.mouseEvent => unit,
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
  external addMouseMoveEventListenerUseCapture:
    (
      [@mel.as "mousemove"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseMoveEventListener:
    ([@mel.as "mousemove"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseMoveEventListenerWithOptions:
    (
      [@mel.as "mousemove"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseMoveEventListenerUseCapture:
    (
      [@mel.as "mousemove"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseOutEventListener:
    ([@mel.as "mouseout"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseOutEventListenerWithOptions:
    (
      [@mel.as "mouseout"] _,
      Dom.mouseEvent => unit,
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
  external addMouseOutEventListenerUseCapture:
    (
      [@mel.as "mouseout"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseOutEventListener:
    ([@mel.as "mouseout"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseOutEventListenerWithOptions:
    (
      [@mel.as "mouseout"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseOutEventListenerUseCapture:
    (
      [@mel.as "mouseout"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseOverEventListener:
    ([@mel.as "mouseover"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseOverEventListenerWithOptions:
    (
      [@mel.as "mouseover"] _,
      Dom.mouseEvent => unit,
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
  external addMouseOverEventListenerUseCapture:
    (
      [@mel.as "mouseover"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseOverEventListener:
    ([@mel.as "mouseover"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseOverEventListenerWithOptions:
    (
      [@mel.as "mouseover"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseOverEventListenerUseCapture:
    (
      [@mel.as "mouseover"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addMouseUpEventListener:
    ([@mel.as "mouseup"] _, Dom.mouseEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addMouseUpEventListenerWithOptions:
    (
      [@mel.as "mouseup"] _,
      Dom.mouseEvent => unit,
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
  external addMouseUpEventListenerUseCapture:
    (
      [@mel.as "mouseup"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseUpEventListener:
    ([@mel.as "mouseup"] _, Dom.mouseEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeMouseUpEventListenerWithOptions:
    (
      [@mel.as "mouseup"] _,
      Dom.mouseEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeMouseUpEventListenerUseCapture:
    (
      [@mel.as "mouseup"] _,
      Dom.mouseEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Wheel */

  [@mel.send.pipe: T.t]
  external addWheelEventListener:
    ([@mel.as "wheel"] _, Dom.wheelEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addWheelEventListenerWithOptions:
    (
      [@mel.as "wheel"] _,
      Dom.wheelEvent => unit,
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
  external addWheelEventListenerUseCapture:
    (
      [@mel.as "wheel"] _,
      Dom.wheelEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeWheelEventListener:
    ([@mel.as "wheel"] _, Dom.wheelEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeWheelEventListenerWithOptions:
    (
      [@mel.as "wheel"] _,
      Dom.wheelEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeWheelEventListenerUseCapture:
    (
      [@mel.as "wheel"] _,
      Dom.wheelEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Input */

  [@mel.send.pipe: T.t]
  external addBeforeInputEventListener:
    ([@mel.as "beforeinput"] _, Dom.inputEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addBeforeInputEventListenerWithOptions:
    (
      [@mel.as "beforeinput"] _,
      Dom.inputEvent => unit,
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
  external addBeforeInputEventListenerUseCapture:
    (
      [@mel.as "beforeinput"] _,
      Dom.inputEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeBeforeInputEventListener:
    ([@mel.as "beforeinput"] _, Dom.inputEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeBeforeInputEventListenerWithOptions:
    (
      [@mel.as "beforeinput"] _,
      Dom.inputEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeBeforeInputEventListenerUseCapture:
    (
      [@mel.as "beforeinput"] _,
      Dom.inputEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addInputEventListener:
    ([@mel.as "input"] _, Dom.inputEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addInputEventListenerWithOptions:
    (
      [@mel.as "input"] _,
      Dom.inputEvent => unit,
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
  external addInputEventListenerUseCapture:
    (
      [@mel.as "input"] _,
      Dom.inputEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeInputEventListener:
    ([@mel.as "input"] _, Dom.inputEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeInputEventListenerWithOptions:
    (
      [@mel.as "input"] _,
      Dom.inputEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeInputEventListenerUseCapture:
    (
      [@mel.as "input"] _,
      Dom.inputEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Keyboard */

  [@mel.send.pipe: T.t]
  external addKeyDownEventListener:
    ([@mel.as "keydown"] _, Dom.keyboardEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addKeyDownEventListenerWithOptions:
    (
      [@mel.as "keydown"] _,
      Dom.keyboardEvent => unit,
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
  external addKeyDownEventListenerUseCapture:
    (
      [@mel.as "keydown"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyDownEventListener:
    ([@mel.as "keydown"] _, Dom.keyboardEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyDownEventListenerWithOptions:
    (
      [@mel.as "keydown"] _,
      Dom.keyboardEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeKeyDownEventListenerUseCapture:
    (
      [@mel.as "keydown"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addKeyUpEventListener:
    ([@mel.as "keyup"] _, Dom.keyboardEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addKeyUpEventListenerWithOptions:
    (
      [@mel.as "keyup"] _,
      Dom.keyboardEvent => unit,
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
  external addKeyUpEventListenerUseCapture:
    (
      [@mel.as "keyup"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyUpEventListener:
    ([@mel.as "keyup"] _, Dom.keyboardEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyUpEventListenerWithOptions:
    (
      [@mel.as "keyup"] _,
      Dom.keyboardEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeKeyUpEventListenerUseCapture:
    (
      [@mel.as "keyup"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addKeyPressEventListener:
    ([@mel.as "keypress"] _, Dom.keyboardEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addKeyPressEventListenerWithOptions:
    (
      [@mel.as "keypress"] _,
      Dom.keyboardEvent => unit,
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
  external addKeyPressEventListenerUseCapture:
    (
      [@mel.as "keypress"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyPressEventListener:
    ([@mel.as "keypress"] _, Dom.keyboardEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeKeyPressEventListenerWithOptions:
    (
      [@mel.as "keypress"] _,
      Dom.keyboardEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeKeyPressEventListenerUseCapture:
    (
      [@mel.as "keypress"] _,
      Dom.keyboardEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Composition */

  [@mel.send.pipe: T.t]
  external addCompositionStartEventListener:
    ([@mel.as "compositionstart"] _, Dom.compositionEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addCompositionStartEventListenerWithOptions:
    (
      [@mel.as "compositionstart"] _,
      Dom.compositionEvent => unit,
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
  external addCompositionStartEventListenerUseCapture:
    (
      [@mel.as "compositionstart"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionStartEventListener:
    ([@mel.as "compositionstart"] _, Dom.compositionEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionStartEventListenerWithOptions:
    (
      [@mel.as "compositionstart"] _,
      Dom.compositionEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeCompositionStartEventListenerUseCapture:
    (
      [@mel.as "compositionstart"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addCompositionUpdateEventListener:
    ([@mel.as "compositionupdate"] _, Dom.compositionEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addCompositionUpdateEventListenerWithOptions:
    (
      [@mel.as "compositionupdate"] _,
      Dom.compositionEvent => unit,
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
  external addCompositionUpdateEventListenerUseCapture:
    (
      [@mel.as "compositionupdate"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionUpdateEventListener:
    ([@mel.as "compositionupdate"] _, Dom.compositionEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionUpdateEventListenerWithOptions:
    (
      [@mel.as "compositionupdate"] _,
      Dom.compositionEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeCompositionUpdateEventListenerUseCapture:
    (
      [@mel.as "compositionupdate"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addCompositionEndEventListener:
    ([@mel.as "compositionend"] _, Dom.compositionEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addCompositionEndEventListenerWithOptions:
    (
      [@mel.as "compositionend"] _,
      Dom.compositionEvent => unit,
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
  external addCompositionEndEventListenerUseCapture:
    (
      [@mel.as "compositionend"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionEndEventListener:
    ([@mel.as "compositionend"] _, Dom.compositionEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeCompositionEndEventListenerWithOptions:
    (
      [@mel.as "compositionend"] _,
      Dom.compositionEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeCompositionEndEventListenerUseCapture:
    (
      [@mel.as "compositionend"] _,
      Dom.compositionEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Drag */

  [@mel.send.pipe: T.t]
  external addDragEventListener:
    ([@mel.as "drag"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragEventListenerWithOptions:
    (
      [@mel.as "drag"] _,
      Dom.dragEvent => unit,
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
  external addDragEventListenerUseCapture:
    (
      [@mel.as "drag"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEventListener:
    ([@mel.as "drag"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEventListenerWithOptions:
    (
      [@mel.as "drag"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragEventListenerUseCapture:
    (
      [@mel.as "drag"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragEndEventListener:
    ([@mel.as "dragend"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragEndEventListenerWithOptions:
    (
      [@mel.as "dragend"] _,
      Dom.dragEvent => unit,
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
  external addDragEndEventListenerUseCapture:
    (
      [@mel.as "dragend"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEndEventListener:
    ([@mel.as "dragend"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEndEventListenerWithOptions:
    (
      [@mel.as "dragend"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragEndEventListenerUseCapture:
    (
      [@mel.as "dragend"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragEnterEventListener:
    ([@mel.as "dragenter"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragEnterEventListenerWithOptions:
    (
      [@mel.as "dragenter"] _,
      Dom.dragEvent => unit,
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
  external addDragEnterEventListenerUseCapture:
    (
      [@mel.as "dragenter"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEnterEventListener:
    ([@mel.as "dragenter"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragEnterEventListenerWithOptions:
    (
      [@mel.as "dragenter"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragEnterEventListenerUseCapture:
    (
      [@mel.as "dragenter"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragExitEventListener:
    ([@mel.as "dragexit"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragExitEventListenerWithOptions:
    (
      [@mel.as "dragexit"] _,
      Dom.dragEvent => unit,
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
  external addDragExitEventListenerUseCapture:
    (
      [@mel.as "dragexit"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragExitEventListener:
    ([@mel.as "dragexit"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragExitEventListenerWithOptions:
    (
      [@mel.as "dragexit"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragExitEventListenerUseCapture:
    (
      [@mel.as "dragexit"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragLeaveEventListener:
    ([@mel.as "dragleave"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragLeaveEventListenerWithOptions:
    (
      [@mel.as "dragleave"] _,
      Dom.dragEvent => unit,
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
  external addDragLeaveEventListenerUseCapture:
    (
      [@mel.as "dragleave"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragLeaveEventListener:
    ([@mel.as "dragleave"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragLeaveEventListenerWithOptions:
    (
      [@mel.as "dragleave"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragLeaveEventListenerUseCapture:
    (
      [@mel.as "dragleave"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragOverEventListener:
    ([@mel.as "dragover"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragOverEventListenerWithOptions:
    (
      [@mel.as "dragover"] _,
      Dom.dragEvent => unit,
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
  external addDragOverEventListenerUseCapture:
    (
      [@mel.as "dragover"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragOverEventListener:
    ([@mel.as "dragover"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragOverEventListenerWithOptions:
    (
      [@mel.as "dragover"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragOverEventListenerUseCapture:
    (
      [@mel.as "dragover"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDragStartEventListener:
    ([@mel.as "dragstart"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDragStartEventListenerWithOptions:
    (
      [@mel.as "dragstart"] _,
      Dom.dragEvent => unit,
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
  external addDragStartEventListenerUseCapture:
    (
      [@mel.as "dragstart"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDragStartEventListener:
    ([@mel.as "dragstart"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDragStartEventListenerWithOptions:
    (
      [@mel.as "dragstart"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDragStartEventListenerUseCapture:
    (
      [@mel.as "dragstart"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addDropEventListener:
    ([@mel.as "drop"] _, Dom.dragEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addDropEventListenerWithOptions:
    (
      [@mel.as "drop"] _,
      Dom.dragEvent => unit,
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
  external addDropEventListenerUseCapture:
    (
      [@mel.as "drop"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeDropEventListener:
    ([@mel.as "drop"] _, Dom.dragEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeDropEventListenerWithOptions:
    (
      [@mel.as "drop"] _,
      Dom.dragEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeDropEventListenerUseCapture:
    (
      [@mel.as "drop"] _,
      Dom.dragEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Touch */

  [@mel.send.pipe: T.t]
  external addTouchCancelEventListener:
    ([@mel.as "touchcancel"] _, Dom.touchEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addTouchCancelEventListenerWithOptions:
    (
      [@mel.as "touchcancel"] _,
      Dom.touchEvent => unit,
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
  external addTouchCancelEventListenerUseCapture:
    (
      [@mel.as "touchcancel"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchCancelEventListener:
    ([@mel.as "touchcancel"] _, Dom.touchEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchCancelEventListenerWithOptions:
    (
      [@mel.as "touchcancel"] _,
      Dom.touchEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeTouchCancelEventListenerUseCapture:
    (
      [@mel.as "touchcancel"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addTouchEndEventListener:
    ([@mel.as "touchend"] _, Dom.touchEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addTouchEndEventListenerWithOptions:
    (
      [@mel.as "touchend"] _,
      Dom.touchEvent => unit,
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
  external addTouchEndEventListenerUseCapture:
    (
      [@mel.as "touchend"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchEndEventListener:
    ([@mel.as "touchend"] _, Dom.touchEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchEndEventListenerWithOptions:
    (
      [@mel.as "touchend"] _,
      Dom.touchEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeTouchEndEventListenerUseCapture:
    (
      [@mel.as "touchend"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addTouchMoveEventListener:
    ([@mel.as "touchmove"] _, Dom.touchEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addTouchMoveEventListenerWithOptions:
    (
      [@mel.as "touchmove"] _,
      Dom.touchEvent => unit,
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
  external addTouchMoveEventListenerUseCapture:
    (
      [@mel.as "touchmove"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchMoveEventListener:
    ([@mel.as "touchmove"] _, Dom.touchEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchMoveEventListenerWithOptions:
    (
      [@mel.as "touchmove"] _,
      Dom.touchEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeTouchMoveEventListenerUseCapture:
    (
      [@mel.as "touchmove"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addTouchStartEventListener:
    ([@mel.as "touchstart"] _, Dom.touchEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addTouchStartEventListenerWithOptions:
    (
      [@mel.as "touchstart"] _,
      Dom.touchEvent => unit,
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
  external addTouchStartEventListenerUseCapture:
    (
      [@mel.as "touchstart"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchStartEventListener:
    ([@mel.as "touchstart"] _, Dom.touchEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeTouchStartEventListenerWithOptions:
    (
      [@mel.as "touchstart"] _,
      Dom.touchEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeTouchStartEventListenerUseCapture:
    (
      [@mel.as "touchstart"] _,
      Dom.touchEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  /* Animation */

  [@mel.send.pipe: T.t]
  external addAnimationCancelEventListener:
    ([@mel.as "animationcancel"] _, Dom.animationEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addAnimationCancelEventListenerWithOptions:
    (
      [@mel.as "animationcancel"] _,
      Dom.animationEvent => unit,
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
  external addAnimationCancelEventListenerUseCapture:
    (
      [@mel.as "animationcancel"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationCancelEventListener:
    ([@mel.as "animationcancel"] _, Dom.animationEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationCancelEventListenerWithOptions:
    (
      [@mel.as "animationcancel"] _,
      Dom.animationEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeAnimationCancelEventListenerUseCapture:
    (
      [@mel.as "animationcancel"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addAnimationEndEventListener:
    ([@mel.as "animationend"] _, Dom.animationEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addAnimationEndEventListenerWithOptions:
    (
      [@mel.as "animationend"] _,
      Dom.animationEvent => unit,
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
  external addAnimationEndEventListenerUseCapture:
    (
      [@mel.as "animationend"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationEndEventListener:
    ([@mel.as "animationend"] _, Dom.animationEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationEndEventListenerWithOptions:
    (
      [@mel.as "animationend"] _,
      Dom.animationEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeAnimationEndEventListenerUseCapture:
    (
      [@mel.as "animationend"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addAnimationIterationEventListener:
    ([@mel.as "animationiteration"] _, Dom.animationEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addAnimationIterationEventListenerWithOptions:
    (
      [@mel.as "animationiteration"] _,
      Dom.animationEvent => unit,
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
  external addAnimationIterationEventListenerUseCapture:
    (
      [@mel.as "animationiteration"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationIterationEventListener:
    ([@mel.as "animationiteration"] _, Dom.animationEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationIterationEventListenerWithOptions:
    (
      [@mel.as "animationiteration"] _,
      Dom.animationEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeAnimationIterationEventListenerUseCapture:
    (
      [@mel.as "animationiteration"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";

  [@mel.send.pipe: T.t]
  external addAnimationStartEventListener:
    ([@mel.as "animationstart"] _, Dom.animationEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external addAnimationStartEventListenerWithOptions:
    (
      [@mel.as "animationstart"] _,
      Dom.animationEvent => unit,
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
  external addAnimationStartEventListenerUseCapture:
    (
      [@mel.as "animationstart"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "addEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationStartEventListener:
    ([@mel.as "animationstart"] _, Dom.animationEvent => unit) => unit =
    "removeEventListener";
  [@mel.send.pipe: T.t]
  external removeAnimationStartEventListenerWithOptions:
    (
      [@mel.as "animationstart"] _,
      Dom.animationEvent => unit,
      {
        .
        "capture": bool,
        "passive": bool,
      }
    ) =>
    unit =
    "removeEventListener"; /* not widely supported */
  [@mel.send.pipe: T.t]
  external removeAnimationStartEventListenerUseCapture:
    (
      [@mel.as "animationstart"] _,
      Dom.animationEvent => unit,
      [@mel.as {json|true|json}] _
    ) =>
    unit =
    "removeEventListener";
};

include Impl({
  type nonrec t = Dom.eventTarget;
});

external unsafeAsDocument: Dom.eventTarget => Dom.document = "%identity";
external unsafeAsElement: Dom.eventTarget => Dom.element = "%identity";
external unsafeAsWindow: Dom.eventTarget => Dom.window = "%identity";
