open Webapi.Dom;
open CompositionEvent;

let event = make("my-event");

let _ = bubbles(event);
let _ = cancelable(event);
let _ = composed(event);
let _ = currentTarget(event);
let _ = defaultPrevented(event);
let _ = eventPhase(event);
let _ = target(event);
let _ = timeStamp(event);
let _ = type_(event);
let _ = isTrusted(event);

preventDefault(event);
stopImmediatePropagation(event);
stopPropagation(event);

let _ = detail(event);
let _ = view(event);

let _ = data(event);
