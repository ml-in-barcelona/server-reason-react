/**
  Virtual History is a tree of routes that the client has visited.
  It's used to store the routes path and renderPage function.
  This is how the client knows which route is rendered, and which subroute needs to get rendered as outlet (children)

  let tree = [{
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/student",
    renderPage: (pageElement) => {...},
  }]

  When the client visits /student/:id, we find the parent route (/student) with VirtualHistory.find and we call the renderPage function to update the page/subroutes.
  The virtual tree history will be updated to:

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

type branch = {
  path: string,
  renderPage: React.element => unit,
};

let tree = ref([]);

/* When a route is visited, we add it to the virtual tree history */
let push = (~path, ~renderPage): unit => {
  let filteredRoutes = List.filter(route => route.path != path, tree^);

  tree :=
    filteredRoutes
    @ [
      {
        path,
        renderPage,
      },
    ];
};

let find = (path: string) => {
  List.find_opt(route => route.path == path, tree^);
};

let baseBranch = tree^ |> List.hd;

let cleanup = () => {
  tree := [];
};

let cleanTreeBranch = path => {
  tree :=
    List.filter(
      route => route.path |> String.length <= (path |> String.length),
      tree^,
    );
};

let getAllRoutes = () => {
  tree^;
};
