  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let f1 : int -> int = fun x -> x + 1
  let f2 : int -> int -> int = fun a -> fun b -> a + b
  let f3 : int -> b:int -> c:int -> int = fun a -> fun ~b -> fun ~c -> a + b + c
  let f4 : int -> int -> int = fun a -> fun b -> a + b
  let f5 : int -> int -> int -> int = fun a -> fun b -> fun c -> a + b + c
  
  let () =
    let x : int option = Some 1 in
    match x with Some 1 -> assert true | _ -> assert false
  
  let () =
    let x : int option option = Some (Some 1) in
    match x with Some (Some 1) -> assert true | _ -> assert false
  
  let x : int = (fun (a, b) -> a + b) (1, 2)
  
  let () =
    let f : int -> int = fun x -> x + 1 in
    let x : int * int * int = (f, f, f) 1 in
    match x with 2, 2, 2 -> assert true | _ -> assert false
  
  let () =
    let f : int -> a:int -> b:int -> int =
     fun x -> fun ~a -> fun ~b -> x + a + b
    in
    let x : int * int * int = (f ~a:2 ~b:3, f ~a:2 ~b:3, f ~a:2 ~b:3) 1 in
    match x with 6, 6, 6 -> assert true | _ -> assert false
  
  let () =
    let x : int option * int option * int option = (Some, Some, Some) 1 in
    match x with Some 1, Some 1, Some 1 -> assert true | _ -> assert false
  
  let () =
    let x =
      ((fun (a, b) -> a + b), (fun (a, b) -> a + b), fun (a, b) -> a + b) (1, 2)
    in
    match x with 3, 3, 3 -> assert true | _ -> assert false
  
  let fn1 ?foo () = 1 + match foo with Some x -> x | None -> 2
  
  let fn2 ?bar x =
    let bar = match bar with Some bar -> bar | None -> 4 in
    2 + bar + x
  
  type field = { send : int -> int }
  
  let self = { send = (fun a -> a + 1) }
  let adder a b = a + b
  let addFive = adder 5
  let ten1 = addFive 5
  let ten2 = adder 5 5
  
  let _ =
    (let open Lwt in
     bind (fun () ->
         print_endline "foo";
         return ()))
      (Lwt_js.sleep 1.)
