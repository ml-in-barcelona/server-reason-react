const path = require("node:path");

globalThis.__webpack_require__ = Object.assign(() => ({}), { u: () => "" });
globalThis.__webpack_chunk_load__ = () => Promise.resolve();
globalThis.__wireCalls = [];

const { encodeReply } = require("react-server-dom-webpack/client.browser");

require(path.resolve(process.argv[2]));

async function encode([id, args]) {
  const body = await encodeReply(args);
  if (typeof body === "string") {
    return { id, body };
  }
  const form = [];
  for (const [key, value] of body.entries()) {
    if (typeof value !== "string") {
      throw new Error(`${id}: unexpected Blob entry ${key}`);
    }
    form.push([key, value]);
  }
  return { id, form };
}

Promise.all(globalThis.__wireCalls.map(encode)).then(
  (replies) => process.stdout.write(JSON.stringify(replies, null, 1) + "\n"),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
