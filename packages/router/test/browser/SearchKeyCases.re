type case = {
  name: string,
  pathname: string,
  search: string,
  href: string,
  current: bool,
};

let cases = [
  {
    name: "reordered names",
    pathname: "/app/notes",
    search: "?b=1&a=2",
    href: "/app/notes?a=2&b=1",
    current: true,
  },
  {
    name: "plus and %20",
    pathname: "/app/notes",
    search: "?q=a+b",
    href: "/app/notes?q=a%20b",
    current: true,
  },
  {
    name: "escape letter case",
    pathname: "/app/notes",
    search: "?q=%c3%a9",
    href: "/app/notes?q=%C3%A9",
    current: true,
  },
  {
    name: "malformed UTF-8 against its replacement",
    pathname: "/app/notes",
    search: "?q=%FF",
    href: "/app/notes?q=%EF%BF%BD",
    current: false,
  },
  {
    name: "broken escape as text",
    pathname: "/app/notes",
    search: "?q=%zz",
    href: "/app/notes?q=%25zz",
    current: true,
  },
  {
    name: "empty pair",
    pathname: "/app/notes",
    search: "?a=1&&b=2",
    href: "/app/notes?b=2&a=1",
    current: true,
  },
  {
    name: "order of repeated values",
    pathname: "/app/notes",
    search: "?a=1&a=2",
    href: "/app/notes?a=2&a=1",
    current: false,
  },
  {
    name: "name without value",
    pathname: "/app/notes",
    search: "?flag",
    href: "/app/notes?flag=",
    current: true,
  },
  {
    name: "hash ignored",
    pathname: "/app/notes",
    search: "",
    href: "/app/notes#top",
    current: true,
  },
  {
    name: "missing search",
    pathname: "/app/notes",
    search: "?a=1",
    href: "/app/notes",
    current: false,
  },
  {
    name: "child path",
    pathname: "/app/notes",
    search: "",
    href: "/app/notes/1",
    current: false,
  },
];

let failures = isCurrent =>
  List.filter_map(
    case =>
      isCurrent(~pathname=case.pathname, ~search=case.search, case.href)
      == case.current
        ? None : Some(case.name),
    cases,
  );
