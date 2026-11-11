export function cx(classes) {
  return classes.filter((x) => x !== "").join(" ").trim();
}
