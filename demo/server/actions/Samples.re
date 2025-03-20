open Ppx_deriving_json_runtime.Primitives;

[@deriving json]
type args = ServerActionFormData.formData;

[@deriving json]
type response = string;

let delayed_value = (~ms, value) => {
  let%lwt () = Lwt_unix.sleep(Int.to_float(ms) /. 1000.0);
  Lwt.return(value);
};

let formData = formData => {
  let (_, name) = Hashtbl.find(formData, "name") |> List.hd;
  let (_, lastName) = Hashtbl.find(formData, "lastName") |> List.hd;
  let (_, age) = Hashtbl.find(formData, "age") |> List.hd;

  let formData = {
    ServerActionFormData.name,
    lastName,
    age,
  };
  let response =
    Printf.sprintf("Hello %s %s, you are %s years old", name, lastName, age);

  Lwt.return(React.Json(`String(response)));
};

let simpleResponse = _ => {
  let response = React.Json(`String("Hello"));
  Lwt.return(response);
};

let complexResponse = _ => {
  let response =
    React.ValueList([
      React.Json(`String("Hello world")),
      React.Promise(
        delayed_value(~ms=5000, "Hello after 5 seconds"),
        res => React.Json(`String(res)),
      ),
    ]);
  Lwt.return(response);
};
