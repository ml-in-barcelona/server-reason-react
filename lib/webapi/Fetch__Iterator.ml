module Next = struct
  type 'a t

  let done_ _ = None
  let value _ = None
end

type 'a t

let next t = t

let rec forEach ~f t =
  let item = next t in
  match Next.(done_ item, value item) with
  | Some true, Some value -> f value
  | Some true, None -> ()
  | (Some false | None), Some value ->
      f value;
      forEach ~f t
  | (Some false | None), None -> forEach ~f t
