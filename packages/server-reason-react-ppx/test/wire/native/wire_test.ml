let force promise =
  match Lwt.state promise with
  | Lwt.Return value -> Ok value
  | Lwt.Fail exn -> Error (Printexc.to_string exn)
  | Lwt.Sleep -> Error "the server function did not resolve"

let form_data entries =
  let form = Js.FormData.make () in
  List.iter
    (function
      | `List [ `String key; `String value ] -> Js.FormData.append form key (`String value)
      | entry -> failwith ("invalid form entry " ^ Yojson.Basic.to_string entry))
    entries;
  form

let call reply =
  let open Yojson.Basic.Util in
  let id = reply |> member "id" |> to_string in
  let result =
    match (FunctionReferences.get id, reply |> member "body", reply |> member "form") with
    | None, _, _ -> Error "not registered on the server"
    | Some (ReactServerDOM.Body handler), `String body, _ -> (
        match ReactServerDOM.decodeReply body with
        | Ok args -> force (try handler args with exn -> Lwt.fail exn)
        | Error message -> Error message)
    | Some (ReactServerDOM.FormData handler), _, `List entries -> (
        match ReactServerDOM.decodeFormDataReply (form_data entries) with
        | Ok (args, form) -> force (try handler args form with exn -> Lwt.fail exn)
        | Error message -> Error message)
    | Some _, _, _ -> Error "the handler kind does not match the encoded body"
  in
  match result with
  | Ok (React.Model.Json (`Bool true)) -> Ok id
  | Ok _ -> Error (id ^ ": the server decoded a different value")
  | Error message -> Error (id ^ ": " ^ message)

let () =
  ignore WireFunctions.sendString.id;
  let replies = Yojson.Basic.from_file Sys.argv.(1) |> Yojson.Basic.Util.to_list in
  let results = List.map call replies in
  let reply_ids = List.map (fun reply -> Yojson.Basic.Util.(reply |> member "id" |> to_string)) replies in
  List.iter (function Ok _ -> () | Error message -> print_endline ("FAIL " ^ message)) results;
  let missing =
    Hashtbl.fold (fun id _ acc -> if List.mem id reply_ids then acc else id :: acc) FunctionReferences.registry []
  in
  List.iter (fun id -> print_endline ("FAIL " ^ id ^ ": no client call reached it")) missing;
  if List.exists Result.is_error results || missing <> [] then exit 1
