/** The Webapi library (stubbed) */
module Base64 = Webapi__Base64;

module Blob = Webapi__Blob;
module Canvas = Webapi__Canvas;
module Dom = Webapi__Dom;
module File = Webapi__File;

module FormData = Fetch.FormData;

module Iterator = FormData.Iterator;

module Performance = Webapi__Performance;

module ReadableStream = Webapi__ReadableStream;

module ResizeObserver = Webapi__ResizeObserver;
module Url = Webapi__Url;

type rafId;

external requestAnimationFrame: (float => unit) => unit =
  "requestAnimationFrame";
external requestCancellableAnimationFrame: (float => unit) => rafId =
  "requestAnimationFrame";
external cancelAnimationFrame: rafId => unit = "cancelAnimationFrame";
