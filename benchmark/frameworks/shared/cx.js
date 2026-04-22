// Matches benchmark/scenarios/Cx.re exactly:
//   let make = cns => cns |> List.filter(x => x != "") |> String.concat(" ") |> String.trim;
export function cx(classes) {
  return classes.filter((x) => x !== "").join(" ").trim();
}
