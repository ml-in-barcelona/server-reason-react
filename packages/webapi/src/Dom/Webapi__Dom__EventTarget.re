module Impl = (T: {
                 type t;
               }) => {
  external asEventTarget: T.t => Dom.eventTarget = "%identity";

  let addEventListener =
      (_eventName: string, _callback: Dom.event => unit, _t: T.t) =>
    ();

  let addEventListenerWithOptions =
      (
        _eventName: string,
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "once": bool,
          "passive": bool,
        },
        _t: T.t,
      ) =>
    ();

  let addEventListenerUseCapture =
      (_eventName: string, _callback: Dom.event => unit, _t: T.t): unit =>
    ();

  let removeEventListener =
      (_eventName: string, _callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeEventListenerWithOptions =
      (
        _eventName: string,
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      ) =>
    ();
  let removeEventListenerUseCapture =
      (_string, _callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let dispatchEvent: Dom.event_like('a) => bool = _eventLike => false;

  /**
   *  non-standard event-specific functions
   */
  /* UI */
  let addLoadEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let addLoadEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
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
  let addLoadEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeLoadEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeLoadEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeLoadEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();

  let addUnloadEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let addUnloadEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
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
  let addUnloadEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeUnloadEventListener =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeUnloadEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeUnloadEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();

  let addAbortEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let addAbortEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
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
  let addAbortEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeAbortEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeAbortEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeAbortEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();

  let addErrorEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let addErrorEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
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
  let addErrorEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeErrorEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeErrorEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeErrorEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();

  let addSelectEventListener = (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let addSelectEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
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
  let addSelectEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeSelectEventListener =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();
  let removeSelectEventListenerWithOptions =
      (
        _callback: Dom.event => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeSelectEventListenerUseCapture =
      (_callback: Dom.event => unit, _t: T.t): unit =>
    ();

  /* Focus */

  let addBlurEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let addBlurEventListenerWithOptions =
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
  let addBlurEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeBlurEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeBlurEventListenerWithOptions =
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
  let removeBlurEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();

  let addFocusEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let addFocusEventListenerWithOptions =
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
  let addFocusEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusEventListenerWithOptions =
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
  let removeFocusEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();

  let addFocusInEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let addFocusInEventListenerWithOptions =
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
  let addFocusInEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusInEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusInEventListenerWithOptions =
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
  let removeFocusInEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();

  let addFocusOutEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let addFocusOutEventListenerWithOptions =
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
  let addFocusOutEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusOutEventListener =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();
  let removeFocusOutEventListenerWithOptions =
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
  let removeFocusOutEventListenerUseCapture =
      (_callback: Dom.focusEvent => unit, _t: T.t): unit =>
    ();

  /* Mouse */

  let addClickEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addClickEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addClickEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeClickEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeClickEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeClickEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addDblClickEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addDblClickEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addDblClickEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeDblClickEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeDblClickEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDblClickEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseDownEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseDownEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseDownEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseDownEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseDownEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseDownEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseEnterEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseEnterEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseEnterEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseEnterEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseEnterEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseEnterEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseMoveEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseMoveEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseMoveEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseMoveEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseMoveEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseMoveEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseOutEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseOutEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseOutEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseOutEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseOutEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseOutEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseOverEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseOverEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseOverEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseOverEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseOverEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseOverEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  let addMouseUpEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let addMouseUpEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
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
  let addMouseUpEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseUpEventListener =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();
  let removeMouseUpEventListenerWithOptions =
      (
        _callback: Dom.mouseEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeMouseUpEventListenerUseCapture =
      (_callback: Dom.mouseEvent => unit, _t: T.t): unit =>
    ();

  /* Wheel */

  let addWheelEventListener =
      (_callback: Dom.wheelEvent => unit, _t: T.t): unit =>
    ();
  let addWheelEventListenerWithOptions =
      (
        _callback: Dom.wheelEvent => unit,
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
  let addWheelEventListenerUseCapture =
      (_callback: Dom.wheelEvent => unit, _t: T.t): unit =>
    ();
  let removeWheelEventListener =
      (_callback: Dom.wheelEvent => unit, _t: T.t): unit =>
    ();
  let removeWheelEventListenerWithOptions =
      (
        _callback: Dom.wheelEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeWheelEventListenerUseCapture =
      (_callback: Dom.wheelEvent => unit, _t: T.t): unit =>
    ();

  /* Input */

  let addBeforeInputEventListener =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let addBeforeInputEventListenerWithOptions =
      (
        _callback: Dom.inputEvent => unit,
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
  let addBeforeInputEventListenerUseCapture =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let removeBeforeInputEventListener =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let removeBeforeInputEventListenerWithOptions =
      (
        _callback: Dom.inputEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeBeforeInputEventListenerUseCapture =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();

  let addInputEventListener =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let addInputEventListenerWithOptions =
      (
        _callback: Dom.inputEvent => unit,
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
  let addInputEventListenerUseCapture =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let removeInputEventListener =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();
  let removeInputEventListenerWithOptions =
      (
        _callback: Dom.inputEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeInputEventListenerUseCapture =
      (_callback: Dom.inputEvent => unit, _t: T.t): unit =>
    ();

  /* Keyboard */

  let addKeyDownEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let addKeyDownEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
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
  let addKeyDownEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyDownEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyDownEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeKeyDownEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();

  let addKeyUpEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let addKeyUpEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
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
  let addKeyUpEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyUpEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyUpEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeKeyUpEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();

  let addKeyPressEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let addKeyPressEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
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
  let addKeyPressEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyPressEventListener =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();
  let removeKeyPressEventListenerWithOptions =
      (
        _callback: Dom.keyboardEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeKeyPressEventListenerUseCapture =
      (_callback: Dom.keyboardEvent => unit, _t: T.t): unit =>
    ();

  /* Composition */

  let addCompositionStartEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let addCompositionStartEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
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
  let addCompositionStartEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionStartEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionStartEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeCompositionStartEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();

  let addCompositionUpdateEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let addCompositionUpdateEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
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
  let addCompositionUpdateEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionUpdateEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionUpdateEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeCompositionUpdateEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();

  let addCompositionEndEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let addCompositionEndEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
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
  let addCompositionEndEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionEndEventListener =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();
  let removeCompositionEndEventListenerWithOptions =
      (
        _callback: Dom.compositionEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeCompositionEndEventListenerUseCapture =
      (_callback: Dom.compositionEvent => unit, _t: T.t): unit =>
    ();

  /* Drag */

  let addDragEventListener = (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragEndEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragEndEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragEndEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEndEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEndEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragEndEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragEnterEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragEnterEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragEnterEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEnterEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragEnterEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragEnterEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragExitEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragExitEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragExitEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragExitEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragExitEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragExitEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragLeaveEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragLeaveEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragLeaveEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragLeaveEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragLeaveEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragLeaveEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragOverEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragOverEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragOverEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragOverEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragOverEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragOverEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDragStartEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDragStartEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDragStartEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragStartEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDragStartEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDragStartEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  let addDropEventListener = (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let addDropEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
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
  let addDropEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDropEventListener =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();
  let removeDropEventListenerWithOptions =
      (
        _callback: Dom.dragEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeDropEventListenerUseCapture =
      (_callback: Dom.dragEvent => unit, _t: T.t): unit =>
    ();

  /* Touch */

  let addTouchCancelEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let addTouchCancelEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
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
  let addTouchCancelEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchCancelEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchCancelEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeTouchCancelEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();

  let addTouchEndEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let addTouchEndEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
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
  let addTouchEndEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchEndEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchEndEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeTouchEndEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();

  let addTouchMoveEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let addTouchMoveEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
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
  let addTouchMoveEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchMoveEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchMoveEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeTouchMoveEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();

  let addTouchStartEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let addTouchStartEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
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
  let addTouchStartEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchStartEventListener =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();
  let removeTouchStartEventListenerWithOptions =
      (
        _callback: Dom.touchEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeTouchStartEventListenerUseCapture =
      (_callback: Dom.touchEvent => unit, _t: T.t): unit =>
    ();

  /* Animation */

  let addAnimationCancelEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let addAnimationCancelEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
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
  let addAnimationCancelEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationCancelEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationCancelEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeAnimationCancelEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();

  let addAnimationEndEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let addAnimationEndEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
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
  let addAnimationEndEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationEndEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationEndEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeAnimationEndEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();

  let addAnimationIterationEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let addAnimationIterationEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
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
  let addAnimationIterationEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationIterationEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationIterationEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeAnimationIterationEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();

  let addAnimationStartEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let addAnimationStartEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
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
  let addAnimationStartEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationStartEventListener =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
  let removeAnimationStartEventListenerWithOptions =
      (
        _callback: Dom.animationEvent => unit,
        _options: {
          .
          "capture": bool,
          "passive": bool,
        },
        _t: T.t,
      )
      : unit =>
    ();
  let removeAnimationStartEventListenerUseCapture =
      (_callback: Dom.animationEvent => unit, _t: T.t): unit =>
    ();
};

include Impl({
  type nonrec t = Dom.eventTarget;
});

external unsafeAsDocument: Dom.eventTarget => Dom.document = "%identity";
external unsafeAsElement: Dom.eventTarget => Dom.element = "%identity";
external unsafeAsWindow: Dom.eventTarget => Dom.window = "%identity";
