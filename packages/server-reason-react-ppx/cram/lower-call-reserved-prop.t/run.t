
  $ ../ppx.sh --output re input.re
  React.createElementWithKey(
    ~key=None,
    "input",
    Stdlib.List.filter_map(
      Stdlib.Fun.id,
      [
        Some(
          [@implicit_arity] React.JSX.String("type", "type", "text": string),
        ),
      ],
    ),
    [],
  );
