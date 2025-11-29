type location = {
  selectedId: option(int),
  isEditing: bool,
  searchText: option(string),
};

let locationToString = location =>
  [
    switch (location.selectedId) {
    | Some(id) => "selectedId=" ++ Int.to_string(id)
    | None => "selectedId="
    },
    "isEditing=" ++ (location.isEditing ? "true" : "false"),
    switch (location.searchText) {
    | Some(text) => "searchText=" ++ text
    | None => "searchText="
    },
  ]
  |> List.filter(s => s != "")
  |> String.concat("&");

let initialLocation = {
  selectedId: None,
  isEditing: false,
  searchText: None,
};

let locationFromString = str => {
  switch (URL.make(str)) {
  | Some(url) =>
    let searchParams = URL.searchParams(url);
    let selectedId =
      URL.SearchParams.get(searchParams, "selectedId")
      |> Option.map(id => int_of_string(id));
    let searchText = URL.SearchParams.get(searchParams, "searchText");

    let isEditing =
      URL.SearchParams.get(searchParams, "isEditing")
      |> Option.map(v =>
           switch (v) {
           | "true" => true
           | "false" => false
           | _ => false
           }
         )
      |> Option.value(~default=false);

    {
      selectedId,
      isEditing,
      searchText,
    };

  | None => initialLocation
  };
};

type payload = {
  body: string,
  title: string,
};

[@platform js]
module Response = Fetch.Response;

[@platform native]
module Response = {
  type t = unit;
};

type router = {
  location,
  navigate: location => unit,
  /* useAction: (string, string) => ((payload, location, unit) => unit, bool), */
};

[@platform js] external windowNavigate: string => unit = "window.__navigate";

let navigate = (location: location) => {
  switch%platform (Runtime.platform) {
  | Client => windowNavigate(locationToString(location))
  | Server => /* on the server, navigate doesn't mean anything */ ()
  };
};

let useRouter: unit => router = () => {
  location: initialLocation,
  navigate,
};

let useNavigate = () => navigate;
