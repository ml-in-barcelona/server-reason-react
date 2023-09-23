type t = Dom.storageEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "StorageEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "StorageEvent";

[@mel.get] external key: t => string = "key";
[@mel.get] external newValue: t => Js.Nullable.t(string) = "newValue";
[@mel.get] external oldValue: t => Js.Nullable.t(string) = "oldValue";
[@mel.get] external storageArea: t => Dom.Storage.t = "storageArea";
[@mel.get] external url: t => string = "url";
