type t = string;

let parsed: ref(option(t)) = ref(None);

let parse = (value: string): result(t, string) => {
  parsed := Some(value);
  Ok(value);
};
let to_string = value => value;
let make = value => value;
let reset = () => parsed := None;
let parsed = () => parsed^;
