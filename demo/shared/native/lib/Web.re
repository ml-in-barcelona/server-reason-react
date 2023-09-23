open Webapi.Dom;
module Option = Belt.Option;
module List = {
  include Belt.List;
  let joinWith = (stringList, separator) => String.concat(separator, stringList);
};

let baseUrl = (base) =>
    Document.querySelector("base", document)
    ->Option.mapWithDefault("", url => Element.getAttribute("href", url)->Option.getWithDefault(""))
    ++ base->List.joinWith("/")
    ++ "/";
