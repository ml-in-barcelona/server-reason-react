type t = int

external first : (_[@mel.as "x"]) -> int -> unit = "first" [@@mel.send]
external middle : t -> (_[@mel.as 3]) -> int -> unit = "middle" [@@mel.send]

let shared_first n : unit = first n
let shared_middle obj n : unit = middle obj n

let expect_melange_only name fn =
  match fn () with
  | () -> failwith (name ^ ": expected Runtime.Impossible_in_ssr")
  | exception Runtime.Impossible_in_ssr _ -> ()

let () =
  expect_melange_only "first" (fun () -> shared_first 1);
  expect_melange_only "middle" (fun () -> shared_middle 0 1)
