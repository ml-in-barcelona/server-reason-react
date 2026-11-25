let committed pathname search : RouterRuntime.Navigation.committed =
  { location = { pathname; search; hash = ""; key = "server" }; matches = []; layouts = []; revision = "r1" }

let render ~pathname ?(search = "") element =
  ReactDOM.renderToString (RouterReact.locationScope ~committed:(committed pathname search) ~children:element ())

let contains text needle =
  let length = String.length needle in
  let rec loop index =
    index + length <= String.length text && (String.sub text index length = needle || loop (index + 1))
  in
  loop 0

let link ?activeWhen path =
  RouterReact.Link.make
    (RouterReact.Link.makeProps ~destination:(RouterRuntime.destination ~path) ?activeWhen
       ~children:(React.string "Notes") ())

let active ?activeWhen path =
  let probe () =
    React.string (if RouterReact.useIsActive ?activeWhen (RouterRuntime.destination ~path) then "yes" else "no")
  in
  React.Upper_case_component ("Probe", probe)

let pending path =
  let probe () = React.string (if RouterReact.useIsPending (RouterRuntime.destination ~path) then "yes" else "no") in
  React.Upper_case_component ("Probe", probe)

let failures = ref []
let expect name condition = if not condition then failures := name :: !failures
let current html = contains html "aria-current=\"page\""

let () =
  expect "Url link with another search is not current"
    (not (current (render ~pathname:"/app/notes" ~search:"?page=2" (link "/app/notes"))));
  expect "Route link with another search is current"
    (current (render ~pathname:"/app/notes" ~search:"?page=2" (link ~activeWhen:RouterReact.Route "/app/notes")));
  expect "Route link is not current below its path"
    (not (current (render ~pathname:"/app/notes/1" (link ~activeWhen:RouterReact.Route "/app/notes"))));
  expect "Subtree link is current below its path"
    (current (render ~pathname:"/app/notes/1" (link ~activeWhen:RouterReact.Subtree "/app/notes")));
  expect "Subtree link is current on its path"
    (current (render ~pathname:"/app/notes" (link ~activeWhen:RouterReact.Subtree "/app/notes?x=1")));
  expect "Subtree compares whole segments"
    (not (current (render ~pathname:"/app/notes-archive" (link ~activeWhen:RouterReact.Subtree "/app/notes"))));
  expect "Subtree compares decoded segments"
    (current (render ~pathname:"/app/caf%c3%a9/1" (link ~activeWhen:RouterReact.Subtree "/app/caf%C3%A9")));
  expect "Subtree link renders its rule"
    (contains (render ~pathname:"/" (link ~activeWhen:RouterReact.Subtree "/app")) "data-router-link=\"subtree\"");
  expect "Route link renders its rule"
    (contains (render ~pathname:"/" (link ~activeWhen:RouterReact.Route "/app")) "data-router-link=\"route\"");
  expect "Url link keeps an empty rule" (contains (render ~pathname:"/" (link "/app")) "data-router-link=\"\"");
  expect "useIsActive defaults to Route" (contains (render ~pathname:"/app" ~search:"?q=1" (active "/app")) "yes");
  expect "useIsActive Url compares the search"
    (contains (render ~pathname:"/app" ~search:"?q=1" (active ~activeWhen:RouterReact.Url "/app")) "no");
  expect "useIsActive Subtree matches below"
    (contains (render ~pathname:"/app/a/b" (active ~activeWhen:RouterReact.Subtree "/app/a")) "yes");
  expect "useIsActive Subtree does not match above"
    (contains (render ~pathname:"/app" (active ~activeWhen:RouterReact.Subtree "/app/a")) "no");
  expect "useIsPending is false on the server" (contains (render ~pathname:"/app" (pending "/app")) "no");
  match !failures with [] -> () | names -> failwith (String.concat ", " (List.rev names))
