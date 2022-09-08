module Console: {
  [@js.global "console.log"]
  let log: 'a => unit;
  [@js.global "console.log"]
  let log2: ('a, 'b) => unit;
  [@js.global "console.log"]
  let log3: ('a, 'b, 'c) => unit;
  [@js.global "console.log"]
  let log4: ('a, 'b, 'c, 'd) => unit;
};

module Window: {
  type window;
  [@js.global "window"]
  let get: option(window);
  [@js.call]
  let alert: (window, string) => unit;
  [@js.get]
  let value: Ojs.t => string;
};
