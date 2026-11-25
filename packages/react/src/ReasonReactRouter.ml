let push (_path : string) = ()
let replace (_path : string) = ()

type url = { path : string list; hash : string; search : string }
type watcherID = unit -> unit

let split_once separator text =
  match String.index_opt text separator with
  | None -> (text, "")
  | Some index -> (String.sub text 0 index, String.sub text (index + 1) (String.length text - index - 1))

let parse_url url_string =
  let before_hash, hash = split_once '#' url_string in
  let pathname, search = split_once '?' before_hash in
  let path = String.split_on_char '/' pathname |> List.filter (fun segment -> segment <> "") in
  { path; hash; search }

let context = React.createContext { path = []; hash = ""; search = "" }

module ServerUrl = struct
  let makeProps ~url ~children () : < url : string ; children : React.element > Js.t =
    object
      method url = url
      method children = children
    end

  let make ?key props =
    React.Context.provider context ?key
      (React.Context.makeProps ~value:(parse_url props#url) ~children:props#children ())
end

let url ?serverUrlString () =
  match serverUrlString with Some url_string -> parse_url url_string | None -> React.useContext context

let dangerouslyGetInitialUrl = url
let watchUrl _callback () = ()
let unwatchUrl _watcherID = ()
let useUrl ?(serverUrl : url option) () = match serverUrl with Some serverUrl -> serverUrl | None -> url ()
