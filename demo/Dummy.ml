module Dummy = struct
  let make =
   fun [@warning "-16"] ~lola ->
    React.createElement "div"
      ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
      [ React.string lola ]
end

let make ?key () = Dummy.make ~lola:"flores" ()
