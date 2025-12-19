/* Simple classname utility for benchmarks */
let make = cns =>
  cns |> List.filter(x => x != "") |> String.concat(" ") |> String.trim;

let ifTrue = (cn, x) => x ? cn : "";
