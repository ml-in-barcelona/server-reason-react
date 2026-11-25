(* Each property compares the router with a reference model written from the path syntax in
   documentation/router.mld, so a shared bug in the parser and the matcher cannot hide. *)

let count = match Sys.getenv_opt "ROUTER_PROPERTY_COUNT" with Some value -> int_of_string value | None -> 10000
let seed = match Sys.getenv_opt "ROUTER_PROPERTY_SEED" with Some value -> int_of_string value | None -> 20261124

let property name ~show gen check =
  Alcotest.test_case name `Quick (fun () ->
      for index = 0 to count - 1 do
        let state = Random.State.make [| seed; index; Hashtbl.hash name |] in
        let case = gen state in
        match check case with
        | () -> ()
        | exception Failure message ->
            Alcotest.failf "case %d (ROUTER_PROPERTY_SEED=%d): %s\n%s" index seed message (show case)
      done)

let failf format = Printf.ksprintf failwith format
let pick state values = values.(Random.State.int state (Array.length values))
let chance state percent = Random.State.int state 100 < percent
let between state low high = low + Random.State.int state (high - low + 1)
let list state ~low ~high item = List.init (between state low high) item
let quote = Printf.sprintf "%S"
let show_list show values = "[" ^ String.concat "; " (List.map show values) ^ "]"

type segment = Static of string | Parameter of string * string * bool | CatchAll of string * bool

let print_segment = function
  | Static value -> value
  | Parameter (name, type_name, optional) -> ":" ^ name ^ (if optional then "?" else "") ^ "<" ^ type_name ^ ">"
  | CatchAll (name, optional) -> ":" ^ name ^ (if optional then "?" else "") ^ "<string...>"

let print segments = "/" ^ String.concat "/" (List.map print_segment segments)
let is_lower character = character >= 'a' && character <= 'z'
let is_upper character = character >= 'A' && character <= 'Z'
let is_digit character = character >= '0' && character <= '9'
let is_alnum character = is_lower character || is_upper character || is_digit character

let rest_of_identifier value =
  String.for_all (fun character -> is_alnum character || character = '_' || character = '\'') value

let reference_label value =
  value <> "" && value <> "_" && (is_lower value.[0] || value.[0] = '_') && rest_of_identifier value

let reference_module value = value <> "" && is_upper value.[0] && rest_of_identifier value

let reference_type value =
  match List.rev (String.split_on_char '.' value) with
  | [ ("int" | "string" | "bool") ] -> true
  | "t" :: (_ :: _ as modules) -> List.for_all reference_module modules
  | _ -> false

let reference_static value =
  value <> "" && value <> "." && value <> ".."
  && value.[0] <> ':'
  && String.for_all
       (fun character ->
         Char.code character >= 0x80 || is_alnum character || String.contains "-._~!$&'()*+,;=:@" character)
       value

let reference_segment segment =
  if reference_static segment then Some (Static segment)
  else if segment = "" || segment.[0] <> ':' then None
  else
    match String.index_opt segment '<' with
    | None -> None
    | Some opening ->
        let length = String.length segment in
        if segment.[length - 1] <> '>' then None
        else
          let label = String.sub segment 1 (opening - 1) in
          let type_name = String.sub segment (opening + 1) (length - opening - 2) in
          let optional = String.ends_with ~suffix:"?" label in
          let name = if optional then String.sub label 0 (String.length label - 1) else label in
          if not (reference_label name) then None
          else if type_name = "string..." then Some (CatchAll (name, optional))
          else if reference_type type_name then Some (Parameter (name, type_name, optional))
          else None

let reference_parse ~template path =
  if path = "" || path = "/" then Some []
  else if path.[0] <> '/' then None
  else
    let segments = List.tl (String.split_on_char '/' path) |> List.map reference_segment in
    if List.mem None segments then None
    else
      let segments = List.filter_map Fun.id segments in
      let rec well_formed = function
        | [] -> true
        | (Parameter (_, _, true) | CatchAll (_, true)) :: _ when not template -> false
        | [ CatchAll _ ] -> true
        | CatchAll _ :: _ -> false
        | _ :: rest -> well_formed rest
      in
      if well_formed segments then Some segments else None

let optional_names segments =
  List.filter_map
    (function
      | Parameter (name, _, true) | CatchAll (name, true) -> Some name | Static _ | Parameter _ | CatchAll _ -> None)
    segments

let rec reference_shapes = function
  | [] -> [ [] ]
  | segment :: rest ->
      let rest = reference_shapes rest in
      let present segment = List.map (fun shape -> segment :: shape) rest in
      begin match segment with
      | Static _ -> present segment
      | Parameter (name, type_name, optional) ->
          present (Parameter (name, type_name, false)) @ if optional then rest else []
      | CatchAll (name, optional) -> present (CatchAll (name, false)) @ if optional then rest else []
      end

let hex_value character =
  match character with
  | '0' .. '9' -> Some (Char.code character - 48)
  | 'a' .. 'f' -> Some (Char.code character - 87)
  | 'A' .. 'F' -> Some (Char.code character - 55)
  | _ -> None

(* The request side of the documented contract: split, then decode each segment, rejecting empty
   segments, malformed escapes, encoded slashes, dot segments, control characters and bad UTF-8. *)
let reference_decode_segment raw =
  let buffer = Buffer.create (String.length raw) in
  let rec loop index =
    if index >= String.length raw then Some (Buffer.contents buffer)
    else if raw.[index] <> '%' then (
      Buffer.add_char buffer raw.[index];
      loop (index + 1))
    else if index + 2 >= String.length raw then None
    else
      match (hex_value raw.[index + 1], hex_value raw.[index + 2]) with
      | Some high, Some low when (high * 16) + low <> Char.code '/' ->
          Buffer.add_char buffer (Char.chr ((high * 16) + low));
          loop (index + 3)
      | _ -> None
  in
  match loop 0 with
  | Some decoded
    when decoded <> "" && decoded <> "." && decoded <> ".." && String.is_valid_utf_8 decoded
         && String.for_all (fun character -> Char.code character >= 0x20 && Char.code character <> 0x7f) decoded ->
      Some decoded
  | Some _ | None -> None

let reference_decode pathname =
  if pathname = "/" then Some []
  else if pathname = "" || pathname.[0] <> '/' then None
  else
    let decoded = List.tl (String.split_on_char '/' pathname) |> List.map reference_decode_segment in
    if List.mem None decoded then None else Some (List.filter_map Fun.id decoded)

let reference_match pattern segments =
  let rec loop captured pattern segments =
    match (pattern, segments) with
    | [], [] -> Some (List.rev captured)
    | [ CatchAll (name, _) ], _ :: _ -> Some (List.rev ((name, String.concat "/" segments) :: captured))
    | Static value :: pattern, segment :: segments when value = segment -> loop captured pattern segments
    | Parameter (name, _, _) :: pattern, segment :: segments -> loop ((name, segment) :: captured) pattern segments
    | _ -> None
  in
  loop [] pattern segments

let reference_specificity pattern =
  let statics = List.length (List.filter (function Static _ -> true | _ -> false) pattern) in
  let finite = if List.exists (function CatchAll _ -> true | _ -> false) pattern then 0 else 1 in
  (statics, finite)

(* A pathname both concrete patterns match, when one exists. *)
let witness left right =
  let fill = List.map (function Static value -> value | Parameter _ | CatchAll _ -> "z") in
  let rec loop left right =
    match (left, right) with
    | [], [] -> Some []
    | [ CatchAll _ ], (_ :: _ as rest) | (_ :: _ as rest), [ CatchAll _ ] -> Some (fill rest)
    | Static a :: left, Static b :: right -> if a = b then Option.map (List.cons a) (loop left right) else None
    | Static value :: left, _ :: right | _ :: left, Static value :: right ->
        Option.map (List.cons value) (loop left right)
    | _ :: left, _ :: right -> Option.map (List.cons "z") (loop left right)
    | [], _ :: _ | _ :: _, [] -> None
  in
  loop left right

let labels = [| "a"; "id"; "_x"; "x'"; "userId"; "n2"; "type"; "rest" |]
let types = [| "int"; "string"; "bool"; "Foo.t"; "A.B_2.t" |]

let static_characters =
  [|
    "a";
    "b";
    "Z";
    "0";
    "-";
    ".";
    "_";
    "~";
    "!";
    "$";
    "&";
    "'";
    "(";
    "*";
    "+";
    ",";
    ";";
    "=";
    ":";
    "@";
    "\xc3\xa9";
    "\xe6\x9d\xb1";
  |]

let rec gen_static state =
  let value = String.concat "" (list state ~low:1 ~high:4 (fun _ -> pick state static_characters)) in
  if reference_static value then value else gen_static state

let gen_template state =
  let length = between state 0 5 in
  List.init length (fun index ->
      let name = labels.(index) in
      let optional = chance state 25 in
      if index = length - 1 && chance state 20 then CatchAll (name, optional)
      else if chance state 50 then Static (gen_static state)
      else Parameter (name, pick state types, optional))

let fuzz_tokens =
  [|
    "/";
    "/";
    "/";
    ":";
    "<";
    ">";
    "?";
    ".";
    "..";
    "%";
    "%20";
    "a";
    "Z";
    "_";
    "'";
    "-";
    "int";
    "string";
    "bool";
    "string...";
    "Foo";
    ".t";
    "\xc3\xa9";
    "\xff";
    " ";
    "#";
    "+";
    "@";
    "~";
    "1";
    ":id<int>";
    ":p?<string>";
    ":r<string...>";
    ":r?<string...>";
    "<Foo.t>";
    "Foo.t>";
    ":_<int>";
  |]

let gen_fuzz_path state =
  let body = String.concat "" (list state ~low:0 ~high:8 (fun _ -> pick state fuzz_tokens)) in
  if chance state 85 then "/" ^ body else body

(* Small alphabets make overlapping route sets likely. *)
let gen_segments state ~index ~offset ~length =
  List.init length (fun position ->
      if position = length - 1 && chance state 20 then CatchAll ("r", false)
      else if chance state 55 then Static (pick state [| "a"; "b"; "\xc3\xa9" |])
      else Parameter (Printf.sprintf "p%d_%d" index (offset + position), pick state [| "int"; "string" |], false))

let gen_route state index = gen_segments state ~index ~offset:0 ~length:(between state 0 3)

(* Extending earlier routes puts routes of different depths on one trie path, where a shallow
   route must not beat a better match found in a sibling branch. *)
let gen_routes state =
  let size = between state 1 6 in
  let rec build routes index =
    if index = size then List.rev routes
    else
      let parents =
        List.filter (fun route -> not (List.exists (function CatchAll _ -> true | _ -> false) route)) routes
      in
      let route =
        if parents <> [] && chance state 50 then
          let parent = List.nth parents (Random.State.int state (List.length parents)) in
          parent @ gen_segments state ~index ~offset:(List.length parent) ~length:(between state 1 2)
        else gen_route state index
      in
      build (route :: routes) (index + 1)
  in
  build [] 0

let path_segments =
  [|
    "a";
    "b";
    "c";
    "%61";
    "\xc3\xa9";
    "%C3%A9";
    "%c3%a9";
    "%2F";
    "%2f";
    "..";
    ".";
    "%2e";
    "";
    "%";
    "%4";
    "%FF";
    "%00";
    "a+b";
    "a%20b";
  |]

let gen_pathname state =
  match between state 0 9 with
  | 0 -> pick state [| ""; "/"; "//"; "a"; "/a/" |]
  | _ -> "/" ^ String.concat "/" (list state ~low:0 ~high:4 (fun _ -> pick state path_segments))

let value_characters =
  [|
    "a";
    "Z";
    "1";
    " ";
    "%";
    "+";
    "?";
    "#";
    "&";
    "=";
    ":";
    "@";
    "'";
    ".";
    "-";
    "~";
    "\xc3\xa9";
    "\xf0\x9f\x98\x80";
    "%2F";
  |]

let rec gen_value state =
  let value = String.concat "" (list state ~low:1 ~high:5 (fun _ -> pick state value_characters)) in
  if value = "." || value = ".." then gen_value state else value

let parse_agrees_with_reference =
  property "parser accepts exactly the documented grammar" ~show:quote gen_fuzz_path (fun path ->
      List.iter
        (fun template ->
          let parse = if template then Pattern.parseTemplate else Pattern.parse in
          match (parse path, reference_parse ~template path) with
          | Ok pattern, Some segments ->
              let printed = print segments in
              if Pattern.toString pattern <> printed then
                failf "printed %S, expected %S" (Pattern.toString pattern) printed;
              if Pattern.optional pattern <> optional_names segments then failf "optional names differ";
              if path <> "" && printed <> path then failf "toString is not the input"
          | Error _, None -> ()
          | Ok _, None -> failf "accepted (template %b)" template
          | Error _, Some _ -> failf "rejected (template %b)" template)
        [ false; true ])

let generated_templates_round_trip =
  property "generated templates print, parse and expand to their shapes"
    ~show:(fun segments -> print segments)
    gen_template
    (fun segments ->
      let path = print segments in
      match (Pattern.parseTemplate path, reference_parse ~template:true path) with
      | Error _, Some _ -> failf "rejected valid template"
      | Ok _, None -> failf "accepted invalid template"
      | Error _, None -> ()
      | Ok pattern, Some segments -> (
          if Pattern.toString pattern <> path then failf "printed %S" (Pattern.toString pattern);
          (match Pattern.parseTemplate (Pattern.toString pattern) with
          | Ok again when Pattern.toString again = path -> ()
          | Ok _ | Error _ -> failf "toString does not re-parse");
          let shapes = List.map Pattern.toString (Pattern.shapes pattern) in
          let expected = List.map print (reference_shapes segments) in
          if shapes <> expected then failf "shapes %s, expected %s" (show_list quote shapes) (show_list quote expected);
          if List.length shapes <> 1 lsl List.length (optional_names segments) then failf "shape count";
          List.iter
            (fun shape ->
              match Pattern.parse shape with Ok _ -> () | Error _ -> failf "shape %S is not concrete" shape)
            shapes;
          match Pattern.parse path with
          | Ok _ when optional_names segments <> [] -> failf "parse accepted optional segments"
          | Error _ when optional_names segments = [] -> failf "parse rejected a concrete path"
          | Ok _ | Error _ -> ()))

let show_routes routes = show_list (fun route -> quote (print route)) routes
let route_id index = "r" ^ string_of_int index

let routes_registry routes =
  RouterServer.Registry.make
    (List.mapi (fun index route -> RouterServer.Route.make ~id:(route_id index) ~path:(print route)) routes)

let show_registry_case (routes, pathnames) = show_routes routes ^ "\npathnames " ^ show_list quote pathnames

let registry_agrees_with_reference =
  property "registry matching agrees with the reference matcher" ~show:show_registry_case
    (fun state ->
      let routes = gen_routes state in
      let pathnames = list state ~low:8 ~high:8 (fun _ -> gen_pathname state) in
      let witnesses =
        List.concat_map
          (fun left ->
            List.filter_map
              (fun right -> Option.map (fun path -> "/" ^ String.concat "/" path) (witness left right))
              routes)
          routes
      in
      (routes, pathnames @ witnesses))
    (fun (routes, pathnames) ->
      let indexed = List.mapi (fun index route -> (route_id index, route)) routes in
      match routes_registry routes with
      | Error (DuplicateId _) -> failf "generated duplicate ids"
      | Error (DuplicatePath path) ->
          if List.length (List.filter (fun route -> print route = path) routes) < 2 then
            failf "spurious duplicate %S" path
      | Error (AmbiguousPattern (left, right)) -> (
          let find path = List.find (fun route -> print route = path) routes in
          let left = find left and right = find right in
          if reference_specificity left <> reference_specificity right then failf "ambiguous with different specificity";
          match witness left right with
          | Some path when Option.is_some (reference_match left path) && Option.is_some (reference_match right path) ->
              ()
          | Some _ | None -> failf "no pathname matches both %S and %S" (print left) (print right))
      | Ok registry ->
          List.iter
            (fun pathname ->
              let found = RouterServer.Match.find registry ~pathname in
              match (reference_decode pathname, found) with
              | None, Error _ -> ()
              | None, Ok _ -> failf "accepted pathname %S" pathname
              | Some _, Error _ -> failf "rejected pathname %S" pathname
              | Some segments, Ok found -> (
                  let candidates =
                    List.filter_map
                      (fun (id, route) ->
                        Option.map
                          (fun captured -> (reference_specificity route, id, captured))
                          (reference_match route segments))
                      indexed
                    |> List.sort (fun (left, _, _) (right, _, _) -> compare right left)
                  in
                  match (candidates, found) with
                  | [], None -> ()
                  | [], Some matched -> failf "%S matched %s" pathname (RouterServer.Route.id matched.route)
                  | (_, id, _) :: _, None -> failf "%S matched nothing, expected %s" pathname id
                  | (best, _, _) :: (next, other, _) :: _, _ when best = next ->
                      failf "registry accepted routes that tie on %S (%s)" pathname other
                  | (_, id, captured) :: _, Some matched ->
                      if RouterServer.Route.id matched.route <> id then
                        failf "%S matched %s, expected %s" pathname (RouterServer.Route.id matched.route) id;
                      if matched.parameters <> captured then failf "%S captured different parameters" pathname))
            pathnames)

let show_render_case (segments, parameters) =
  print segments ^ "\nparameters " ^ show_list (fun (name, value) -> name ^ "=" ^ quote value) parameters

let href_round_trips =
  property "generated hrefs match their own route with the same parameters" ~show:show_render_case
    (fun state ->
      let segments = gen_template state in
      let parameters =
        List.filter_map
          (function
            | Static _ -> None
            | (Parameter (_, _, true) | CatchAll (_, true)) when chance state 40 -> None
            | Parameter (name, _, _) -> Some (name, gen_value state)
            | CatchAll (name, _) -> Some (name, String.concat "/" (list state ~low:1 ~high:3 (fun _ -> gen_value state))))
          segments
      in
      (segments, parameters))
    (fun (segments, parameters) ->
      let path = print segments in
      match Pattern.parseTemplate path with
      | Error _ -> failf "rejected a generated template"
      | Ok pattern -> (
          let href =
            RouterRuntime.href
              (RouterRuntime.destinationFromPattern ~pattern:(RouterRuntime.pattern path) ~parameters ~search:[])
          in
          if not (Pattern.matchesPath pattern href) then failf "matchesPath rejected %S" href;
          let shapes = Pattern.shapes pattern in
          let routes =
            List.mapi
              (fun index shape -> RouterServer.Route.make ~id:(route_id index) ~path:(Pattern.toString shape))
              shapes
          in
          (* Shapes that two pathnames share make the template invalid; the generator reports it. *)
          match RouterServer.Registry.make routes with
          | Error _ -> ()
          | Ok registry -> (
              let names shape =
                List.sort compare
                  (List.map (fun (parameter : Pattern.parameter) -> parameter.name) (Pattern.parameters shape))
              in
              let given = List.sort compare (List.map fst parameters) in
              let expected = List.filter (fun shape -> names shape = given) shapes in
              match (RouterServer.Match.find registry ~pathname:href, expected) with
              | Ok (Some matched), [ shape ] ->
                  if RouterServer.Route.path matched.route <> Pattern.toString shape then
                    failf "%S matched %S" href (RouterServer.Route.path matched.route);
                  let sort = List.sort compare in
                  if sort matched.parameters <> sort parameters then failf "%S decoded different parameters" href
              | Ok (Some _), _ -> failf "no unique expected shape"
              | Ok None, _ -> failf "%S matched nothing" href
              | Error _, _ -> failf "%S was rejected" href)))

let bytes = Array.init 256 (fun code -> String.make 1 (Char.chr code))

let segment_encoding_round_trips =
  property "encoded segments decode to their bytes"
    ~show:(fun value -> quote value)
    (fun state ->
      String.concat ""
        (list state ~low:0 ~high:6 (fun _ -> if chance state 50 then pick state bytes else pick state value_characters)))
    (fun value ->
      let encoded = Pattern.encodeStaticSegment value in
      let decode ~plus = Url.decodeEscaped ~plus encoded ~start:0 ~stop:(String.length encoded) ~first:0 in
      if decode ~plus:false <> Ok value then failf "decoded differently";
      if decode ~plus:true <> Ok value then failf "plus changed it";
      if String.contains encoded '/' then failf "left a slash unescaped";
      let valid = reference_decode_segment encoded <> None in
      match
        RouterRuntime.destinationFromPattern ~pattern:(RouterRuntime.pattern "/:v<string>")
          ~parameters:[ ("v", value) ]
          ~search:[]
      with
      | destination ->
          if not valid then failf "rendered an invalid segment";
          if RouterRuntime.href destination <> "/" ^ encoded then failf "href %S" (RouterRuntime.href destination)
      | exception Invalid_argument _ -> if valid then failf "refused a valid segment")

let show_pair (path, pathname) = quote path ^ " " ^ quote pathname

let matches_path_agrees_with_server =
  property "matchesPath agrees with the server matcher" ~show:show_pair
    (fun state -> (print (gen_route state 0), gen_pathname state))
    (fun (path, pathname) ->
      let pattern = match Pattern.parse path with Ok pattern -> pattern | Error _ -> failf "invalid route" in
      let registry = RouterServer.Registry.makeExn [ RouterServer.Route.make ~id:"r" ~path ] in
      let server =
        match RouterServer.Match.find registry ~pathname with Ok (Some _) -> true | Ok None | Error _ -> false
      in
      if Pattern.matchesPath pattern pathname <> server then
        failf "matchesPath %b, server %b" (Pattern.matchesPath pattern pathname) server)

let base_paths = [| "/"; "/app"; "/a%20b"; "/caf%C3%A9"; "/app/v1" |]

let base_path_agrees_with_server =
  property "base path stripping agrees with matchesPath"
    ~show:(fun (basePath, pathname) -> quote basePath ^ " " ^ quote pathname)
    (fun state ->
      let basePath = pick state base_paths in
      let prefix = pick state [| basePath; "/app"; "/APP"; "/a b"; "/caf%c3%a9"; "/caf\xc3\xa9"; "/apple"; "" |] in
      let prefix = if prefix = "/" then "" else prefix in
      (basePath, prefix ^ gen_pathname state))
    (fun (basePath, pathname) ->
      let pattern = match Pattern.parse "/:x<string>" with Ok pattern -> pattern | Error _ -> assert false in
      let root = match Pattern.parse "/" with Ok pattern -> pattern | Error _ -> assert false in
      let registry =
        RouterServer.Registry.makeExn
          [ RouterServer.Route.make ~id:"x" ~path:"/:x<string>"; RouterServer.Route.make ~id:"root" ~path:"/" ]
      in
      (* ServerEngine applies the trailing-slash policy before it strips the base path. *)
      let canonical = RouterServer.Path.stripTrailingSlashes pathname = None in
      let server =
        match if canonical then RouterServer.Path.stripBasePath ~basePath pathname else None with
        | None -> None
        | Some rest -> (
            match RouterServer.Match.find registry ~pathname:rest with
            | Ok (Some matched) -> Some (RouterServer.Route.id matched.route)
            | Ok None | Error _ -> None)
      in
      let client =
        if not canonical then None
        else if Pattern.matchesPath ~basePath pattern pathname then Some "x"
        else if Pattern.matchesPath ~basePath root pathname then Some "root"
        else None
      in
      if server <> client then
        failf "server %s, matchesPath %s" (Option.value server ~default:"none") (Option.value client ~default:"none"))

let relationship_is_symmetric =
  property "relationship is symmetric"
    ~show:(fun (left, right) -> quote (print left) ^ " " ^ quote (print right))
    (fun state -> (gen_route state 0, gen_route state 0))
    (fun (left, right) ->
      let parse route = match Pattern.parse (print route) with Ok pattern -> pattern | Error _ -> failf "invalid" in
      if Pattern.relationship (parse left) (parse right) <> Pattern.relationship (parse right) (parse left) then
        failf "asymmetric")

let () =
  Alcotest.run "router path properties"
    [
      ("grammar", [ parse_agrees_with_reference; generated_templates_round_trip ]);
      ( "matching",
        [
          registry_agrees_with_reference;
          matches_path_agrees_with_server;
          base_path_agrees_with_server;
          relationship_is_symmetric;
        ] );
      ("encoding", [ href_round_trips; segment_encoding_round_trips ]);
    ]
