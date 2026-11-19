open Melange_json.Primitives;

[@deriving json]
type point = {
  x: int,
  [@json.key "label"]
  name: string,
};

[@deriving json]
type shape =
  | Circle(float)
  | Square(int)
  | Empty;

[@deriving json]
type tone = [
  | `Warm
  | `Cold(int)
];

module Expected = {
  let string = {js|$1 café "quoted"|js} ++ "\n";
  let int = (-42);
  let float = 3.25;
  let bool = false;
  let some: option(string) = Some("x");
  let none: option(string) = None;
  let list = [1, 2, 3];
  let array = [|"a", "$b"|];
  let tuple = (1, "two", 3.5);
  let point = {
    x: 1,
    name: "n",
  };
  let shape = Circle(1.5);
  let constant = Empty;
  let tone: tone = `Cold(3);
  let ok: result(int, string) = Ok(1);
  let error: result(int, string) = Error("bad");
  let char = 'x';
  let highChar = Char.chr(233);
  let int64 = 9007199254740993L;
  let nested: list(option(result((shape, array(tone)), string))) = [
    Some(Ok((Square(2), [|`Warm|]))),
  ];
};

let check = (value, expected) => Js.Promise.resolve(value == expected);

[@react.server.function]
let sendString = (value: string): Js.Promise.t(bool) =>
  check(value, Expected.string);

[@react.server.function]
let sendInt = (value: int): Js.Promise.t(bool) =>
  check(value, Expected.int);

[@react.server.function]
let sendFloat = (value: float): Js.Promise.t(bool) =>
  check(value, Expected.float);

[@react.server.function]
let sendBool = (value: bool): Js.Promise.t(bool) =>
  check(value, Expected.bool);

[@react.server.function]
let sendUnit = (): Js.Promise.t(bool) => check((), ());

[@react.server.function]
let sendOptions =
    (some: option(string), none: option(string)): Js.Promise.t(bool) =>
  check((some, none), (Expected.some, Expected.none));

[@react.server.function]
let sendList = (value: list(int)): Js.Promise.t(bool) =>
  check(value, Expected.list);

[@react.server.function]
let sendArray = (value: array(string)): Js.Promise.t(bool) =>
  check(value, Expected.array);

[@react.server.function]
let sendTuple = (value: (int, string, float)): Js.Promise.t(bool) =>
  check(value, Expected.tuple);

[@react.server.function]
let sendRecord = (value: point): Js.Promise.t(bool) =>
  check(value, Expected.point);

[@react.server.function]
let sendVariant = (value: shape, constant: shape): Js.Promise.t(bool) =>
  check((value, constant), (Expected.shape, Expected.constant));

[@react.server.function]
let sendPolyVariant = (value: tone): Js.Promise.t(bool) =>
  check(value, Expected.tone);

[@react.server.function]
let sendResults =
    (ok: result(int, string), error: result(int, string))
    : Js.Promise.t(bool) =>
  check((ok, error), (Expected.ok, Expected.error));

[@react.server.function]
let sendChar = (value: char, high: char): Js.Promise.t(bool) =>
  check((value, high), (Expected.char, Expected.highChar));

[@react.server.function]
let sendInt64 = (value: int64): Js.Promise.t(bool) =>
  check(value, Expected.int64);

[@react.server.function]
let sendNested =
    (value: list(option(result((shape, array(tone)), string))))
    : Js.Promise.t(bool) =>
  check(value, Expected.nested);

[@react.server.function]
let sendLabelled =
    ((), ~count: int, ~label: string="default", ~note: option(string)=?, ())
    : Js.Promise.t(bool) =>
  check((count, label, note), (Expected.int, "default", Expected.some));

[@react.server.function]
let sendForm = (prefix: string, formData: Js.FormData.t): Js.Promise.t(bool) =>
  check(
    (prefix, Js.FormData.get(formData, "name")),
    (Expected.string, `String("Ada")),
  );
