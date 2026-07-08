// The registry of reply-direction spec cases: the arguments a client passes
// to a server function, encoded by the REAL React `encodeReply` (the public
// wrapper over processReply) in generate-reply.mjs.
//
// Each case is `{ name, args, options? }` where `args` is a thunk returning
// the argument array to encode (a thunk so mutable values like FormData are
// rebuilt per run) and `options` an optional thunk returning encodeReply
// options. Determinism rules: fixed Date instants only, Map/Set/FormData
// are serialized by React in insertion order.
//
// This module must be imported AFTER the __webpack_require__ shims are
// installed (see generate-reply.mjs): client.browser expects webpack globals.
import {
  createServerReference,
  createTemporaryReferenceSet,
} from "react-server-dom-webpack/client.browser";

// Bun quirk: Bun defines a non-standard, non-configurable
// `FormData.prototype.toJSON`. JSON.stringify calls it BEFORE handing the
// value to React's replacer, so processReply's `instanceof FormData` branch
// ($K) never runs and the FormData leaks through as a plain object. Browsers
// have no FormData.prototype.toJSON. Shadow it per instance to restore the
// web-standard behavior React was written against.
function webFormData(fd) {
  Object.defineProperty(fd, "toJSON", { value: undefined });
  return fd;
}

function userFormData() {
  const fd = webFormData(new FormData());
  fd.append("name", "Lola");
  fd.append("age", "20");
  return fd;
}

// The client stub of a server function. The id is `<module>#<export>`; the
// second argument (callServer) is never invoked during encoding.
const serverRef = () => createServerReference("srv#action", async () => {});

export const cases = [
  // ------------------------------------------------------------------
  // String bodies: no Map/Set/Blob/FormData/reference in the arguments,
  // so encodeReply returns a plain JSON string.
  // ------------------------------------------------------------------
  { name: "primitives", args: () => ["hello", 42, 3.14, true, false, null] },
  { name: "numbers", args: () => [0, -1, 1073741824, 1e21, 1.5, -3.5] },
  { name: "empty_args", args: () => [] },
  // User strings starting with `$` are escaped by prepending one `$`.
  { name: "dollar_strings", args: () => ["$money", "$$x", "$", "price is $10"] },
  { name: "undefined_arg", args: () => ["a", undefined, 42] },
  { name: "date", args: () => [new Date("2024-01-15T10:30:00.000Z")] },
  { name: "bigint", args: () => [9007199254740993n] },
  { name: "nonfinite_numbers", args: () => [NaN, Infinity, -Infinity, -0] },
  {
    name: "nested_object",
    args: () => [{ user: { name: "Lola", tags: ["a", "b"] }, meta: null }],
  },
  { name: "nested_array", args: () => [[1, [2, [3]]]] },
  { name: "unicode_string", args: () => ["héllo → 🚀", "line\nbreak\ttab"] },
  {
    name: "mixed_special",
    args: () => ["hello", undefined, 42, new Date("2024-06-15T00:00:00.000Z"), NaN, Infinity],
  },
  // With a temporary reference set, values that cannot be serialized
  // (functions, symbols, elements) encode as "$T" — path-keyed, no id.
  {
    name: "temporary_reference",
    args: () => [{ fn: () => {} }],
    options: () => ({ temporaryReferences: createTemporaryReferenceSet() }),
  },

  // ------------------------------------------------------------------
  // FormData bodies: outlined models. React appends outlined parts first,
  // then the root model at key "0".
  // ------------------------------------------------------------------
  {
    name: "map_string_keys",
    args: () => [
      new Map([
        ["name", "Alice"],
        ["role", "admin"],
      ]),
    ],
  },
  {
    name: "map_number_keys",
    args: () => [
      new Map([
        [1, "one"],
        [2, "two"],
      ]),
    ],
  },
  { name: "map_empty", args: () => [new Map()] },
  {
    name: "map_of_dates",
    args: () => [new Map([["d", new Date("2024-06-15T00:00:00.000Z")]])],
  },
  { name: "set_numbers", args: () => [new Set([1, 2, 3])] },
  { name: "set_strings", args: () => [new Set(["a", "b", "c"])] },
  { name: "set_in_map", args: () => [new Map([["nums", new Set([10, 20, 30])]])] },
  { name: "map_in_object", args: () => [{ config: new Map([["x", 1]]) }, "tail"] },
  { name: "formdata", args: () => [userFormData()] },
  { name: "formdata_with_leading_arg", args: () => ["Hello", userFormData()] },
  {
    name: "formdata_nested",
    args: () => {
      const fd = webFormData(new FormData());
      fd.append("name", "Lola");
      return [{ form: fd }];
    },
  },
  {
    name: "blob_text",
    args: () => [new Blob(["blob-content-here"], { type: "text/plain" })],
  },
  { name: "server_reference", args: () => [serverRef()] },
  { name: "server_reference_nested", args: () => [{ fn: serverRef() }] },
];
