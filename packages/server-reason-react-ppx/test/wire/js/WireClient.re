open WireFunctions;

let makeForm: unit => Js.FormData.t = [%mel.raw
  {|function () { const form = new FormData(); form.append("name", "Ada"); return form; }|}
];

let _ = sendString.call(Expected.string);
let _ = sendInt.call(Expected.int);
let _ = sendFloat.call(Expected.float);
let _ = sendBool.call(Expected.bool);
let _ = sendUnit.call();
let _ = sendOptions.call(Expected.some, Expected.none);
let _ = sendList.call(Expected.list);
let _ = sendArray.call(Expected.array);
let _ = sendTuple.call(Expected.tuple);
let _ = sendRecord.call(Expected.point);
let _ = sendVariant.call(Expected.shape, Expected.constant);
let _ = sendPolyVariant.call(Expected.tone);
let _ = sendResults.call(Expected.ok, Expected.error);
let _ = sendChar.call(Expected.char, Expected.highChar);
let _ = sendInt64.call(Expected.int64);
let _ = sendNested.call(Expected.nested);
let _ = sendLabelled.call((), ~count=Expected.int, ~note="x", ());
let _ = sendForm.call(Expected.string, makeForm());
let _ = sendDefaultAlias.call(~x=None, ());
