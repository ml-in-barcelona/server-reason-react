open Ppxlib

type parameter = { name : string; typ : core_type; parser : Longident.t; printer : Longident.t; loc : Location.t }
type search_kind = Required | Optional | Default of expression | Many

type search = {
  name : string;
  typ : core_type;
  parser : Longident.t;
  printer : Longident.t;
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

type t = { base_path : string; application_error : Longident.t option; root : group; loc : Location.t }

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

let name_of_page page =
  match longident_of_expression page |> longident_parts |> List.rev with
  | "make" :: module_name :: _ -> module_name
  | _ -> error ~loc:page.pexp_loc "page must be a module make function"

let name_of_alias expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident name; _ }, None) -> name
  | _ -> error ~loc:expression.pexp_loc "~as_ must be a module identifier"

let type_of_name ~loc name = Ast_builder.Default.ptyp_constr ~loc { txt = Longident.parse name; loc } []

let printer_of_type ~loc name =
  match String.split_on_char '.' name with
  | [ "int" ] -> Longident.Lident "string_of_int"
  | [ "string" ] -> Longident.parse "Fun.id"
  | parts -> (
      match List.rev parts with
      | "t" :: module_parts when module_parts <> [] ->
          List.rev ("print" :: module_parts) |> String.concat "." |> Longident.parse
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

let parameters_of_path ~loc path =
  let length = String.length path in
  let rec find_char character index =
    if index >= length then None else if path.[index] = character then Some index else find_char character (index + 1)
  in
  let rec loop index parameters =
    match find_char ':' index with
    | None -> List.rev parameters
    | Some colon -> (
        match find_char '<' (colon + 1) with
        | None -> error ~loc "path parameter requires a <type> annotation"
        | Some opening -> (
            match find_char '>' (opening + 1) with
            | None -> error ~loc "unterminated path parameter type"
            | Some closing ->
                let name = String.sub path (colon + 1) (opening - colon - 1) in
                let type_name = String.sub path (opening + 1) (closing - opening - 1) in
                if name = "" || type_name = "" then error ~loc "path parameter name and type must not be empty";
                loop (closing + 1)
                  ({
                     name;
                     typ = type_of_name ~loc type_name;
                     parser = parser_of_type ~loc type_name;
                     printer = printer_of_type ~loc type_name;
                     loc;
                   }
                  :: parameters)))
  in
  loop 0 []

let arguments expression =
  match expression.pexp_desc with
  | Pexp_apply (callee, arguments) -> (callee, arguments)
  | _ -> error ~loc:expression.pexp_loc "expected a router declaration call"

let argument label arguments =
  List.find_map (fun (argument_label, expression) -> if argument_label = label then Some expression else None) arguments

let unlabelled_arguments arguments =
  List.filter_map (fun (label, expression) -> if label = Nolabel then Some expression else None) arguments

let attachment_labels = [ "layout"; "loading"; "notFound"; "error"; "loader"; "loaderAs_"; "metadata"; "headers" ]

let validate_arguments ~loc ~allowed ~unlabelled arguments =
  let labels =
    List.filter_map
      (fun (label, _) -> match label with Labelled label | Optional label -> Some label | Nolabel -> None)
      arguments
  in
  List.iter (fun label -> if not (List.mem label allowed) then error ~loc "unknown router argument ~%s" label) labels;
  let rec duplicate = function
    | [] -> None
    | label :: labels -> if List.mem label labels then Some label else duplicate labels
  in
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
    printer_of_type ~loc:type_expression.pexp_loc type_name )

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
          let kind, typ, parser, printer = search_kind value in
          { name; typ; parser; printer; kind; loc })
        fields
  | _ -> error ~loc:expression.pexp_loc "~search must be a record schema"

let rec list_of_expression expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident "[]"; _ }, None) -> []
  | Pexp_construct ({ txt = Longident.Lident "::"; _ }, Some { pexp_desc = Pexp_tuple [ head; tail ]; _ }) ->
      head :: list_of_expression tail
  | _ -> error ~loc:expression.pexp_loc "expected a route list"

let join_path parent child =
  if child = "/" then if parent = "" then "/" else parent
  else if parent = "" || parent = "/" then child
  else parent ^ child

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
        ~allowed:([ "path"; "as_"; "search" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let page =
      match argument Nolabel arguments with
      | Some page -> page
      | None -> error ~loc:expression.pexp_loc "route requires a page"
    in
    let path =
      match argument (Labelled "path") arguments with
      | Some path -> string_of_expression path
      | None -> error ~loc:expression.pexp_loc "route requires ~path"
    in
    let name =
      match argument (Labelled "as_") arguments with Some alias -> name_of_alias alias | None -> name_of_page page
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
  let duplicate values =
    let rec loop = function [] -> None | value :: rest -> if List.mem value rest then Some value else loop rest in
    loop values
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
      | None -> ())
    routes;
  (match duplicate (List.map (fun (route : route) -> route.name) routes) with
  | Some name -> error ~loc:declaration.loc "duplicate generated route name %s" name
  | None -> ());
  let reserved = [ "Status"; "Loader"; "Error"; "Metadata"; "Headers"; "Navigation"; "Search" ] in
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
        ~allowed:([ "basePath"; "search" ] @ attachment_labels)
        ~unlabelled:1 arguments
    in
    let base_path =
      match argument (Labelled "basePath") arguments with
      | Some base_path -> string_of_expression base_path
      | None -> error ~loc:expression.pexp_loc "Router.make requires ~basePath"
    in
    let children =
      match List.rev arguments with
      | (Nolabel, children) :: _ -> list_of_expression children
      | _ -> error ~loc:expression.pexp_loc "Router.make requires a route list"
    in
    let application_error = root_error_policy arguments in
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
    Some
      {
        base_path;
        application_error;
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
