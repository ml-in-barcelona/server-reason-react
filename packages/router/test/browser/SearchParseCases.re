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
    search: "?a=1&q=%ZZ&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "malformed escape in a key",
    search: "?%ZZ=1&a=1",
    expected: Values([("a", ["1"])]),
  },
  {
    name: "truncated escape",
    search: "?a=1&q=ab%4&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "lone percent",
    search: "?a=1&q=%&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "invalid UTF-8 byte",
    search: "?a=1&q=%FF&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "overlong two-byte form",
    search: "?a=1&q=%C0%AF&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "overlong three-byte form",
    search: "?a=1&q=%E0%80%AF&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "encoded surrogate",
    search: "?a=1&q=%ED%A0%80&b=2",
    expected: Values([("a", ["1"]), ("b", ["2"])]),
  },
  {
    name: "a malformed value among repeated keys",
    search: "?t=1&t=%FF&t=2&t=%ZZ",
    expected: Values([("t", ["1", "2"])]),
  },
  {
    name: "only malformed pairs",
    search: "?q=%ZZ&%FF",
    expected: Values([]),
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
