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
    name: "broken escape is dropped like in route decode",
    pathname: "/app/notes",
    search: "?q=%zz",
    href: "/app/notes?q=%25zz",
    current: false,
  },
  {
    name: "malformed pair against no pair",
    pathname: "/app/notes",
    search: "?x=%FF&q=1",
    href: "/app/notes?q=1",
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

type activeCase = {
  activeName: string,
  rule: string,
  currentPath: string,
  linkHref: string,
  active: bool,
};

let activeCases = [
  {
    activeName: "route ignores the search",
    rule: "route",
    currentPath: "/app/notes",
    linkHref: "/app/notes?page=2#top",
    active: true,
  },
  {
    activeName: "route is exact on the path",
    rule: "route",
    currentPath: "/app/notes/1",
    linkHref: "/app/notes",
    active: false,
  },
  {
    activeName: "subtree matches below",
    rule: "subtree",
    currentPath: "/app/notes/1/edit",
    linkHref: "/app/notes",
    active: true,
  },
  {
    activeName: "subtree compares whole segments",
    rule: "subtree",
    currentPath: "/app/notes-archive",
    linkHref: "/app/notes",
    active: false,
  },
  {
    activeName: "subtree compares decoded segments",
    rule: "subtree",
    currentPath: "/app/caf%c3%a9/1",
    linkHref: "/app/caf%C3%A9",
    active: true,
  },
  {
    activeName: "subtree of the root",
    rule: "subtree",
    currentPath: "/app",
    linkHref: "/",
    active: true,
  },
  {
    activeName: "subtree does not match above",
    rule: "subtree",
    currentPath: "/app",
    linkHref: "/app/notes",
    active: false,
  },
];

let activeFailures = isActive =>
  List.filter_map(
    case =>
      isActive(
        ~prefix=String.equal(case.rule, "subtree"),
        ~pathname=case.currentPath,
        case.linkHref,
      )
      == case.active
        ? None : Some(case.activeName),
    activeCases,
  );
