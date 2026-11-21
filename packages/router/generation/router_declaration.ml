open Ppxlib

type parameter_kind = Segment | OptionalSegment | OptionalRest

type parameter = {
  name : string;
  presence : parameter_kind;
  typ : core_type;
  argument : core_type;
  parser : Longident.t;
  to_string : Longident.t;
  loc : Location.t;
}

type search_kind = Required | Optional | Default of expression | Many

type search = {
  name : string;
  key : string;
  typ : core_type;
  parser : Longident.t;
  to_string : Longident.t;
  kind : search_kind;
  shallow : bool;
  loc : Location.t;
}

type loader = { run : expression; result_label : string; loc : Location.t }

type attachments = {
  layout : expression option;
  loading : expression option;
  not_found : expression option;
  error : expression option;
  loader : loader option;
  metadata : expression option;
  headers : expression option;
}

type prefetch = Off | Intent | Viewport | Idle

type scope = {
  id : string;
  path : string;
  parameters : parameter list;
  search : search list;
  attachments : attachments;
  prefetch : prefetch option;
  loc : Location.t;
}

type leaf = { name : string; page : expression; scope : scope; loc : Location.t }
type redirect_leaf = { id : string; target : expression; permanent : bool; scope : scope; loc : Location.t }

type group = { scope : scope; children : node list }
and node = Group of group | Route of leaf | Redirect of redirect_leaf

type route = {
  name : string;
  page : expression;
  path : string;
  parameters : parameter list;
  search : search list;
  scopes : scope list;
  prefetch : prefetch;
  loc : Location.t;
}

type redirect = {
  id : string;
  target : expression;
  permanent : bool;
  path : string;
  parameters : parameter list;
  search : search list;
  loc : Location.t;
}

type endpoint = Page of route | RedirectTo of redirect
type trailing_slash = Redirect | Reject

type t = {
  base_path : string;
  trailing_slash : trailing_slash;
  intercept_links : bool option;
  view_transitions : bool option;
  page_cache_max_age : string option;
  error_status : expression option;
  invalid_search : expression option;
  context : core_type option;
  root : group;
  loc : Location.t;
}

let error ~loc format = Location.raise_errorf ~loc ("router: " ^^ format)

let longident_of_expression expression =
  match expression.pexp_desc with
  | Pexp_ident identifier -> identifier.txt
  | _ -> error ~loc:expression.pexp_loc "expected a qualified identifier"

let rec longident_parts = function
  | Longident.Lident name -> [ name ]
  | Longident.Ldot (parent, name) -> longident_parts parent @ [ name ]
  | Longident.Lapply _ -> []

let is_identifier expected expression = longident_of_expression expression |> longident_parts = expected

let string_of_expression expression =
  match expression.pexp_desc with
  | Pexp_constant (Pconst_string (value, _, _)) -> value
  | _ -> error ~loc:expression.pexp_loc "expected a string literal"

let name_of_route expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident name; _ }, None) -> name
  | _ -> error ~loc:expression.pexp_loc "route name must be a module identifier"

let component_attachment ~label expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt; loc }, None) ->
      { expression with pexp_desc = Pexp_ident { txt = Longident.Ldot (txt, "make"); loc } }
  | _ -> error ~loc:expression.pexp_loc "~%s takes a component module, for example ~%s=Pages.Note" label label

let type_of_name ~loc name = Ast_builder.Default.ptyp_constr ~loc { txt = Longident.parse name; loc } []

let to_string_of_type ~loc name =
  match String.split_on_char '.' name with
  | [ "bool" ] -> Longident.Ldot (Lident "Stdlib", "string_of_bool")
  | [ "int" ] -> Longident.Ldot (Lident "Stdlib", "string_of_int")
  | [ "string" ] -> Longident.parse "Fun.id"
  | parts -> (
      match List.rev parts with
      | "t" :: module_parts when module_parts <> [] ->
          List.rev ("to_string" :: module_parts) |> String.concat "." |> Longident.parse
      | _ -> error ~loc "custom path parameter types must end in .t")

let parser_of_type ~loc name =
  match String.split_on_char '.' name with
  | [ "bool" ] -> Longident.parse "RouterRuntime.Search.parseBool"
  | [ "int" ] -> Longident.parse "RouterRuntime.Search.parseInt"
  | [ "string" ] -> Longident.parse "RouterRuntime.Search.parseString"
  | parts -> (
      match List.rev parts with
      | "t" :: module_parts when module_parts <> [] ->
          List.rev ("parse" :: module_parts) |> String.concat "." |> Longident.parse
      | _ -> error ~loc "custom search parameter types must end in .t")

let type_name_of_expression expression = longident_of_expression expression |> longident_parts |> String.concat "."

let pattern_of_path ~loc path =
  match (RouterUtf8.valid path, RouterPattern.parseTemplate path) with
  | false, _ | true, Error _ -> error ~loc "invalid route path %s" path
  | true, Ok pattern -> pattern

let parameters_of_path ~loc path =
  let pattern = pattern_of_path ~loc path in
  let optional = RouterPattern.optional pattern in
  RouterPattern.parameters pattern
  |> List.map (fun (parameter : RouterPattern.parameter) ->
      let is_optional = List.mem parameter.name optional in
      match parameter.typeName with
      | "string..." ->
          let typ =
            Ast_builder.Default.ptyp_constr ~loc { txt = Longident.Lident "list"; loc } [ type_of_name ~loc "string" ]
          in
          {
            name = parameter.name;
            presence = (if is_optional then OptionalRest else Segment);
            typ;
            argument = typ;
            parser = Longident.parse "RouterRuntime.CatchAll.parse";
            to_string = Longident.parse "RouterRuntime.CatchAll.toString";
            loc;
          }
      | type_name ->
          let argument = type_of_name ~loc type_name in
          {
            name = parameter.name;
            presence = (if is_optional then OptionalSegment else Segment);
            typ =
              (if is_optional then
                 Ast_builder.Default.ptyp_constr ~loc { txt = Longident.Lident "option"; loc } [ argument ]
               else argument);
            argument;
            parser = parser_of_type ~loc type_name;
            to_string = to_string_of_type ~loc type_name;
            loc;
          })

let arguments expression =
  match expression.pexp_desc with
  | Pexp_apply (callee, arguments) -> (callee, arguments)
  | _ -> error ~loc:expression.pexp_loc "expected a router declaration call"

let argument label arguments =
  List.find_map (fun (argument_label, expression) -> if argument_label = label then Some expression else None) arguments

let unlabelled_arguments arguments =
  List.filter_map (fun (label, expression) -> if label = Nolabel then Some expression else None) arguments

let attachment_labels = [ "layout"; "loading"; "notFound"; "error"; "loader"; "loaderLabel"; "metadata"; "headers" ]
let renamed_labels = [ ("loaderAs_", "loaderLabel"); ("to_", "target") ]

let rec duplicate = function
  | [] -> None
  | value :: values -> if List.mem value values then Some value else duplicate values

let validate_arguments ~loc ~allowed ~unlabelled arguments =
  let labels =
    List.filter_map
      (fun (label, _) -> match label with Labelled label | Optional label -> Some label | Nolabel -> None)
      arguments
  in
  List.iter
    (fun label ->
      match List.assoc_opt label renamed_labels with
      | Some renamed -> error ~loc "~%s was renamed to ~%s" label renamed
      | None -> if not (List.mem label allowed) then error ~loc "unknown router argument ~%s" label)
    labels;
  (match duplicate labels with Some label -> error ~loc "duplicate router argument ~%s" label | None -> ());
  if List.length (unlabelled_arguments arguments) <> unlabelled then
    error ~loc "expected %d unlabelled router argument(s)" unlabelled

let search_kind ~name expression =
  let callee, arguments = arguments expression in
  let values = unlabelled_arguments arguments in
  let kind, type_expression, unlabelled =
    if is_identifier [ "Router"; "Search"; "required" ] callee then
      match values with
      | [ typ ] -> (Required, typ, 1)
      | _ -> error ~loc:expression.pexp_loc "Search.required expects one type"
    else if is_identifier [ "Router"; "Search"; "optional" ] callee then
      match values with
      | [ typ ] -> (Optional, typ, 1)
      | _ -> error ~loc:expression.pexp_loc "Search.optional expects one type"
    else if is_identifier [ "Router"; "Search"; "default" ] callee then
      match values with
      | [ typ; default ] -> (Default default, typ, 2)
      | _ -> error ~loc:expression.pexp_loc "Search.default expects a type and default"
    else if is_identifier [ "Router"; "Search"; "many" ] callee then
      match values with [ typ ] -> (Many, typ, 1) | _ -> error ~loc:expression.pexp_loc "Search.many expects one type"
    else error ~loc:expression.pexp_loc "unknown search schema constructor"
  in
  validate_arguments ~loc:expression.pexp_loc ~allowed:[ "key"; "shallow" ] ~unlabelled arguments;
  let shallow =
    match argument (Labelled "shallow") arguments with
    | None -> false
    | Some { pexp_desc = Pexp_construct ({ txt = Lident "true"; _ }, None); _ } -> true
    | Some { pexp_desc = Pexp_construct ({ txt = Lident "false"; _ }, None); _ } -> false
    | Some shallow_expression ->
        error ~loc:shallow_expression.pexp_loc "~shallow takes true or false, for example ~shallow:true"
  in
  let key =
    match argument (Labelled "key") arguments with
    | None -> name
    | Some key_expression ->
        let key =
          match key_expression.pexp_desc with
          | Pexp_constant (Pconst_string (key, _, _)) -> key
          | _ -> error ~loc:key_expression.pexp_loc "~key takes a string literal, for example ~key:\"info-page\""
        in
        if String.equal key "" then error ~loc:key_expression.pexp_loc "search key must not be empty";
        if not (RouterUtf8.valid key) then error ~loc:key_expression.pexp_loc "search key %S is not valid UTF-8" key;
        key
  in
  let type_name = type_name_of_expression type_expression in
  ( kind,
    key,
    shallow,
    type_of_name ~loc:type_expression.pexp_loc type_name,
    parser_of_type ~loc:type_expression.pexp_loc type_name,
    to_string_of_type ~loc:type_expression.pexp_loc type_name )

let search_of_expression expression =
  match expression.pexp_desc with
  | Pexp_record (fields, None) ->
      List.map
        (fun ({ txt; loc }, value) ->
          let name =
            match longident_parts txt |> List.rev with
            | name :: _ -> name
            | [] -> error ~loc "search field needs a name"
          in
          let kind, key, shallow, typ, parser, to_string = search_kind ~name value in
          { name; key; typ; parser; to_string; kind; shallow; loc })
        fields
  | _ -> error ~loc:expression.pexp_loc "~search must be a record schema"

let rec list_of_expression expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident "[]"; _ }, None) -> []
  | Pexp_construct ({ txt = Longident.Lident "::"; _ }, Some { pexp_desc = Pexp_tuple [ head; tail ]; _ }) ->
      head :: list_of_expression tail
  | _ -> error ~loc:expression.pexp_loc "expected a route list"

let join_path parent child =
  match (RouterPattern.parseTemplate parent, RouterPattern.parseTemplate child) with
  | Ok parent, Ok child -> RouterPattern.append parent child |> RouterPattern.toString
  | _ -> invalid_arg "validated router paths failed to compose"

let loader_attachment expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt; loc }, None) -> (
      match longident_parts txt |> List.rev with
      | module_name :: _ ->
          let run = { expression with pexp_desc = Pexp_ident { txt = Longident.Ldot (txt, "load"); loc } } in
          (run, String.uncapitalize_ascii module_name)
      | [] -> error ~loc:expression.pexp_loc "~loader takes a loader module, for example ~loader=Pages.NoteLoader")
  | _ -> error ~loc:expression.pexp_loc "~loader takes a loader module, for example ~loader=Pages.NoteLoader"

let loader_alias expression =
  match expression.pexp_desc with
  | Pexp_ident { txt = Longident.Lident name; _ } | Pexp_construct ({ txt = Longident.Lident name; _ }, None) -> name
  | _ -> error ~loc:expression.pexp_loc "~loaderLabel must be an identifier"

let attachments arguments =
  let loader =
    match argument (Labelled "loader") arguments with
    | None -> (
        match argument (Labelled "loaderLabel") arguments with
        | Some alias -> error ~loc:alias.pexp_loc "~loaderLabel requires ~loader"
        | None -> None)
    | Some loader ->
        let run, inferred_label = loader_attachment loader in
        let result_label =
          match argument (Labelled "loaderLabel") arguments with
          | Some alias -> loader_alias alias
          | None -> inferred_label
        in
        Some { run; result_label; loc = loader.pexp_loc }
  in
  let component label = Option.map (component_attachment ~label) (argument (Labelled label) arguments) in
  {
    layout = component "layout";
    loading = component "loading";
    not_found = component "notFound";
    error = component "error";
    loader;
    metadata = argument (Labelled "metadata") arguments;
    headers = argument (Labelled "headers") arguments;
  }

let prefetch_level arguments =
  match argument (Labelled "prefetch") arguments with
  | None -> None
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Off"; _ }, None); _ } -> Some Off
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Intent"; _ }, None); _ } -> Some Intent
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Viewport"; _ }, None); _ } -> Some Viewport
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Idle"; _ }, None); _ } -> Some Idle
  | Some expression -> error ~loc:expression.pexp_loc "~prefetch must be Off, Intent, Viewport or Idle"

let scope ~id ~path arguments expression =
  {
    id;
    path;
    parameters = parameters_of_path ~loc:expression.pexp_loc path;
    search =
      (match argument (Labelled "search") arguments with Some search -> search_of_expression search | None -> []);
    attachments = attachments arguments;
    prefetch = prefetch_level arguments;
    loc = expression.pexp_loc;
  }

let trailing_slash_policy arguments =
  match argument (Labelled "trailingSlash") arguments with
  | None -> Redirect
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Redirect"; _ }, None); _ } -> Redirect
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "Reject"; _ }, None); _ } -> Reject
  | Some expression -> error ~loc:expression.pexp_loc "~trailingSlash must be Redirect or Reject"

let bool_argument label arguments =
  match argument (Labelled label) arguments with
  | None -> None
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "true"; _ }, None); _ } -> Some true
  | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "false"; _ }, None); _ } -> Some false
  | Some expression -> error ~loc:expression.pexp_loc "~%s must be true or false" label

let float_argument label arguments =
  match argument (Labelled label) arguments with
  | None -> None
  | Some { pexp_desc = Pexp_constant (Pconst_float (literal, None)); _ } -> Some literal
  | Some expression -> error ~loc:expression.pexp_loc "~%s must be a float literal, such as 30.0" label

let reject_context ~callee arguments =
  match argument (Labelled "context") arguments with
  | Some context -> error ~loc:context.pexp_loc "%s cannot declare ~context; declare it on Router.make" callee
  | None -> ()

let rec node_of_expression ~address expression =
  let callee, arguments = arguments expression in
  if is_identifier [ "Router"; "route" ] callee then
    let () = reject_context ~callee:"Router.route" arguments in
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:([ "page"; "path"; "search"; "prefetch" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let name =
      match argument Nolabel arguments with
      | Some name -> name_of_route name
      | None -> error ~loc:expression.pexp_loc "route requires a name"
    in
    let page =
      match argument (Labelled "page") arguments with
      | Some page -> component_attachment ~label:"page" page
      | None -> error ~loc:expression.pexp_loc "route requires ~page"
    in
    let path =
      match argument (Labelled "path") arguments with
      | Some path -> string_of_expression path
      | None -> error ~loc:expression.pexp_loc "route requires ~path"
    in
    Route { name; page; scope = scope ~id:("route:" ^ name) ~path arguments expression; loc = expression.pexp_loc }
  else if is_identifier [ "Router"; "group" ] callee then
    let () = reject_context ~callee:"Router.group" arguments in
    let () =
      match argument (Labelled "search") arguments with
      | Some search ->
          error ~loc:search.pexp_loc "Router.group cannot declare ~search; declare it on Router.make or on each route"
      | None -> ()
    in
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:([ "path"; "prefetch" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let local_path =
      match argument (Labelled "path") arguments with Some path -> string_of_expression path | None -> "/"
    in
    let () =
      match RouterPattern.parseTemplate local_path with
      | Ok pattern
        when List.exists
               (function RouterPattern.CatchAll _ -> true | Static _ | Parameter _ -> false)
               (RouterPattern.segments pattern) ->
          error ~loc:expression.pexp_loc "group path %s cannot contain a catch-all segment" local_path
      | Ok pattern when RouterPattern.optional pattern <> [] ->
          error ~loc:expression.pexp_loc "group path %s cannot contain an optional segment" local_path
      | Ok _ | Error _ -> ()
    in
    match List.rev arguments with
    | (Nolabel, children) :: _ ->
        Group
          {
            scope = scope ~id:("group:" ^ address) ~path:local_path arguments expression;
            children =
              list_of_expression children
              |> List.mapi (fun index child -> node_of_expression ~address:(address ^ "." ^ Int.to_string index) child);
          }
    | _ -> error ~loc:expression.pexp_loc "group requires a child list"
  else if is_identifier [ "Router"; "redirect" ] callee then (
    let () = reject_context ~callee:"Router.redirect" arguments in
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:[ "path"; "search"; "target"; "permanent" ]
        ~unlabelled:0 arguments
    in
    let path =
      match argument (Labelled "path") arguments with
      | Some path -> string_of_expression path
      | None -> error ~loc:expression.pexp_loc "redirect requires ~path"
    in
    if RouterPattern.optional (pattern_of_path ~loc:expression.pexp_loc path) <> [] then
      error ~loc:expression.pexp_loc "redirect path %s cannot contain an optional segment" path;
    let target =
      match argument (Labelled "target") arguments with
      | Some target -> target
      | None -> error ~loc:expression.pexp_loc "redirect requires ~target"
    in
    let permanent =
      match argument (Labelled "permanent") arguments with
      | None -> false
      | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "true"; _ }, None); _ } -> true
      | Some { pexp_desc = Pexp_construct ({ txt = Longident.Lident "false"; _ }, None); _ } -> false
      | Some expression -> error ~loc:expression.pexp_loc "~permanent must be true or false"
    in
    Redirect
      {
        id = "redirect:" ^ address;
        target;
        permanent;
        scope = scope ~id:("redirect:" ^ address) ~path arguments expression;
        loc = expression.pexp_loc;
      })
  else error ~loc:expression.pexp_loc "expected Router.route, Router.group, or Router.redirect"

let root_search declaration = declaration.root.scope.search

let shapes path =
  match RouterPattern.parseTemplate path with
  | Ok pattern -> RouterPattern.shapes pattern
  | Error _ -> invalid_arg "validated router path failed to parse"

let generated_labels =
  [
    "applicationStatus";
    "ariaCurrent";
    "basePath";
    "children";
    "className";
    "decodeError";
    "destination";
    "download";
    "error";
    "fallback";
    "hash";
    "history";
    "href";
    "input";
    "item";
    "make";
    "pattern";
    "registry";
    "revalidate";
    "routeSearch";
    "search";
    "target";
    "updateSearch";
    "unsafeDestination";
    "useNavigation";
    "useRoute";
    "useSearch";
    "useUpdateHash";
    "value";
    "values";
  ]

let endpoints declaration =
  let rec flatten ~parent_path ~parameters ~search ~scopes node =
    let local_scope =
      match node with Group group -> group.scope | Route leaf -> leaf.scope | Redirect leaf -> leaf.scope
    in
    let path = join_path parent_path local_scope.path in
    let parameters = parameters @ local_scope.parameters in
    let search = search @ local_scope.search in
    let scopes = scopes @ [ local_scope ] in
    match node with
    | Route leaf ->
        let prefetch =
          List.fold_left (fun level (scope : scope) -> Option.value scope.prefetch ~default:level) Intent scopes
        in
        [ Page { name = leaf.name; page = leaf.page; path; parameters; search; scopes; prefetch; loc = leaf.loc } ]
    | Redirect leaf ->
        [
          RedirectTo
            { id = leaf.id; target = leaf.target; permanent = leaf.permanent; path; parameters; search; loc = leaf.loc };
        ]
    | Group group -> List.concat_map (flatten ~parent_path:path ~parameters ~search ~scopes) group.children
  in
  let endpoints =
    List.concat_map
      (flatten ~parent_path:"" ~parameters:declaration.root.scope.parameters ~search:declaration.root.scope.search
         ~scopes:[ declaration.root.scope ])
      declaration.root.children
  in
  List.iter
    (fun endpoint ->
      let parameters, search, loader_labels, loc =
        match endpoint with
        | Page route ->
            ( route.parameters,
              route.search,
              List.filter_map
                (fun (scope : scope) -> Option.map (fun loader -> loader.result_label) scope.attachments.loader)
                route.scopes,
              route.loc )
        | RedirectTo redirect -> (redirect.parameters, redirect.search, [], redirect.loc)
      in
      (match duplicate (List.map (fun (search : search) -> search.name) search) with
      | Some name -> error ~loc "duplicate search parameter %s" name
      | None -> ());
      (match duplicate (List.map (fun (search : search) -> search.key) search) with
      | Some key ->
          let search = List.filter (fun (search : search) -> String.equal search.key key) search in
          let labels = List.map (fun (search : search) -> search.name) search in
          let loc = match List.rev search with last :: _ -> last.loc | [] -> loc in
          error ~loc "duplicate search key %S, used by %s" key (String.concat " and " labels)
      | None -> ());
      let labels = List.map (fun (parameter : parameter) -> parameter.name) parameters @ loader_labels in
      match duplicate labels with
      | Some label -> error ~loc "duplicate branch input label %s" label
      | None ->
          List.iter
            (fun label ->
              if List.mem label generated_labels || (Option.is_some declaration.context && String.equal label "context")
              then error ~loc "branch input label %s conflicts with a generated router argument" label)
            labels)
    endpoints;
  let routes = List.filter_map (function Page route -> Some route | RedirectTo _ -> None) endpoints in
  (match duplicate (List.map (fun (route : route) -> route.name) routes) with
  | Some name -> error ~loc:declaration.loc "duplicate generated route name %s" name
  | None -> ());
  let reserved = [ "Status"; "Loader"; "Error"; "Metadata"; "Headers"; "Navigation"; "Search"; "Link" ] in
  List.iter
    (fun route ->
      if List.mem route.name reserved then error ~loc:route.loc "generated route name %s is reserved" route.name)
    routes;
  let endpoint_path = function Page route -> route.path | RedirectTo redirect -> redirect.path in
  let endpoint_loc = function Page route -> route.loc | RedirectTo redirect -> redirect.loc in
  let describe endpoint shape =
    let path = endpoint_path endpoint in
    let shape = RouterPattern.toString shape in
    if String.equal shape path then shape else shape ^ " (from " ^ path ^ ")"
  in
  let validate_shape (left, left_shape) (right, right_shape) =
    match RouterPattern.relationship left_shape right_shape with
    | Duplicate -> error ~loc:(endpoint_loc right) "duplicate route path %s" (describe right right_shape)
    | Ambiguous ->
        error ~loc:(endpoint_loc right) "ambiguous route patterns %s and %s" (describe left left_shape)
          (describe right right_shape)
    | IncompatiblePrefix -> (
        match (left, right) with
        | Page _, Page _ ->
            let (prefix, prefix_shape), (pattern, pattern_shape) =
              if List.length (RouterPattern.segments left_shape) < List.length (RouterPattern.segments right_shape) then
                ((left, left_shape), (right, right_shape))
              else ((right, right_shape), (left, left_shape))
            in
            error ~loc:(endpoint_loc pattern) "route prefix parameters differ between %s and %s"
              (describe prefix prefix_shape) (describe pattern pattern_shape)
        | Page _, RedirectTo _ | RedirectTo _, Page _ | RedirectTo _, RedirectTo _ -> ())
    | Distinct | CompatiblePrefix -> ()
  in
  let rec pairs = function [] -> [] | item :: rest -> List.map (fun other -> (item, other)) rest @ pairs rest in
  let expanded = List.map (fun endpoint -> (endpoint, shapes (endpoint_path endpoint))) endpoints in
  List.iter
    (fun (endpoint, shapes) ->
      List.iter
        (fun (left, right) ->
          match RouterPattern.relationship left right with
          | Duplicate | Ambiguous ->
              error ~loc:(endpoint_loc endpoint) "optional segments in %s make %s and %s ambiguous"
                (endpoint_path endpoint) (RouterPattern.toString left) (RouterPattern.toString right)
          | Distinct | CompatiblePrefix | IncompatiblePrefix -> ())
        (pairs shapes))
    expanded;
  List.iter
    (fun ((left, left_shapes), (right, right_shapes)) ->
      List.iter
        (fun left_shape ->
          List.iter (fun right_shape -> validate_shape (left, left_shape) (right, right_shape)) right_shapes)
        left_shapes)
    (pairs expanded);
  endpoints

let routes declaration =
  List.filter_map (function Page route -> Some route | RedirectTo _ -> None) (endpoints declaration)

let declaration_of_expression expression =
  let callee, arguments = arguments expression in
  if not (is_identifier [ "Router"; "make" ] callee) then None
  else
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:
          ([
             "basePath";
             "trailingSlash";
             "search";
             "invalidSearch";
             "interceptLinks";
             "viewTransitions";
             "pageCacheMaxAge";
             "errorStatus";
             "context";
           ]
          @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let base_path =
      match argument (Labelled "basePath") arguments with
      | Some base_path -> (
          let base_path = string_of_expression base_path in
          match (RouterUtf8.valid base_path, RouterPattern.parse base_path) with
          | true, Ok pattern when (not (String.equal base_path "")) && RouterPattern.parameters pattern = [] ->
              base_path
          | false, _ | true, Ok _ | true, Error _ ->
              error ~loc:expression.pexp_loc "invalid router base path %s" base_path)
      | None -> error ~loc:expression.pexp_loc "Router.make requires ~basePath"
    in
    let children =
      match List.rev arguments with
      | (Nolabel, children) :: _ -> list_of_expression children
      | _ -> error ~loc:expression.pexp_loc "Router.make requires a route list"
    in
    let error_status = argument (Labelled "errorStatus") arguments in
    let invalid_search =
      Option.map (component_attachment ~label:"invalidSearch") (argument (Labelled "invalidSearch") arguments)
    in
    let root_scope = scope ~id:"root" ~path:"" arguments expression in
    if
      Option.is_some root_scope.attachments.error
      && List.exists (fun (search : search) -> search.kind = Required) root_scope.search
      && Option.is_none invalid_search
    then error ~loc:expression.pexp_loc "Router.make with required root search and ~error also requires ~invalidSearch";
    Some
      {
        base_path;
        trailing_slash = trailing_slash_policy arguments;
        intercept_links = bool_argument "interceptLinks" arguments;
        view_transitions = bool_argument "viewTransitions" arguments;
        page_cache_max_age = float_argument "pageCacheMaxAge" arguments;
        error_status;
        invalid_search;
        context =
          Option.map
            (fun context -> type_of_name ~loc:context.pexp_loc (type_name_of_expression context))
            (argument (Labelled "context") arguments);
        root =
          {
            scope = root_scope;
            children = List.mapi (fun index child -> node_of_expression ~address:(Int.to_string index) child) children;
          };
        loc = expression.pexp_loc;
      }

let find structure =
  let declarations =
    List.filter_map
      (fun item ->
        match item.pstr_desc with Pstr_eval (expression, _) -> declaration_of_expression expression | _ -> None)
      structure
  in
  match declarations with
  | [] -> None
  | [ declaration ] -> Some declaration
  | declaration :: _ -> error ~loc:declaration.loc "expected exactly one Router.make declaration"
