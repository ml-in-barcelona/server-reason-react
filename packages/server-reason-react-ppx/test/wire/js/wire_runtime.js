exports.createServerReference = (id) => (...args) => {
  globalThis.__wireCalls.push([id, args]);
  return Promise.resolve(true);
};
