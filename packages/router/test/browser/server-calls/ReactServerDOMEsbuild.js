const unused = () => {
  throw new Error("the server call test does not decode Flight");
};
module.exports = {
  createFromReadableStream: () => Promise.resolve(null),
  createFromFetch: unused,
  createServerReference: unused,
  encodeReply: (args) => Promise.resolve(JSON.stringify(args)),
};
