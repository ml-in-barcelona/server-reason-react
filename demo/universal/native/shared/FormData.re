// TODO: Support other types.
type entryValue = [ | `String(string)];
type t = Hashtbl.t(string, entryValue);

let make: unit => t = () => Hashtbl.create(10);

let append: (t, string, entryValue) => unit =
  (formData, key, value) => {
    Hashtbl.add(formData, key, value);
  };

let get: (t, string) => entryValue =
  (formData, key) => {
    Hashtbl.find(formData, key);
  };
