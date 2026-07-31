/**
  MountedLayouts is a registry of the layout levels currently on screen.
  Each entry pairs a route path with that level's renderPage function,
  which swaps the content rendered below the layout.

  let state = [{
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/student",
    renderPage: (pageElement) => {...},
  }]

  When the client visits /student/:id, we find the parent route (/student) with MountedLayouts.find and we call the renderPage function to update the page/subroutes.
  The registry will be updated to:

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

/* When a route level mounts, we register it */
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
