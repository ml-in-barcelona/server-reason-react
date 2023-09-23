/*
 * Spec: https://html.spec.whatwg.org/multipage/forms.html#the-form-element
 * MDN: https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement
 */

module Impl = (T: {
                 type t;
               }) => {
  type t_htmlFormElement = T.t;

  /* TODO: elements: HTMLFormControlsCollection */
  [@mel.get] external length: t_htmlFormElement => int = "length";
  [@mel.get] external name: t_htmlFormElement => string = "name";
  [@mel.set] external setName: (t_htmlFormElement, string) => unit = "name";
  [@mel.get] external method: t_htmlFormElement => string = "method";
  [@mel.set]
  external setMethod: (t_htmlFormElement, string) => unit = "method";
  [@mel.get] external target: t_htmlFormElement => string = "target";
  [@mel.set]
  external setTarget: (t_htmlFormElement, string) => unit = "target";
  [@mel.get] external action: t_htmlFormElement => string = "action";
  [@mel.set]
  external setAction: (t_htmlFormElement, string) => unit = "action";
  [@mel.get]
  external acceptCharset: t_htmlFormElement => string = "acceptCharset";
  [@mel.set]
  external setAcceptCharset: (t_htmlFormElement, string) => unit =
    "acceptCharset";
  [@mel.get]
  external autocomplete: t_htmlFormElement => string = "autocomplete";
  [@mel.set]
  external setAutocomplete: (t_htmlFormElement, string) => unit =
    "autocomplete";
  [@mel.get] external noValidate: t_htmlFormElement => bool = "noValidate";
  [@mel.set]
  external setNoValidate: (t_htmlFormElement, bool) => unit = "noValidate";
  [@mel.get] external enctype: t_htmlFormElement => string = "enctype";
  [@mel.set]
  external setEnctype: (t_htmlFormElement, string) => unit = "enctype";
  [@mel.get] external encoding: t_htmlFormElement => string = "encoding";
  [@mel.set]
  external setEncoding: (t_htmlFormElement, string) => unit = "encoding";

  [@mel.send.pipe: t_htmlFormElement] external submit: unit = "submit";
  [@mel.send.pipe: t_htmlFormElement] external reset: unit = "reset";
  [@mel.send.pipe: t_htmlFormElement]
  external checkValidity: bool = "checkValidity";
  [@mel.send.pipe: t_htmlFormElement]
  external reportValidity: bool = "reportValidity";

  /** @since 0.18.0 */
  [@mel.new]
  external data: T.t => Fetch.FormData.t = "FormData";
};

type t = Dom.htmlFormElement;

include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__Element.Impl({
  type nonrec t = t;
});
include Webapi__Dom__HtmlElement.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
