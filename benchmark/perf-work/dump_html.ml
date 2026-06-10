(* Dump HTML for byte-diff comparison across perf experiments.

   Usage: dump_html.exe [scenario] [--string]
   With no args, prints the list of scenarios. [--string] renders with
   [renderToString] instead of [renderToStaticMarkup]. *)

let scenarios : (string * (unit -> React.element)) list =
  let open Benchmark_scenarios in
  [
    ("Trivial", fun () -> Trivial.make (Trivial.makeProps ()));
    ("ShallowTree", fun () -> ShallowTree.make (ShallowTree.makeProps ()));
    ("DeepTree10", fun () -> DeepTree.Depth10.make (DeepTree.Depth10.makeProps ()));
    ("DeepTree50", fun () -> DeepTree.Depth50.make (DeepTree.Depth50.makeProps ()));
    ("WideTree10", fun () -> WideTree.Wide10.make (WideTree.Wide10.makeProps ()));
    ("WideTree100", fun () -> WideTree.Wide100.make (WideTree.Wide100.makeProps ()));
    ("WideTree500", fun () -> WideTree.Wide500.make (WideTree.Wide500.makeProps ()));
    ("Table10", fun () -> Table.Table10.make (Table.Table10.makeProps ()));
    ("Table100", fun () -> Table.Table100.make (Table.Table100.makeProps ()));
    ("Table500", fun () -> Table.Table500.make (Table.Table500.makeProps ()));
    ("PropsSmall", fun () -> PropsHeavy.Small.make (PropsHeavy.Small.makeProps ()));
    ("PropsMedium", fun () -> PropsHeavy.Medium.make (PropsHeavy.Medium.makeProps ()));
    ("Ecommerce24", fun () -> Ecommerce.Products24.make (Ecommerce.Products24.makeProps ()));
    ("Ecommerce48", fun () -> Ecommerce.Products48.make (Ecommerce.Products48.makeProps ()));
    ("Dashboard", fun () -> Dashboard.make (Dashboard.makeProps ()));
    ("Blog50", fun () -> Blog.Blog50.make (Blog.Blog50.makeProps ()));
    ("Form", fun () -> Form.make (Form.makeProps ()));
  ]

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let use_string = List.mem "--string" args in
  let which = List.filter (fun a -> a <> "--string") args in
  match which with
  | [] ->
      print_endline "Scenarios:";
      List.iter (fun (name, _) -> Printf.printf "  %s\n" name) scenarios
  | name :: _ -> (
      match List.assoc_opt name scenarios with
      | None -> failwith ("unknown scenario: " ^ name)
      | Some make ->
          let element = make () in
          let html = if use_string then ReactDOM.renderToString element else ReactDOM.renderToStaticMarkup element in
          print_string html)
