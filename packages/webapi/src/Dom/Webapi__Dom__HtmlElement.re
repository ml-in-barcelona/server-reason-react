module Impl = (T: {
                 type t;
               }) => {
  type t_htmlElement = T.t;

  let ofElement = Webapi__Dom__Element.asHtmlElement;

  [@mel.get] external accessKey: t_htmlElement => string = "accessKey";
  [@mel.set]
  external setAccessKey: (t_htmlElement, string) => unit = "accessKey";
  [@mel.get]
  external accessKeyLabel: t_htmlElement => string = "accessKeyLabel";
  [@mel.get]
  external contentEditable: t_htmlElement => string /* enum */ =
    "contentEditable";
  let contentEditable: t_htmlElement => Webapi__Dom__Types.contentEditable =
    self => Webapi__Dom__Types.decodeContentEditable(contentEditable(self));
  [@mel.set]
  external setContentEditable: (t_htmlElement, string /* enum */) => unit =
    "contentEditable";
  let setContentEditable:
    (t_htmlElement, Webapi__Dom__Types.contentEditable) => unit =
    (self, value) =>
      setContentEditable(
        self,
        Webapi__Dom__Types.encodeContentEditable(value),
      );
  [@mel.get]
  external isContentEditable: t_htmlElement => bool = "isContentEditable";
  [@mel.get]
  external contextMenu: t_htmlElement => Dom.htmlElement = "contextMenu"; /* returns HTMLMenuElement */
  [@mel.set]
  external setContextMenu: (t_htmlElement, Dom.htmlElement) => unit =
    "contextMenu"; /* accepts and returns HTMLMenuElement */
  [@mel.get] external dataset: t_htmlElement => Dom.domStringMap = "dataset";
  [@mel.get] external dir: t_htmlElement => string /* enum */ = "dir";
  let dir: t_htmlElement => Webapi__Dom__Types.dir =
    self => Webapi__Dom__Types.decodeDir(dir(self));
  [@mel.set]
  external setDir: (t_htmlElement, string /* enum */) => unit = "dir";
  let setDir: (t_htmlElement, Webapi__Dom__Types.dir) => unit =
    (self, value) => setDir(self, Webapi__Dom__Types.encodeDir(value));
  [@mel.get] external draggable: t_htmlElement => bool = "draggable";
  [@mel.set] external setDraggable: (t_htmlElement, bool) => unit = "draggable" /*let setDraggable : t_htmlElement => bool => unit = fun self value => setDraggable self (Js.Boolean.to_js_boolean value);*/; /* temproarily removed to reduce codegen size */
  [@mel.get]
  external dropzone: t_htmlElement => Dom.domSettableTokenList = "dropzone";
  [@mel.get] external hidden: t_htmlElement => bool = "hidden";
  [@mel.set] external setHidden: (t_htmlElement, bool) => unit = "hidden" /*let setHidden : t_htmlElement => bool => unit = fun self value => setHidden self (Js.Boolean.to_js_boolean value);*/; /* temproarily removed to reduce codegen size */
  [@mel.get] external itemScope: t_htmlElement => bool = "itemScope"; /* experimental */
  [@mel.set] external setItemScope: (t_htmlElement, bool) => unit = "itemScope" /*let setItemScope : t_htmlElement => bool => unit = fun self value => setItemScope self (Js.Boolean.to_js_boolean value);*/; /* experimental */ /* temproarily removed to reduce codegen size */
  [@mel.get]
  external itemType: t_htmlElement => Dom.domSettableTokenList = "itemType"; /* experimental */
  [@mel.get] external itemId: t_htmlElement => string = "itemId"; /* experimental */
  [@mel.set] external setItemId: (t_htmlElement, string) => unit = "itemId"; /* experimental */
  [@mel.get]
  external itemRef: t_htmlElement => Dom.domSettableTokenList = "itemRef"; /* experimental */
  [@mel.get]
  external itemProp: t_htmlElement => Dom.domSettableTokenList = "itemProp"; /* experimental */
  [@mel.get] external itemValue: t_htmlElement => Js.t({..}) = "itemValue"; /* experimental */
  [@mel.set]
  external setItemValue: (t_htmlElement, Js.t({..})) => unit = "itemValue"; /* experimental */
  [@mel.get] external lang: t_htmlElement => string = "lang";
  [@mel.set] external setLang: (t_htmlElement, string) => unit = "lang";
  [@mel.get] external offsetHeight: t_htmlElement => int = "offsetHeight"; /* experimental */
  [@mel.get] external offsetLeft: t_htmlElement => int = "offsetLeft"; /* experimental */
  [@mel.get] [@mel.return nullable]
  external offsetParent: t_htmlElement => option(Dom.element) =
    "offsetParent"; /* experimental */
  [@mel.get] external offsetTop: t_htmlElement => int = "offsetTop"; /* experimental, but widely supported */
  [@mel.get] external offsetWidth: t_htmlElement => int = "offsetWidth"; /* experimental */
  /*external properties : r => HTMLPropertiesCollection.t = "properties" [@@mel.get]; /* experimental */*/
  [@mel.get] external spellcheck: t_htmlElement => bool = "spellcheck";
  [@mel.set]
  external setSpellcheck: (t_htmlElement, bool) => unit = "spellcheck" /*let setSpellcheck : t_htmlElement => bool => unit = fun self value => setSpellcheck self (Js.Boolean.to_js_boolean value);*/; /* temproarily removed to reduce codegen size */
  [@mel.get]
  external style: t_htmlElement => Dom.cssStyleDeclaration = "style";
  [@mel.set]
  external setStyle: (t_htmlElement, Dom.cssStyleDeclaration) => unit =
    "style";
  [@mel.get] external tabIndex: t_htmlElement => int = "tabIndex";
  [@mel.set] external setTabIndex: (t_htmlElement, int) => unit = "tabIndex";
  [@mel.get] external title: t_htmlElement => string = "title";
  [@mel.set] external setTitle: (t_htmlElement, string) => unit = "title";
  [@mel.get] external translate: t_htmlElement => bool = "translate"; /* experimental */
  [@mel.set] external setTranslate: (t_htmlElement, bool) => unit = "translate" /*let setTranslate : t_htmlElement => bool => unit = fun self value => setTranslate self (Js.Boolean.to_js_boolean value);*/; /* experimental */ /* temproarily removed to reduce codegen size */
  [@mel.send.pipe: t_htmlElement] external blur: unit = "blur";
  [@mel.send.pipe: t_htmlElement] external click: unit = "click";
  [@mel.send.pipe: t_htmlElement] external focus: unit = "focus";
  [@mel.send.pipe: t_htmlElement]
  external focusPreventScroll:
    ([@mel.as {json|{ "preventScroll": true }|json}] _) => unit =
    "focus";
  [@mel.send.pipe: t_htmlElement]
  external forceSpellCheck: unit = "forceSpellCheck"; /* experimental */

  /* TODO: element-spcific, should be pulled out */
  [@mel.get] external value: t_htmlElement => string = "value"; /* HTMLInputElement */
  [@mel.get] external checked: t_htmlElement => bool = "checked"; /* HTMLInputElement */
  [@mel.get] external type_: t_htmlElement => string = "type"; /* HTMLStyleElement */
  [@mel.set] external setType: (t_htmlElement, string) => unit = "type"; /* HTMLStyleElement */
  [@mel.get] external rel: t_htmlElement => string = "rel"; /* HTMLLinkElement */
  [@mel.set] external setRel: (t_htmlElement, string) => unit = "rel"; /* HTMLLinkElement */
  [@mel.get] external href: t_htmlElement => string = "href"; /* HTMLLinkElement, HTMLAnchorElement */
  [@mel.set] external setHref: (t_htmlElement, string) => unit = "href"; /* HTMLLinkElement, HTMLAnchorElement */
};

/* TODO
   module Tree (T: { type t; }) => {
     include ElementRe.Tree { type t = Type };
     include Impl { type t = Type };
   };

   include Tree { type t = Dom.htmlElement };
   */

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
