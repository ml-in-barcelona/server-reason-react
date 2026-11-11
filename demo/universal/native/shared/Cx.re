let make = cns =>
  cns->Belt.List.keep(x => x !== "") |> String.concat(" ") |> String.trim;
