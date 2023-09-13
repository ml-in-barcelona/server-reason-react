type t = Dom.idbVersionChangeEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "IDBVersionChangeEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "IDBVersionChangeEvent";

[@mel.get] external oldVersion: t => int = "oldVersion";
[@mel.get] external newVersion: t => int = "newVersion";
