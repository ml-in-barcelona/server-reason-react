type ('a, 'id) eq = ('a, 'id) Belt.Id.eq
type ('a, 'id) hash = ('a, 'id) Belt.Id.hash
type ('a, 'id) id = ('a, 'id) Belt.Id.hashable

module Example = struct
  include (
    struct
      type foo = { name : string; age : int }

      let foo : name:string -> age:int -> foo = fun ~name ~age -> { name; age }
      let name : foo -> string = fun o -> o.name
      let age : foo -> int = fun o -> o.age
    end :
      sig
        type foo

        val foo : name:string -> age:int -> foo
        val name : foo -> string
        val age : foo -> int
      end)
end

let tony = Example.foo ~name:"Tony" ~age:27
let _ = print_endline (Example.name tony)
let aa : int Js.undefined array = Belt.Array.makeUninitialized 1
let _ = print_endline @@ "size: " ^ string_of_int (Belt.Array.length aa)

let _ =
  Belt.Array.forEachU aa (fun x ->
      match Js.Undefined.toOption x with
      | None -> print_endline "YUP"
      | Some x -> assert false)

let aa = Belt.Array.mapWithIndex aa (fun i _ -> i)
let aaa = Belt.List.concat [ 1.0; 2.0 ] [ 3.0; 4.0 ]

let _ =
  Belt.List.forEach aaa (fun x ->
      print_endline @@ "Number: " ^ string_of_float x)

module TestingMore = struct
  include (
    struct
      type t = { name2 : string option; [@bs.optional] age2 : int }

      let t : ?name2:string -> age2:int -> unit -> t =
       fun ?name2 ~age2 () -> { name2; age2 }

      let name2 : t -> string option = fun o -> o.name2
      let age2 : t -> int = fun o -> o.age2
    end :
      sig
        type t

        val t : ?name2:string -> age2:int -> unit -> t
        val name2 : t -> string option
        val age2 : t -> int
      end)
end

let aaaaa = TestingMore.t ~age2:10 ()

let () =
  let ten = Belt.Int.fromString "10" in
  match ten with
  | Some t -> print_endline (Belt.Int.toString t)
  | None -> print_endline "waaaa"

let () =
  let (some10 : int option) = Belt.Option.keep (Some 10) (fun x -> x > 5) in
  (match some10 with
  | Some t -> print_endline (string_of_int t)
  | None -> print_endline "error");

  let (none : int option) = Belt.Option.keep (Some 4) (fun x -> x > 5) in
  (match none with
  | Some _ -> print_endline "error"
  | None -> print_endline "green");

  let (none : int option) = Belt.Option.keep None (fun x -> x > 5) in
  match none with
  | Some _ -> print_endline "error"
  | None -> print_endline "green"

let () =
  let ten = Belt.Int.fromString "10" in
  match ten with
  | Some t -> print_endline (Belt.Int.toString t)
  | None -> print_endline "waaaa"

let print_array arr =
  print_string "[";
  print_string (Belt.Array.getUnsafe arr 0);
  Belt.Array.forEach (Belt.Array.sliceToEnd arr 1) (fun x ->
      print_string (", " ^ x));
  print_string "]\n"

let () =
  print_endline "\nBelt.Array";
  let arr = Belt.Array.makeUninitializedUnsafe 5 "lola" in
  print_array arr;
  let newa = Belt.Array.truncateToLengthUnsafe arr 3 in
  print_array newa
