type expected =
  | Values(list((string, list(string))))
  | Fails(string);

type case = {
  name: string,
  search: string,
  expected,
};

let cases = [
  {
    name: "valid pairs",
    search: "?a=1&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "empty pairs",
    search: "?&a=1&&b=&",
    expected: Values([("a", ["1"]), ("b", [""])]),
  },
  {
    name: "plus is a space",
    search: "?q=a+b",
    expected: Values([("q", ["a%20b"])]),
  },
  {
    name: "escaped plus",
    search: "?q=a%2Bb",
    expected: Values([("q", ["a%2Bb"])]),
  },
  {
    name: "upper and lower hex",
    search: "?u=%C3%A9&l=%c3%a9",
    expected: Values([("u", ["%C3%A9"]), ("l", ["%C3%A9"])]),
  },
  {
    name: "raw space",
    search: "?a=b c",
    expected: Values([("a", ["b%20c"])]),
  },
  {
    name: "malformed escape",
    search: "?q=%ZZ",
    expected: Fails("malformed %ZZ"),
  },
  {
    name: "malformed escape in a key",
    search: "?%ZZ=1",
    expected: Fails("malformed %ZZ"),
  },
  {
    name: "truncated escape",
    search: "?q=ab%4",
    expected: Fails("malformed ab%4"),
  },
  {
    name: "lone percent",
    search: "?q=%",
    expected: Fails("malformed %"),
  },
  {
    name: "invalid UTF-8 byte",
    search: "?q=%FF",
    expected: Fails("malformed %FF"),
  },
  {
    name: "overlong two-byte form",
    search: "?q=%C0%AF",
    expected: Fails("malformed %C0%AF"),
  },
  {
    name: "overlong three-byte form",
    search: "?q=%E0%80%AF",
    expected: Fails("malformed %E0%80%AF"),
  },
  {
    name: "encoded surrogate",
    search: "?q=%ED%A0%80",
    expected: Fails("malformed %ED%A0%80"),
  },
  {
    name: "four-byte emoji",
    search: "?e=%F0%9F%98%80",
    expected: Values([("e", ["%F0%9F%98%80"])]),
  },
  {
    name: "repeated keys keep their order",
    search: "?a=1&b=2&a=3",
    expected: Values([("a", ["1", "3"]), ("b", ["2"])]),
  },
  {
    name: "repeated keys past eight names",
    search: "?k1=1&k2=2&k3=3&k4=4&k5=5&k6=6&k7=7&k8=8&k9=9&k1=x&k9=y",
    expected:
      Values([
        ("k1", ["1", "x"]),
        ("k2", ["2"]),
        ("k3", ["3"]),
        ("k4", ["4"]),
        ("k5", ["5"]),
        ("k6", ["6"]),
        ("k7", ["7"]),
        ("k8", ["8"]),
        ("k9", ["9", "y"]),
      ]),
  },
  {
    name: "names without a value",
    search: "?flag&x",
    expected: Values([("flag", [""]), ("x", [""])]),
  },
  {
    name: "empty name",
    search: "?=v",
    expected: Values([("", ["v"])]),
  },
  {
    name: "equals sign in a value",
    search: "?a=b=c",
    expected: Values([("a", ["b%3Dc"])]),
  },
  {
    name: "no leading question mark",
    search: "a=1",
    expected: Values([("a", ["1"])]),
  },
  {
    name: "empty search",
    search: "",
    expected: Values([]),
  },
  {
    name: "query too long",
    search: "?a=" ++ String.make(8190, 'x'),
    expected: Fails("too long"),
  },
];

let failures = (~parse, ~encode) =>
  List.filter_map(
    case => {
      let actual =
        switch (parse(case.search)) {
        | Ok(values) =>
          Values(
            List.map(
              ((key, values)) => (encode(key), List.map(encode, values)),
              values,
            ),
          )
        | Error(error) => Fails(error)
        };
      actual == case.expected ? None : Some(case.name);
    },
    cases,
  );
