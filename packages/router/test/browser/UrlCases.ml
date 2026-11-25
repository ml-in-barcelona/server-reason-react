(* One deterministic case generator for native and the browser. Arithmetic
   stays within 31 bits so both platforms draw the same sequence. *)

type platform = {
  text : string -> string;
  encodeSearch : (string * string list) list -> string;
  parseSearch : string -> (string * string list) list option;
  encodeSegment : string -> string;
  decodeSegment : string -> string option;
}

let seed = 20261124
let count = 2000

type random = { mutable state : int }

let next random =
  random.state <- ((random.state * 1103515245) + 12345) land 0x7fffffff;
  random.state lsr 8

let below random bound = next random mod bound

let pools =
  [|
    [| 0x61; 0x62; 0x7a; 0x41; 0x5a; 0x30; 0x39 |];
    [| 0x2d; 0x5f; 0x2e; 0x21; 0x7e; 0x2a; 0x27; 0x28; 0x29 |];
    [| 0x20; 0x25; 0x2b; 0x26; 0x3d; 0x23; 0x3f; 0x2f; 0x3b; 0x3a; 0x40; 0x24; 0x2c; 0x22; 0x3c |];
    [| 0xe9; 0xfc; 0xa0 |];
    [| 0x4e2d; 0x6771; 0x0301; 0x200d |];
    [| 0xe000; 0xff21; 0xfffd; 0xffff |];
    [| 0x1f600; 0x1f30d; 0x10000; 0x10ffff |];
  |]

let add_code_point buffer code =
  let add byte = Buffer.add_char buffer (Char.unsafe_chr byte) in
  if code < 0x80 then add code
  else if code < 0x800 then (
    add (0xc0 lor (code lsr 6));
    add (0x80 lor (code land 0x3f)))
  else if code < 0x10000 then (
    add (0xe0 lor (code lsr 12));
    add (0x80 lor ((code lsr 6) land 0x3f));
    add (0x80 lor (code land 0x3f)))
  else (
    add (0xf0 lor (code lsr 18));
    add (0x80 lor ((code lsr 12) land 0x3f));
    add (0x80 lor ((code lsr 6) land 0x3f));
    add (0x80 lor (code land 0x3f)))

let text_bytes random ~minimum ~maximum =
  let buffer = Buffer.create 16 in
  for _ = 1 to minimum + below random (maximum - minimum + 1) do
    let pool = pools.(below random (Array.length pools)) in
    add_code_point buffer pool.(below random (Array.length pool))
  done;
  Buffer.contents buffer

let query random =
  let rec keys count taken =
    if count = 0 then taken
    else
      let key = text_bytes random ~minimum:1 ~maximum:5 in
      if List.mem key taken then keys count taken else keys (count - 1) (key :: taken)
  in
  keys (below random 4) []
  |> List.map (fun key -> (key, List.init (1 + below random 3) (fun _ -> text_bytes random ~minimum:0 ~maximum:6)))

let raw_query random =
  let alphabet = "ab=&+%2F%%zZ09?#;%FF%C3%A9%E2%82" in
  String.init (below random 24) (fun _ -> alphabet.[below random (String.length alphabet)])

let valid_segment value =
  value <> "" && value <> "." && value <> ".."
  && String.for_all
       (fun character -> character <> '/' && Char.code character >= 0x20 && Char.code character <> 0x7f)
       value

(* Prints one line per encoding so the native and browser outputs can be
   compared byte for byte, and fails with the seed and case on a broken
   property. *)
let run platform print =
  let random = { state = seed } in
  let fail index property detail =
    failwith (Printf.sprintf "URL property %s failed: seed %d, case %d: %s" property seed index detail)
  in
  for index = 0 to count - 1 do
    let bytes = query random in
    let expected =
      List.sort (fun (left, _) (right, _) -> String.compare left right) bytes
      |> List.map (fun (key, values) -> (platform.text key, List.map platform.text values))
    in
    let encoded = platform.encodeSearch expected in
    print ("query " ^ encoded);
    (match platform.parseSearch encoded with
    | Some parsed when parsed = expected -> ()
    | Some _ -> fail index "parse after print" encoded
    | None -> fail index "parse after print" (encoded ^ " did not parse"));
    let segment = text_bytes random ~minimum:1 ~maximum:6 in
    if valid_segment segment then (
      let encoded = platform.encodeSegment (platform.text segment) in
      print ("segment " ^ encoded);
      if platform.decodeSegment encoded <> Some (platform.text segment) then
        fail index "segment decode after encode" encoded);
    let raw = raw_query random in
    match platform.parseSearch raw with
    | None -> print "raw none"
    | Some parsed ->
        let once = platform.encodeSearch parsed in
        print ("raw " ^ once);
        let twice =
          match platform.parseSearch once with
          | Some parsed -> platform.encodeSearch parsed
          | None -> fail index "print after parse is stable" (once ^ " did not parse")
        in
        if once <> twice then fail index "print after parse is stable" (raw ^ ": " ^ once ^ " then " ^ twice)
  done
