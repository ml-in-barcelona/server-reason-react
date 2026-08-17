open Ppxlib

type parameter = { name : string; typ : core_type; parser : Longident.t; to_string : Longident.t; loc : Location.t }
type search_kind = Required | Optional | Default of expression | Many

type search = {
  name : string;
  typ : core_type;
  parser : Longident.t;
  to_string : Longident.t;
  kind : search_kind;
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

type scope = {
  id : string;
  path : string;
  parameters : parameter list;
  search : search list;
  attachments : attachments;
  loc : Location.t;
}

type leaf = { name : string; page : expression; scope : scope; loc : Location.t }

type group = { scope : scope; children : node list }
and node = Group of group | Route of leaf

type route = {
  name : string;
  page : expression;
  path : string;
  parameters : parameter list;
  search : search list;
  scopes : scope list;
  loc : Location.t;
}

type t = {
  base_path : string;
  application_error : Longident.t option;
  invalid_search : expression option;
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

let type_of_name ~loc name = Ast_builder.Default.ptyp_constr ~loc { txt = Longident.parse name; loc } []

let to_string_of_type ~loc name =
  match String.split_on_char '.' name with
  | [ "int" ] -> Longident.Lident "string_of_int"
  | [ "string" ] -> Longident.parse "Fun.id"
  | parts -> (
      match List.rev parts with
      | "t" :: module_parts when module_parts <> [] ->
          List.rev ("to_string" :: module_parts) |> String.concat "." |> Longident.parse
      | _ -> error ~loc "custom path parameter types must end in .t")

let parser_of_type ~loc name =
  match String.split_on_char '.' name with
  | [ "int" ] -> Longident.parse "RouterRuntime.Search.parseInt"
  | [ "string" ] -> Longident.parse "RouterRuntime.Search.parseString"
  | parts -> (
      match List.rev parts with
      | "t" :: module_parts when module_parts <> [] ->
          List.rev ("parse" :: module_parts) |> String.concat "." |> Longident.parse
      | _ -> error ~loc "custom search parameter types must end in .t")

let type_name_of_expression expression = longident_of_expression expression |> longident_parts |> String.concat "."

let valid_utf8 value =
  let length = String.length value in
  let byte index = Char.code value.[index] in
  let continuation index = index < length && byte index >= 0x80 && byte index <= 0xbf in
  let rec loop index =
    if index >= length then true
    else
      let first = byte index in
      if first <= 0x7f then loop (index + 1)
      else if first >= 0xc2 && first <= 0xdf then continuation (index + 1) && loop (index + 2)
      else if first = 0xe0 then
        index + 2 < length
        && byte (index + 1) >= 0xa0
        && byte (index + 1) <= 0xbf
        && continuation (index + 2)
        && loop (index + 3)
      else if (first >= 0xe1 && first <= 0xec) || (first >= 0xee && first <= 0xef) then
        continuation (index + 1) && continuation (index + 2) && loop (index + 3)
      else if first = 0xed then
        index + 2 < length
        && byte (index + 1) >= 0x80
        && byte (index + 1) <= 0x9f
        && continuation (index + 2)
        && loop (index + 3)
      else if first = 0xf0 then
        index + 3 < length
        && byte (index + 1) >= 0x90
        && byte (index + 1) <= 0xbf
        && continuation (index + 2)
        && continuation (index + 3)
        && loop (index + 4)
      else if first >= 0xf1 && first <= 0xf3 then
        continuation (index + 1) && continuation (index + 2) && continuation (index + 3) && loop (index + 4)
      else if first = 0xf4 then
        index + 3 < length
        && byte (index + 1) >= 0x80
        && byte (index + 1) <= 0x8f
        && continuation (index + 2)
        && continuation (index + 3)
        && loop (index + 4)
      else false
  in
  loop 0

let parameters_of_path ~loc path =
  match (valid_utf8 path, RouterPattern.parse path) with
  | false, _ -> error ~loc "invalid route path %s" path
  | true, Error _ -> error ~loc "invalid route path %s" path
  | true, Ok pattern ->
      RouterPattern.parameters pattern
      |> List.map (fun (parameter : RouterPattern.parameter) ->
          let type_name = parameter.typeName in
          {
            name = parameter.name;
            typ = type_of_name ~loc type_name;
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

let attachment_labels = [ "layout"; "loading"; "notFound"; "error"; "loader"; "loaderAs_"; "metadata"; "headers" ]

let rec duplicate = function
  | [] -> None
  | value :: values -> if List.mem value values then Some value else duplicate values

let validate_arguments ~loc ~allowed ~unlabelled arguments =
  let labels =
    List.filter_map
      (fun (label, _) -> match label with Labelled label | Optional label -> Some label | Nolabel -> None)
      arguments
  in
  List.iter (fun label -> if not (List.mem label allowed) then error ~loc "unknown router argument ~%s" label) labels;
  (match duplicate labels with Some label -> error ~loc "duplicate router argument ~%s" label | None -> ());
  if List.length (unlabelled_arguments arguments) <> unlabelled then
    error ~loc "expected %d unlabelled router argument(s)" unlabelled

let search_kind expression =
  let callee, arguments = arguments expression in
  let values = unlabelled_arguments arguments in
  let kind, type_expression =
    if is_identifier [ "Router"; "Search"; "required" ] callee then
      match values with
      | [ typ ] -> (Required, typ)
      | _ -> error ~loc:expression.pexp_loc "Search.required expects one type"
    else if is_identifier [ "Router"; "Search"; "optional" ] callee then
      match values with
      | [ typ ] -> (Optional, typ)
      | _ -> error ~loc:expression.pexp_loc "Search.optional expects one type"
    else if is_identifier [ "Router"; "Search"; "default" ] callee then
      match values with
      | [ typ; default ] -> (Default default, typ)
      | _ -> error ~loc:expression.pexp_loc "Search.default expects a type and default"
    else if is_identifier [ "Router"; "Search"; "many" ] callee then
      match values with [ typ ] -> (Many, typ) | _ -> error ~loc:expression.pexp_loc "Search.many expects one type"
    else error ~loc:expression.pexp_loc "unknown search schema constructor"
  in
  let type_name = type_name_of_expression type_expression in
  ( kind,
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
          let kind, typ, parser, to_string = search_kind value in
          { name; typ; parser; to_string; kind; loc })
        fields
  | _ -> error ~loc:expression.pexp_loc "~search must be a record schema"

let rec list_of_expression expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident "[]"; _ }, None) -> []
  | Pexp_construct ({ txt = Longident.Lident "::"; _ }, Some { pexp_desc = Pexp_tuple [ head; tail ]; _ }) ->
      head :: list_of_expression tail
  | _ -> error ~loc:expression.pexp_loc "expected a route list"

let join_path parent child =
  match (RouterPattern.parse parent, RouterPattern.parse child) with
  | Ok parent, Ok child -> RouterPattern.append parent child |> RouterPattern.toString
  | _ -> invalid_arg "validated router paths failed to compose"

let loader_label expression =
  match longident_of_expression expression |> longident_parts |> List.rev with
  | "load" :: module_name :: _ -> String.uncapitalize_ascii module_name
  | _ -> error ~loc:expression.pexp_loc "~loader requires ~loaderAs_ when its module name cannot be inferred"

let loader_alias expression =
  match expression.pexp_desc with
  | Pexp_ident { txt = Longident.Lident name; _ } | Pexp_construct ({ txt = Longident.Lident name; _ }, None) -> name
  | _ -> error ~loc:expression.pexp_loc "~loaderAs_ must be an identifier"

let attachments arguments =
  let loader =
    match argument (Labelled "loader") arguments with
    | None -> (
        match argument (Labelled "loaderAs_") arguments with
        | Some alias -> error ~loc:alias.pexp_loc "~loaderAs_ requires ~loader"
        | None -> None)
    | Some run ->
        let result_label =
          match argument (Labelled "loaderAs_") arguments with
          | Some alias -> loader_alias alias
          | None -> loader_label run
        in
        Some { run; result_label; loc = run.pexp_loc }
  in
  {
    layout = argument (Labelled "layout") arguments;
    loading = argument (Labelled "loading") arguments;
    not_found = argument (Labelled "notFound") arguments;
    error = argument (Labelled "error") arguments;
    loader;
    metadata = argument (Labelled "metadata") arguments;
    headers = argument (Labelled "headers") arguments;
  }

let scope ~id ~path arguments expression =
  {
    id;
    path;
    parameters = parameters_of_path ~loc:expression.pexp_loc path;
    search =
      (match argument (Labelled "search") arguments with Some search -> search_of_expression search | None -> []);
    attachments = attachments arguments;
    loc = expression.pexp_loc;
  }

let root_error_policy arguments =
  match argument (Labelled "error") arguments with
  | Some { pexp_desc = Pexp_construct ({ txt; _ }, None); _ } -> Some txt
  | _ -> None

let error_boundary_expression ~loc policy =
  Ast_builder.Default.pexp_ident ~loc { txt = Longident.Ldot (policy, "make"); loc }

let rec node_of_expression ~address expression =
  let callee, arguments = arguments expression in
  if is_identifier [ "Router"; "route" ] callee then
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:([ "page"; "path"; "search" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let name =
      match argument Nolabel arguments with
      | Some name -> name_of_route name
      | None -> error ~loc:expression.pexp_loc "route requires a name"
    in
    let page =
      match argument (Labelled "page") arguments with
      | Some page -> page
      | None -> error ~loc:expression.pexp_loc "route requires ~page"
    in
    let path =
      match argument (Labelled "path") arguments with
      | Some path -> string_of_expression path
      | None -> error ~loc:expression.pexp_loc "route requires ~path"
    in
    Route { name; page; scope = scope ~id:("route:" ^ name) ~path arguments expression; loc = expression.pexp_loc }
  else if is_identifier [ "Router"; "group" ] callee then
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:([ "path"; "search" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let local_path =
      match argument (Labelled "path") arguments with Some path -> string_of_expression path | None -> "/"
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
  else error ~loc:expression.pexp_loc "expected Router.route or Router.group"

let root_search declaration = declaration.root.scope.search

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
    "href";
    "includeDescendants";
    "input";
    "item";
    "make";
    "options";
    "pattern";
    "registry";
    "search";
    "target";
    "updateSearch";
    "useIsActive";
    "useNavigation";
    "useSearch";
    "useUpdateHash";
    "value";
    "values";
  ]

let routes declaration =
  let rec flatten ~parent_path ~parameters ~search ~scopes node =
    let local_scope = match node with Group group -> group.scope | Route leaf -> leaf.scope in
    let path = join_path parent_path local_scope.path in
    let parameters = parameters @ local_scope.parameters in
    let search = search @ local_scope.search in
    let scopes = scopes @ [ local_scope ] in
    match node with
    | Route leaf -> [ { name = leaf.name; page = leaf.page; path; parameters; search; scopes; loc = leaf.loc } ]
    | Group group -> List.concat_map (flatten ~parent_path:path ~parameters ~search ~scopes) group.children
  in
  let routes =
    List.concat_map
      (flatten ~parent_path:"" ~parameters:declaration.root.scope.parameters ~search:declaration.root.scope.search
         ~scopes:[ declaration.root.scope ])
      declaration.root.children
  in
  List.iter
    (fun (route : route) ->
      let loader_labels =
        List.filter_map
          (fun (scope : scope) -> Option.map (fun loader -> loader.result_label) scope.attachments.loader)
          route.scopes
      in
      let labels =
        List.map (fun (parameter : parameter) -> parameter.name) route.parameters
        @ List.map (fun (search : search) -> search.name) route.search
        @ loader_labels
      in
      match duplicate labels with
      | Some label -> error ~loc:route.loc "duplicate branch input label %s" label
      | None ->
          List.iter
            (fun label ->
              if List.mem label generated_labels then
                error ~loc:route.loc "branch input label %s conflicts with a generated router argument" label)
            labels)
    routes;
  (match duplicate (List.map (fun (route : route) -> route.name) routes) with
  | Some name -> error ~loc:declaration.loc "duplicate generated route name %s" name
  | None -> ());
  let reserved = [ "Status"; "Loader"; "Error"; "Metadata"; "Headers"; "Navigation"; "Search"; "Link" ] in
  List.iter
    (fun route ->
      if List.mem route.name reserved then error ~loc:route.loc "generated route name %s is reserved" route.name)
    routes;
  routes

let declaration_of_expression expression =
  let callee, arguments = arguments expression in
  if not (is_identifier [ "Router"; "make" ] callee) then None
  else
    let () =
      validate_arguments ~loc:expression.pexp_loc
        ~allowed:([ "basePath"; "search"; "invalidSearch" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let base_path =
      match argument (Labelled "basePath") arguments with
      | Some base_path -> (
          let base_path = string_of_expression base_path in
          match (valid_utf8 base_path, RouterPattern.parse base_path) with
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
    let application_error = root_error_policy arguments in
    let invalid_search = argument (Labelled "invalidSearch") arguments in
    let root_scope = scope ~id:"root" ~path:"" arguments expression in
    let root_scope =
      match application_error with
      | None -> root_scope
      | Some policy ->
          {
            root_scope with
            attachments =
              { root_scope.attachments with error = Some (error_boundary_expression ~loc:expression.pexp_loc policy) };
          }
    in
    if
      Option.is_some root_scope.attachments.error
      && List.exists (fun (search : search) -> search.kind = Required) root_scope.search
      && Option.is_none invalid_search
    then error ~loc:expression.pexp_loc "Router.make with required root search and ~error also requires ~invalidSearch";
    Some
      {
        base_path;
        application_error;
        invalid_search;
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
