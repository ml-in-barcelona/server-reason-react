const React = require("react");
const utils = require("util");
const ReactDOM = require("react-dom/server");

let first = React.createElement(
  "div",
  { key: "fi", value1: "aaa", style: { margin: "1px" } },
  ["first"]
);
let clon = React.cloneElement(
  first,
  { value: "bbb", more: 22, style: { margin: "1", padding: "0px" } },
  ["asdf"]
);

const { Provider, Consumer } = React.createContext(10);

var app = () => {
  /* https://fb.me/react-uselayouteffect-ssr */
  React.useLayoutEffect(() => {
    console.log("asdfdsf");

    return () => {
      console.log("asdfsdf");
    };
  });
  return React.createElement("div", { className: "contenido" }, []);
};

var app = () => {
  let [state, setState] = React.useState(0);

  React.useEffect(() => {
    setState(state + 1);
    console.log("asdfdsf");

    return () => {
      console.log("asdfsdf");
    };
  });
  return React.createElement("div", { className: "contenido" }, []);
};

var app = () => {
  let [state, setState] = React.useState(0);
  let ref = React.useRef(true);
  console.log(state);
  if (ref.current) {
    setState(state + 1);
    ref.current = false;
  }
  React.useEffect(() => {
    console.log("asfsdafsafsadf");
  });
  React.useEffect(() => {
    console.log("asfsdafsafsadf");
  }, [state]);
  console.log(state);
  return React.createElement("div", null, [state]);
};

/* var app = () => {
  return React.createElement("div", {
    dangerouslySetInnerHTML: { __html: "asdf" },
  });
}; */

var ctx = React.createContext(10);

var context_user = () => {
  let a = React.useContext(ctx);
  console.log(a);
  return React.createElement("div", { key: 1 }, [a]);
};

var app = () => {
  let ref = React.useRef(333);
  console.log(ref);
  return React.createElement(
    ctx.Provider,
    { value: 0, ref: ref },
    React.createElement(context_user)
  );
};

var app = React.forwardRef(() => {
  let ref = React.useRef(333);
  console.log(ref);
  return React.createElement(
    ctx.Provider,
    { value: 0, ref: ref },
    React.createElement(context_user)
  );
});

var app = () => {
  return React.createElement("div", { about: "' <" }, ['& "']);
};

/* console.log(ReactDOM.renderToStaticMarkup(React.createElement(app, null))); */

const murmur2 = (str) => {
  // 'm' and 'r' are mixing constants generated offline.
  // They're not really 'magic', they just happen to work well.

  // const m = 0x5bd1e995;
  // const r = 24;

  // Initialize the hash

  var h = 0;

  // Mix 4 bytes at a time into the hash

  var k,
    i = 0,
    len = str.length;
  for (; len >= 4; ++i, len -= 4) {
    k =
      (str.charCodeAt(i) & 0xff) |
      ((str.charCodeAt(i + 1) & 0xff) << 8) |
      ((str.charCodeAt(i + 2) & 0xff) << 16) |
      ((str.charCodeAt(i + 3) & 0xff) << 24);

    /* console.log(str.charCodeAt(i) & 0xff); */
    /* console.log((str.charCodeAt(i + 1) & 0xff) << 8); */
    /* console.log((str.charCodeAt(i + 2) & 0xff) << 16); */
    /* console.log((str.charCodeAt(i + 3) & 0xff) << 24); */
    /* console.log("--"); */

    let k_one = (k & 0xffff) * 0x5bd1e995;
    /* console.log(k & 0xffff); */
    /* console.log(k_one); */
    let k_pre_16 = (k >>> 16) * 0xe995;
    /* console.log(k_pre_16); */
    let k_16 = k_pre_16 << 16;
    /* console.log(k_16); */

    k = k_one + k_16;
    /* console.log(k); */
    /* console.log(k ^ (k >>> 24)); */
    k ^= /* k >>> r: */ k >>> 24;
    /* console.log(k); */
    /* console.log("--"); */

    h =
      /* Math.imul(k, m): */
      ((k & 0xffff) * 0x5bd1e995 + (((k >>> 16) * 0xe995) << 16)) ^
      /* Math.imul(h, m): */
      ((h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16));
    /* console.log((k & 0xffff) * 0x5bd1e995 + (((k >>> 16) * 0xe995) << 16)); */
    /* console.log((h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16)); */
    /* console.log(((k >>> 16) * 0xe995) << 16); */
    /* console.log((h & 0xffff) * 0x5bd1e995); */
    /* console.log(((h >>> 16) * 0xe995) << 16); */
    /* console.log(h); */
  }

  // Handle the last few bytes of the input array

  /* switch (len) {
    case 3:
      h ^= (str.charCodeAt(i + 2) & 0xff) << 16;
    case 2:
      h ^= (str.charCodeAt(i + 1) & 0xff) << 8;
    case 1:
      h ^= str.charCodeAt(i) & 0xff;
      h =
        (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16);
  } */

  // Do a few final mixes of the hash to ensure the last few
  // bytes are well-incorporated.

  /* console.log(h >>> 13); */

  h ^= h >>> 13;
  /* console.log(h); */

  h =
    /* Math.imul(h, m): */
    (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16);

  /* console.log("h-post: ", h); */

  let result = ((h ^ (h >>> 15)) >>> 0).toString(36);
  console.log("Result: ", result);
  return result;
};

murmur2("display: block");
murmur2("display: flex");
