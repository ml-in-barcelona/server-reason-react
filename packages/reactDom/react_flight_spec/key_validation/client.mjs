import React from "react";

export default function Client({ children, items, data, promise, other }) {
  const [count, setCount] = React.useState(0);
  const value = promise ? React.use(promise) : (items ?? data?.items ?? children);
  if (other && other !== promise) {
    throw new Error("Shared native promise lost its identity");
  }
  React.useEffect(() => {
    window.flightTest.clientCommits++;
  }, []);
  return React.createElement(
    "section",
    { "data-client": "true" },
    value,
    React.createElement("button", { onClick: () => setCount(count + 1) }, `count:${count}`),
  );
}
