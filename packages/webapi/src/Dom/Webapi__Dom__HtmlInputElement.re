/*
 * Spec: https://html.spec.whatwg.org/multipage/input.html#the-input-element
 * MDN: https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement
 */

module Impl = (T: {
                 type t;
               }) => {
  type t_htmlInputElement = T.t;

  [@mel.get] [@mel.return nullable]
  external form: t_htmlInputElement => option(Dom.htmlFormElement) = "form";
  [@mel.get] external formAction: t_htmlInputElement => string = "formAction";
  [@mel.set]
  external setFormAction: (t_htmlInputElement, string) => unit = "formAction";
  [@mel.get]
  external formEncType: t_htmlInputElement => string = "formEncType";
  [@mel.set]
  external setFormEncType: (t_htmlInputElement, string) => unit =
    "formEncType";
  [@mel.get] external formMethod: t_htmlInputElement => string = "formMethod";
  [@mel.set]
  external setFormMethod: (t_htmlInputElement, string) => unit = "formMethod";
  [@mel.get]
  external formNoValidate: t_htmlInputElement => bool = "formNoValidate";
  [@mel.set]
  external setFormNoValidate: (t_htmlInputElement, bool) => unit =
    "formNoValidate";
  [@mel.get] external formTarget: t_htmlInputElement => string = "formTarget";
  [@mel.set]
  external setFormTarget: (t_htmlInputElement, string) => unit = "formTarget";

  /* Properties that apply to any type of input element that is not hidden */
  [@mel.get] external name: t_htmlInputElement => string = "name";
  [@mel.set] external setName: (t_htmlInputElement, string) => unit = "name";
  [@mel.get] external type_: t_htmlInputElement => string = "type";
  [@mel.set] external setType: (t_htmlInputElement, string) => unit = "type";
  [@mel.get] external disabled: t_htmlInputElement => bool = "disabled";
  [@mel.set]
  external setDisabled: (t_htmlInputElement, bool) => unit = "disabled";
  [@mel.get] external autofocus: t_htmlInputElement => bool = "autofocus";
  [@mel.set]
  external setAutofocus: (t_htmlInputElement, bool) => unit = "autofocus";
  [@mel.get] external required: t_htmlInputElement => bool = "required";
  [@mel.set]
  external setRequired: (t_htmlInputElement, bool) => unit = "required";
  [@mel.get] external value: t_htmlInputElement => string = "value";
  [@mel.set] external setValue: (t_htmlInputElement, string) => unit = "value";
  [@mel.get]
  external validity: t_htmlInputElement => Webapi__Dom__ValidityState.t =
    "validity";
  [@mel.get]
  external validationMessage: t_htmlInputElement => string =
    "validationMessage";
  [@mel.get]
  external willValidate: t_htmlInputElement => bool = "willValidate";

  /* Properties that apply only to elements of type "checkbox" or "radio" */
  [@mel.get] external checked: t_htmlInputElement => bool = "checked";
  [@mel.set]
  external setChecked: (t_htmlInputElement, bool) => unit = "checked";
  [@mel.get]
  external defaultChecked: t_htmlInputElement => bool = "defaultChecked";
  [@mel.set]
  external setDefaultChecked: (t_htmlInputElement, bool) => unit =
    "defaultChecked";
  [@mel.get]
  external indeterminate: t_htmlInputElement => bool = "indeterminate";
  [@mel.set]
  external setIndeterminate: (t_htmlInputElement, bool) => unit =
    "indeterminate";

  /* Properties that apply only to elements of type "image" */
  [@mel.get] external alt: t_htmlInputElement => string = "alt";
  [@mel.set] external setAlt: (t_htmlInputElement, string) => unit = "alt";
  [@mel.get] external height: t_htmlInputElement => string = "height";
  [@mel.set]
  external setHeight: (t_htmlInputElement, string) => unit = "height";
  [@mel.get] external src: t_htmlInputElement => string = "src";
  [@mel.set] external setSrc: (t_htmlInputElement, string) => unit = "src";
  [@mel.get] external width: t_htmlInputElement => string = "width";
  [@mel.set] external setWidth: (t_htmlInputElement, string) => unit = "width";

  /* Properties that apply only to elements of type "file" */
  [@mel.get] external accept: t_htmlInputElement => string = "accept";
  [@mel.set]
  external setAccept: (t_htmlInputElement, string) => unit = "accept";
  /* TODO: files: Returns/accepts a FileList object. */

  /* Properties that apply only to text/number-containing or elements */
  [@mel.get]
  external autocomplete: t_htmlInputElement => string = "autocomplete";
  [@mel.set]
  external setAutocomplete: (t_htmlInputElement, string) => unit =
    "autocomplete";
  [@mel.get] external maxLength: t_htmlInputElement => int = "maxLength";
  [@mel.set]
  external setMaxLength: (t_htmlInputElement, int) => unit = "maxLength";
  [@mel.get] external minLength: t_htmlInputElement => int = "minLength";
  [@mel.set]
  external setMinLength: (t_htmlInputElement, int) => unit = "minLength";
  [@mel.get] external size: t_htmlInputElement => int = "size";
  [@mel.set] external setSize: (t_htmlInputElement, int) => unit = "size";
  [@mel.get] external pattern: t_htmlInputElement => string = "pattern";
  [@mel.set]
  external setPattern: (t_htmlInputElement, string) => unit = "pattern";
  [@mel.get]
  external placeholder: t_htmlInputElement => string = "placeholder";
  [@mel.set]
  external setPlaceholder: (t_htmlInputElement, string) => unit =
    "placeholder";
  [@mel.get] external readOnly: t_htmlInputElement => bool = "readOnly";
  [@mel.set]
  external setReadOnly: (t_htmlInputElement, bool) => unit = "readOnly";
  [@mel.get] external min: t_htmlInputElement => string = "min";
  [@mel.set] external setMin: (t_htmlInputElement, string) => unit = "min";
  [@mel.get] external max: t_htmlInputElement => string = "max";
  [@mel.set] external setMax: (t_htmlInputElement, string) => unit = "max";
  [@mel.get]
  external selectionStart: t_htmlInputElement => int = "selectionStart";
  [@mel.set]
  external setSelectionStart: (t_htmlInputElement, int) => unit =
    "selectionStart";
  [@mel.get] external selectionEnd: t_htmlInputElement => int = "selectionEnd";
  [@mel.set]
  external setSelectionEnd: (t_htmlInputElement, int) => unit = "selectionEnd";
  [@mel.get]
  external selectionDirection: t_htmlInputElement => string =
    "selectionDirection";
  [@mel.set]
  external setSelectionDirection: (t_htmlInputElement, string) => unit =
    "selectionDirection";

  /* Properties not yet categorized */
  [@mel.get]
  external defaultValue: t_htmlInputElement => string = "defaultValue";
  [@mel.set]
  external setDefaultValue: (t_htmlInputElement, string) => unit =
    "defaultValue";
  [@mel.get] external dirName: t_htmlInputElement => string = "dirName";
  [@mel.set]
  external setDirName: (t_htmlInputElement, string) => unit = "dirName";
  [@mel.get] external accessKey: t_htmlInputElement => string = "accessKey";
  [@mel.set]
  external setAccessKey: (t_htmlInputElement, string) => unit = "accessKey";
  [@mel.get] [@mel.return nullable]
  external list: t_htmlInputElement => option(Dom.htmlElement) = "list";
  [@mel.get] external multiple: t_htmlInputElement => bool = "multiple";
  [@mel.set]
  external setMultiple: (t_htmlInputElement, bool) => unit = "multiple";
  /* TODO: files: FileList array. Returns the list of selected files. */
  [@mel.get]
  external labels: t_htmlInputElement => array(Dom.nodeList) = "labels";
  [@mel.get] external step: t_htmlInputElement => string = "step";
  [@mel.set] external setStep: (t_htmlInputElement, string) => unit = "step";
  [@mel.get] [@mel.return nullable]
  external valueAsDate: t_htmlInputElement => option(Js.Date.t) =
    "valueAsDate";
  [@mel.set]
  external setValueAsDate: (t_htmlInputElement, Js.Date.t) => unit =
    "valueAsDate";
  [@mel.get]
  external valueAsNumber: t_htmlInputElement => float = "valueAsNumber";

  [@mel.send.pipe: t_htmlInputElement] external select: unit = "select";

  module SelectionDirection = {
    type t =
      | Forward
      | Backward
      | None;

    let toString =
      fun
      | Forward => "forward"
      | Backward => "backward"
      | None => "none";
  };

  [@mel.send.pipe: t_htmlInputElement]
  external setSelectionRange: (int, int) => unit = "setSelectionRange";
  [@mel.send.pipe: t_htmlInputElement]
  external setSelectionRangeWithDirection_: (int, int, string) => unit =
    "setSelectionRange";
  let setSelectionRangeWithDirection =
      (selectionStart, selectionEnd, selectionDirection, element) =>
    element
    |> setSelectionRangeWithDirection_(
         selectionStart,
         selectionEnd,
         selectionDirection |> SelectionDirection.toString,
       );

  module SelectionMode = {
    type t =
      | Select
      | Start
      | End
      | Preserve;

    let toString =
      fun
      | Select => "select"
      | Start => "start"
      | End => "end"
      | Preserve => "preserve";
  };

  [@mel.send.pipe: t_htmlInputElement]
  external setRangeTextWithinSelection: string => unit = "setRangeText";
  [@mel.send.pipe: t_htmlInputElement]
  external setRangeTextWithinInterval: (string, int, int) => unit =
    "setRangeText";
  [@mel.send.pipe: t_htmlInputElement]
  external setRangeTextWithinIntervalWithSelectionMode_:
    (string, int, int, string) => unit =
    "setRangeText";
  let setRangeTextWithinIntervalWithSelectionMode =
      (text, selectionStart, selectionEnd, selectionMode, element) =>
    element
    |> setRangeTextWithinIntervalWithSelectionMode_(
         text,
         selectionStart,
         selectionEnd,
         selectionMode |> SelectionMode.toString,
       );

  [@mel.send.pipe: t_htmlInputElement]
  external setCustomValidity: string => unit = "setCustomValidity";
  [@mel.send.pipe: t_htmlInputElement]
  external checkValidity: bool = "checkValidity";
  [@mel.send.pipe: t_htmlInputElement]
  external reportValidity: bool = "reportValidity";
  [@mel.send.pipe: t_htmlInputElement]
  external stepDownBy: int => unit = "stepDown";
  [@mel.send.pipe: t_htmlInputElement]
  external stepDownByOne: unit = "stepDown";
  [@mel.send.pipe: t_htmlInputElement]
  external stepUpBy: int => unit = "stepUp";
  [@mel.send.pipe: t_htmlInputElement] external stepUpByOne: unit = "stepUp";
};

type t = Dom.htmlInputElement;

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
