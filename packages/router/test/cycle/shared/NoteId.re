type t = int;

let parse = value =>
  switch (int_of_string_opt(value)) {
  | Some(value) => Ok(value)
  | None => Error("expected an integer")
  };
let print = Int.to_string;
let make = value => value;
let toInt = value => value;
