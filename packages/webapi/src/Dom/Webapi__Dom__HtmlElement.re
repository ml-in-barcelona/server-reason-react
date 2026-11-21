module Impl = (T: {
                 type t;
               }) => {
  type t_htmlElement = T.t;

  let%melange_only ofElement = Webapi__Dom__Element.asHtmlElement;

  [@mel.get] external accessKey: t_htmlElement => string = "accessKey";
  [@mel.set]
  external setAccessKey: (t_htmlElement, string) => unit = "accessKey";
  [@mel.get]
  external accessKeyLabel: t_htmlElement => string = "accessKeyLabel";
  [@mel.get]
  external contentEditable: t_htmlElement => string = "contentEditable";
  let contentEditable: t_htmlElement => Webapi__Dom__Types.contentEditable =
      self =>
    Webapi__Dom__Types.decodeContentEditable(contentEditable(self));
  [@mel.set]
  external setContentEditable: (t_htmlElement, string) => unit =
    "contentEditable";
  let setContentEditable
      : (t_htmlElement, Webapi__Dom__Types.contentEditable) => unit =
      (self, value) =>
    setContentEditable(
      self,
      Webapi__Dom__Types.encodeContentEditable(value),
    );
  [@mel.get]
  external isContentEditable: t_htmlElement => bool = "isContentEditable";
  [@mel.get]
  external contextMenu: t_htmlElement => Dom.htmlElement = "contextMenu";
  [@mel.set]
  external setContextMenu: (t_htmlElement, Dom.htmlElement) => unit =
    "contextMenu";
  [@mel.get] external dataset: t_htmlElement => Dom.domStringMap = "dataset";
  [@mel.get] external dir: t_htmlElement => string = "dir";
  let dir: t_htmlElement => Webapi__Dom__Types.dir = self =>
    Webapi__Dom__Types.decodeDir(dir(self));
  [@mel.set] external setDir: (t_htmlElement, string) => unit = "dir";
  let setDir: (t_htmlElement, Webapi__Dom__Types.dir) => unit = (self, value) =>
    setDir(self, Webapi__Dom__Types.encodeDir(value));
  [@mel.get] external draggable: t_htmlElement => bool = "draggable";
  [@mel.set]
  external setDraggable: (t_htmlElement, bool) => unit = "draggable";
  [@mel.get]
  external dropzone: t_htmlElement => Dom.domSettableTokenList = "dropzone";
  [@mel.get] external hidden: t_htmlElement => bool = "hidden";
  [@mel.set] external setHidden: (t_htmlElement, bool) => unit = "hidden";
  [@mel.get] external itemScope: t_htmlElement => bool = "itemScope";
  [@mel.set]
  external setItemScope: (t_htmlElement, bool) => unit = "itemScope";
  [@mel.get]
  external itemType: t_htmlElement => Dom.domSettableTokenList = "itemType";
  [@mel.get] external itemId: t_htmlElement => string = "itemId";
  [@mel.set] external setItemId: (t_htmlElement, string) => unit = "itemId";
  [@mel.get]
  external itemRef: t_htmlElement => Dom.domSettableTokenList = "itemRef";
  [@mel.get]
  external itemProp: t_htmlElement => Dom.domSettableTokenList = "itemProp";
  [@mel.get] external itemValue: t_htmlElement => Js.t({..}) = "itemValue";
  [@mel.set]
  external setItemValue: (t_htmlElement, Js.t({..})) => unit = "itemValue";
  [@mel.get] external lang: t_htmlElement => string = "lang";
  [@mel.set] external setLang: (t_htmlElement, string) => unit = "lang";
  [@mel.get] external offsetHeight: t_htmlElement => int = "offsetHeight";
  [@mel.get] external offsetLeft: t_htmlElement => int = "offsetLeft";
  [@mel.get] [@mel.return nullable]
  external offsetParent: t_htmlElement => option(Dom.element) =
    "offsetParent";
  [@mel.get] external offsetTop: t_htmlElement => int = "offsetTop";
  [@mel.get] external offsetWidth: t_htmlElement => int = "offsetWidth";
  [@mel.get] external spellcheck: t_htmlElement => bool = "spellcheck";
  [@mel.set]
  external setSpellcheck: (t_htmlElement, bool) => unit = "spellcheck";
  [@mel.get]
  external style: t_htmlElement => Dom.cssStyleDeclaration = "style";
  [@mel.set]
  external setStyle: (t_htmlElement, Dom.cssStyleDeclaration) => unit =
    "style";
  [@mel.get] external tabIndex: t_htmlElement => int = "tabIndex";
  [@mel.set] external setTabIndex: (t_htmlElement, int) => unit = "tabIndex";
  [@mel.get] external title: t_htmlElement => string = "title";
  [@mel.set] external setTitle: (t_htmlElement, string) => unit = "title";
  [@mel.get] external translate: t_htmlElement => bool = "translate";
  [@mel.set]
  external setTranslate: (t_htmlElement, bool) => unit = "translate";
  [@mel.send.pipe: t_htmlElement] external blur: unit = "blur";
  [@mel.send.pipe: t_htmlElement] external click: unit = "click";
  [@mel.send.pipe: t_htmlElement] external focus: unit = "focus";
  [@mel.send.pipe: t_htmlElement]
  external focusPreventScroll:
    ([@mel.as {json|{ "preventScroll": true }|json}] _) => unit =
    "focus";
  [@mel.send.pipe: t_htmlElement]
  external forceSpellCheck: unit = "forceSpellCheck";

  [@mel.get] external value: t_htmlElement => string = "value";
  [@mel.get] external checked: t_htmlElement => bool = "checked";
  [@mel.get] external type_: t_htmlElement => string = "type";
  [@mel.set] external setType: (t_htmlElement, string) => unit = "type";
  [@mel.get] external rel: t_htmlElement => string = "rel";
  [@mel.set] external setRel: (t_htmlElement, string) => unit = "rel";
  [@mel.get] external href: t_htmlElement => string = "href";
  [@mel.set] external setHref: (t_htmlElement, string) => unit = "href";
};

type t = Dom.htmlElement;

include Webapi__Dom__Node.Impl({
  type nonrec t = t;
});
include Webapi__Dom__EventTarget.Impl({
  type nonrec t = t;
});
include Webapi__Dom__GlobalEventHandlers.Impl({
  type nonrec t = t;
});
include Webapi__Dom__Element.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});
