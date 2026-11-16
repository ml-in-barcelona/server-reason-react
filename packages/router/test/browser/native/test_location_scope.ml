let committed : RouterRuntime.Navigation.committed =
  {
    location = { pathname = "/app/notes"; search = ""; hash = ""; key = "server" };
    matches = [];
    layouts = [];
    revision = "r1";
  }

let link () =
  RouterReact.Link.make
    (RouterReact.Link.makeProps
       ~destination:(RouterRuntime.destination ~path:"/app/notes")
       ~children:(React.string "Notes") ())

let model element =
  let rows = Buffer.create 256 in
  Lwt_main.run
    (ReactServerDOM.render_model
       ~subscribe:(fun row ->
         Buffer.add_string rows row;
         Lwt.return ())
       element);
  Buffer.contents rows

let contains text needle =
  let length = String.length needle in
  let rec loop index =
    index + length <= String.length text && (String.sub text index length = needle || loop (index + 1))
  in
  loop 0

let () =
  let scoped = RouterReact.locationScope ~committed ~children:(link ()) () in
  if not (contains (model scoped) "aria-current") then
    failwith "a scoped Link had no aria-current in the Flight payload";
  if not (contains (ReactDOM.renderToString scoped) "aria-current=\"page\"") then
    failwith "a scoped Link had no aria-current in the HTML";
  if contains (model (link ())) "aria-current" then failwith "a Link outside any scope claimed to be current"
