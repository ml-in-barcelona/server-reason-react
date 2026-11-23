type console;
type crypto;
type frameList;
type idleDeadline;
type locationbar;
type menubar;
type navigator;
type personalbar;
type screen;
type scrollbars;
type speechSynthesis;
type statusbar;
type toolbar;
type mediaQueryList;
type transferable;

type idleCallbackId;

module Impl = (T: {
                 type t;
               }) => {
  type t_window = T.t;

  [@mel.get] external console: t_window => console = "console";
  [@mel.get] external crypto: t_window => crypto = "crypto";
  [@mel.get] external document: t_window => Dom.document = "document";
  [@mel.get] [@mel.return nullable]
  external frameElement: t_window => option(Dom.element) = "frameElement";
  [@mel.get] external frames: t_window => frameList = "frames";
  [@mel.get] external fullScreen: t_window => bool = "fullScreen";
  [@mel.get] external history: t_window => Dom.history = "history";
  [@mel.get] external innerWidth: t_window => int = "innerWidth";
  [@mel.get] external innerHeight: t_window => int = "innerHeight";
  [@mel.get] external isSecureContext: t_window => bool = "isSecureContext";
  [@mel.get] external length: t_window => int = "length";
  [@mel.get] external location: t_window => Dom.location = "location";
  [@mel.set] external setLocation: (t_window, string) => unit = "location";
  [@mel.get] external locationbar: t_window => locationbar = "locationbar";
  [@mel.get] external menubar: t_window => menubar = "menubar";
  [@mel.get] external name: t_window => string = "name";
  [@mel.set] external setName: (t_window, string) => unit = "name";
  [@mel.get] external navigator: t_window => navigator = "navigator";
  [@mel.get] [@mel.return nullable]
  external opener: t_window => option(Dom.window) = "opener";
  [@mel.get] external outerWidth: t_window => int = "outerWidth";
  [@mel.get] external outerHeight: t_window => int = "outerHeight";
  [@mel.get] external pageXOffset: t_window => float = "pageXOffset";
  [@mel.get] external pageYOffset: t_window => float = "pageYOffset";
  [@mel.get] external parent: t_window => Dom.window = "parent";
  [@mel.get]
  external performance: t_window => Webapi__Performance.t = "performance";
  [@mel.get] external personalbar: t_window => personalbar = "personalbar";
  [@mel.get] external screen: t_window => screen = "screen";
  [@mel.get] external screenX: t_window => int = "screenX";
  [@mel.get] external screenY: t_window => int = "screenY";
  [@mel.get] external scrollbars: t_window => scrollbars = "scrollbars";
  [@mel.get] external scrollX: t_window => float = "scrollX";
  [@mel.get] external scrollY: t_window => float = "scrollY";
  [@mel.get] external self: t_window => Dom.window = "self";
  [@mel.get]
  external speechSynthesis: t_window => speechSynthesis = "speechSynthesis";
  [@mel.get] external status: t_window => string = "status";
  [@mel.set] external setStatus: (t_window, string) => unit = "status";
  [@mel.get] external statusbar: t_window => statusbar = "statusbar";
  [@mel.get] external toolbar: t_window => toolbar = "toolbar";
  [@mel.get] external top: t_window => Dom.window = "top";
  [@mel.get] external window: t_window => t_window = "window";

  [@mel.send.pipe: t_window] external alert: string => unit = "alert";
  [@mel.send.pipe: t_window] external blur: unit = "blur";
  [@mel.send.pipe: t_window]
  external cancelIdleCallback: idleCallbackId => unit = "cancelIdleCallback";
  [@mel.send.pipe: t_window] external close: unit = "close";
  [@mel.send.pipe: t_window] external confirm: string => bool = "confirm";
  [@mel.send.pipe: t_window] external focus: unit = "focus";
  [@mel.send.pipe: t_window]
  external getComputedStyle: Dom.element => Dom.cssStyleDeclaration =
    "getComputedStyle";
  [@mel.send.pipe: t_window]
  external getComputedStyleWithPseudoElement:
    (Dom.element, string) => Dom.cssStyleDeclaration =
    "getComputedStyle";
  [@mel.send.pipe: t_window]
  external getSelection: Dom.selection = "getSelection";
  [@mel.send.pipe: t_window]
  external matchMedia: string => mediaQueryList = "matchMedia";
  [@mel.send.pipe: t_window] external moveBy: (int, int) => unit = "moveBy";
  [@mel.send.pipe: t_window] external moveTo: (int, int) => unit = "moveTo";
  [@mel.send.pipe: t_window] [@mel.return nullable]
  external open_:
    (~url: string, ~name: string, ~features: string=?) => option(Dom.window) =
    "open";
  [@mel.send.pipe: t_window]
  external postMessage: ('a, string) => unit = "postMessage";
  [@mel.send.pipe: t_window]
  external postMessageWithTransfers: ('a, string, array(transferable)) => unit =
    "postMessage";
  [@mel.send.pipe: t_window] external print: unit = "print";
  [@mel.send.pipe: t_window] external prompt: string => string = "prompt";
  [@mel.send.pipe: t_window]
  external promptWithDefault: (string, string) => string = "prompt";
  [@mel.send.pipe: t_window]
  external requestIdleCallback: (idleDeadline => unit) => idleCallbackId =
    "requestIdleCallback";
  [@mel.send.pipe: t_window]
  external requestIdleCallbackWithOptions:
    (idleDeadline => unit, {. "timeout": int }) => idleCallbackId =
    "requestIdleCallback";
  [@mel.send.pipe: t_window]
  external resizeBy: (int, int) => unit = "resizeBy";
  [@mel.send.pipe: t_window]
  external resizeTo: (int, int) => unit = "resizeTo";
  [@mel.send.pipe: t_window]
  external scroll: (float, float) => unit = "scroll";
  [@mel.send.pipe: t_window]
  external scrollBy: (float, float) => unit = "scrollBy";
  [@mel.send.pipe: t_window]
  external scrollTo: (float, float) => unit = "scrollTo";
  [@mel.send.pipe: t_window] external stop: unit = "stop";

  [@mel.send.pipe: t_window]
  external addPopStateEventListener:
    ([@mel.as "popstate"] _, Dom.popStateEvent => unit) => unit =
    "addEventListener";
  [@mel.send.pipe: t_window]
  external removePopStateEventListener:
    ([@mel.as "popstate"] _, Dom.popStateEvent => unit) => unit =
    "removeEventListener";

  [@mel.set] external setOnLoad: (t_window, unit => unit) => unit = "onload";
};

type t = Dom.window;

include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__GlobalEventHandlers.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
