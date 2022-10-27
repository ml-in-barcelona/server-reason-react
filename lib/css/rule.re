type t =
  | Declaration(string, string)
  | Selector(string, array(t))
  | Pseudoclass(string, array(t))
  | PseudoclassParam(string, string, array(t));

let rec rule_to_string = (accumulator: string, rule) => {
  let next_rule = switch (rule) {
  | Declaration(name, value) =>
    Printf.sprintf("%s: %s", name, value)
  | Selector(name, rules) =>
    Printf.sprintf(".%s { %s }", name, to_string(rules))
  | Pseudoclass(name, rules) =>
    Printf.sprintf(":%s { %s }", name, to_string(rules))
  | PseudoclassParam(name, param, rules) =>
    Printf.sprintf(":%s ( %s ) %s", name, param, to_string(rules))
  };
  accumulator ++ next_rule ++ "; ";
}

and to_string = (rules: array(t)) =>
  rules |> Array.fold_left(rule_to_string, "");
