/**
  Virtual History is a state of routes that the client has visited.
  It's used to store the routes path and renderPage function.
  This is how the client knows which route is rendered, and which subroute needs to get rendered as pageconsumer (children)

  let state = [{
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/student",
    renderPage: (pageElement) => {...},
  }]

  When the client visits /student/:id, we find the parent route (/student) with VirtualHistory.find and we call the renderPage function to update the page/subroutes.
  The virtual state history will be updated to:

  [
    {
      path: "/",
      renderPage: (pageElement) => {...},
    },
    {
      path: "/student",
      renderPage: (pageElement) => {...},
    },
    {
      path: "/student/:id",
      renderPage: (pageElement) => {...},
    },
  ]
 */

type route = {
  path: string,
  renderPage: React.element => unit,
};

let state = ref([]);

/* When a route is visited, we add it to the virtual state history */
let push = (~path, ~renderPage): unit => {
  let filteredRoutes = List.filter(route => route.path != path, state^);

  state :=
    filteredRoutes
    @ [
      {
        path,
        renderPage,
      },
    ];
};

let find = (path: string) => {
  List.find_opt(route => route.path == path, state^);
};

let cleanup = () => {
  state := [];
};

let cleanPathState = path => {
  state :=
    List.filter(
      route => route.path |> String.length <= (path |> String.length),
      state^,
    );
};

let getAllRoutes = () => {
  state^;
};
