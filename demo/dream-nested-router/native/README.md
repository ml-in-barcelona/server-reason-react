# Nested Router

The Nested Router allows us to navigate through the application while requesting only the minimum required to render the page.

<img width="400" src="https://github.com/user-attachments/assets/185a8406-44b9-4f51-b41f-cb6fe32763d0" />

To understand how this navigation works, we must understand the concepts behind it:

## Route

A route is composed of a **Layout**, a **page**, and **sub-routes**.

A layout is the UI shared across sub-routes. On navigation, layouts preserve state, remain interactive, and do not rerender, while the page is the dynamic content of the current route and is replaced by the sub-route content when navigate to.
The sub-route, as the name suggests, is a route composed of the previous one.

As we can see in the sample below:

<img width="700px" src="https://github.com/user-attachments/assets/098021bb-74e2-4a1e-9252-011ee69fe44d" />

On this sample, we can see the `/`, `/students`, and `/students/lola` pages.
We can divide those into:

- "/"
  - Main Layout (Top bar) (Orange)
  - Main Page (Orange)

- "/student"
  - Main Layout (Orange)
  - Students Layout (Sidebar) (Red)
  - Students Page (Red)
 
- "/student/lola"
  - Main Layout (Top bar) (Orange)
  - Students Layout (Sidebar) (Red)
  - Student Page (Blue)

As we can see, the Main Layout is present on all pages because it is inherited on sub-routes; as such, the Students Layout is present on "/student" and "/student/lola". On the other hand, the "page" is dynamic, defined by the current route.

### How does the control of the route happen?

The main feature of having the control of the route is to be able to render the page content dynamically, based on the current route, so we can request the minimum required to render the page content, keeping the layouts static and only rendering the page content when the route changes.

For example:
- Current route -> /
  ```reason
  module MainLayout = {
    [@react.component]
    let make = (~children) => {
      <div>
        <TopBar />
        children
      </div>
    }
  }
  module MainPage = {
    [@react.component]
    let make = (~children) => {
      <div>
        <h1> "Home" </h1>
        <HomeContent />
      </div>
    }
  }

  /**
    Visual Representation of the MainLayout and MainPage components
    <MainLayout>
      <MainPage />
    </MainLayout>
  */
  ```
- Target route -> /students
  ```reason
  module StudentsLayout = {
    [@react.component]
    let make = (~children) => {
      <div>
        <SideBar />
        children
      </div>
    }
  }
  module StudentsPage = {
    [@react.component]
    let make = (~children) => {
      <div>
        <h1> "Students" </h1>
        <StudentsList />
      </div>
    }
  }

  /**
    Visual Representation of the StudentsLayout and StudentsPage components
    <MainLayout>
      <StudentsLayout>
        <StudentsPage />
      </StudentsLayout>
    </MainLayout>
  */
  ```

In that case we only need the sub-route content, the /students, composed of StudentsLayout and StudentsPage, taking over the MainPage component as the page content. The MainLayout keeps the same, no rerender as the Layout is server component.
To make this work we have a state that stores the route, and a function that updates it when the user navigates to a new route.
The module responsible for this is the `Route` module. All routes are Rendered through the `Route` component.
For example:
```reason
<Route path="/" page={<MainPage />} layout={<MainLayout />} />
<Route path="/students" page={<StudentsPage />} layout={<StudentsLayout />} />
```

As soon we navigate to "/students", inside the Route component of the "/" path, it will render the `<Route path="/students" page={StudentsPage} layout={StudentsLayout} />` component in the place of the `MainPage` component inside the "/" Route component, setting the route state content to the `<Route path="/students" page={StudentsPage} layout={StudentsLayout} />`.

⚠️ **Important** Route is a client component, so the props must respect the React rules for client components, which means that we can't pass a function component as a prop.
```reason
<Route path="/" page={() => <MainPage />} layout={(~children) => <MainLayout children />} />
```
This will cause an error because the function component is not client prop.

#### So how can we update the MainPage to StudentsPage when the user navigates to "/students" if the cannot call layout(~childre=<StudentsLayout />) inside the Route component?

The workaround for it is to use the Context API to pass the children to the layout, through a `Consumer`
```reason
module PageConsumer = {
  [@react.client.component]
  let make = () => {
    let value = React.useContext(context);

    value;
  };
}

[@react.client.component]
let make =
    (~path: string, ~layout: React.element, ~page: option(React.element)) => {
  let (page, setPage) =
    React.useState(() => page |> Option.value(~default=React.null));

  let%browser_only renderPage = pageElement => setPage(_ => pageElement);

  <Provider
    value={page}>
    layout
  </Provider>;
};
```
That way we send to the client the page content, and the layout will be rendered as: `layout(~children=<PageConsumer />)`.
We can dynamically update the page content by calling the `renderPage` function, updating the page content on the layout. With minimum re-renders.

### Virtual History

To make all this work, we need to keep track of the visited routes so we can identify the parent route and the sub-route to render the correct page content.

```reason
type branch = {
  path: string,
  renderPage: React.element => unit,
};

let state = ref([]);
```

That way we can find the route by calling the `find` function with the path of the route, and render the page content by calling the `renderPage` function.
For example
```reason
// Current Virtual History state
[
  {
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students",
    renderPage: (pageElement) => {...},
  },
]

// navigating from "/students" to "/students/:name":
let navigate = (~to: string) => {
  // ...
  let route = VirtualHistory.find("/students");
  route.renderPage(<Route path={"/students/:name"} page={StudentPage} layout={<PageConsumer />} />);
  // ...
}

// After navigating to "/students/:name" the Virtual History state will be updated to:
[
  {
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students/:name",
    renderPage: (pageElement) => {...},
  },
]

// navigating from "/students/lola" to "/students":
let navigate = (~to: string) => {
  // ...
  let route = VirtualHistory.find("/");
  route.renderPage(<Route path={"/students"} page={<StudentsPage />} layout={<StudentsLayout />} />);
  // ...
}

// After navigating to "/" the Virtual History state will be updated to:
[
  {
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students",
    renderPage: (pageElement) => {...},
  },
]
```

On every Route component, we push the route to the virtual history, and render the page content by calling the `renderPage` function. That way the Virtual History state is always up to date with the current route.
```reason
[@react.client.component]
let make =
    (~path: string, ~layout: React.element, ~page: option(React.element)) => {
  let (page, setPage) =
    React.useState(() => page |> Option.value(~default=React.null));

  let%browser_only renderPage = pageElement => setPage(_ => pageElement);

  (
    if (isFirstRender.current) {
      isFirstRender.current = false;
      VirtualHistory.push(~path, ~renderPage);
    }
  );

  <Provider
    value={page}>
    layout
  </Provider>;
};
```

## Dynamic Routes

Dynamic routes are routes that have a dynamic parameter, like "/students/:name". That allows us to render the same route with different content based on the dynamic parameter.
For example:

```reason
module StudentPage = {
  [@react.client.component]
  let make = (~dynamicParams: Router.DynamicParams.t) => {
    let name = Router.DynamicParams.find("name", dynamicParams);
    <div>
      <h1> "Student " ++ id </h1>
      <StudentContent />
    </div>
  };
};
```

The dynamic parameters can also be accessed in any client component by using the `Router.use` hook.
```reason
let {dynamicParams, ..._} = Router.use();
let name = Router.DynamicParams.find("name", dynamicParams);
```

## Router

To control the routes navigation, we need to use the `Router` component, which provides the dynamic params, url and navigation function to the application.
```reason
[@react.client.component]
let make = () => {
  let {navigate, dynamicParams, url, _} = Router.use();

  <div>
    <p> "Student Name: " ++ dynamicParams |> Router.DynamicParams.find("name") </p>
    <p> "URL: " ++ url |> Url.to_json </p>
    <button onClick={() => navigate("/students")}> "Navigate to Students" </button>
  </div>
};
```

### Navigation

The navigate function takes care of identifying the sub-route path to render the correct page content, so we request only the minimum required to render the page content.
Example:
```reason
// current route: /students
navigate(~to="/students/lola");
// Parent route: /students
// Sub-route: /lola
// Request: /students/lola?toSubRoute=/lola
```
In the sample above, the request is for the `/students/lola` route (In the server it falls into the `/students/:name` route) but we only want to render the `/lola` route, thats why we send the `toSubRoute` query param with the sub-route path. On the Dream handler, we split the target to get the sub-route path and the parent route path. In that case, the parent route path is `/students` and the sub-route path is `/:name`.
We then return the `/:name` route and update the Virtual History item `/students` to render the `/:name` route. Updating the Virtual History state to:
```reason
[
  {
    path: "/",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students",
    renderPage: (pageElement) => {...},
  },
  {
    path: "/students/:name",
    renderPage: (pageElement) => {...},
  },
]
```

## Route definitions

After knowing how the navigation works, we can now understand how to define the routes.

We declare the routes as a tree of routes, where each route can have a layout and a page.
```reason
type route = {
  path: string,
  layout: option(React.element),
  page: option(React.element),
  subRoutes: option(list(route)),
};

type routeDefinitionsTree = {
  mainLayout: React.element,
  mainPage: React.element,
  routes: list(route),
};

let routeDefinitionsTree = {
  mainLayout: <MainLayout />,
  mainPage: <MainPage />,
  routes: [
    {
      path: "/",
      layout: Some(<MainLayout />),
      page: Some(<MainPage />),
      subRoutes: Some([
        {
          path: "/students",
          layout: Some(<StudentsLayout />),
          page: Some(<StudentsPage />),
          subRoutes: Some([
            {
              path: "/students/:name",
              layout: None,
              page: Some(<StudentPage />),
              subRoutes: None,
            },
          ]),
        },
      ]),
    },
  ],
};
```

⚠️ The routeDefinitionsTree as the name suggests is a tree of routes, so it starts from a branch and goes down to the leaves, the main branch is the "/", so we don't need to define the "/" branch. Also, the MainLayout and MainPage are special as they don't have dynamic params.

It's from the route definitions tree that the Dream handler generates the routes paths and find which route to render based on the current path.
```reason
let routesPaths = [
  "/",
  "/students",
  "/students/:name",
];

let route = routes |> RouterRSC.getRoute(~request, ~definition="/students/:name", routes);
/** Result:
  <Route
    path="/"
    layout={<MainLayout />}
    page={
      Some(
        <Route
          path="/students"
          layout={<StudentsLayout />}
          page={
            Some(
              <Route
                path="/students/:name"
                layout={<PageConsumer />}
                page={Some(<StudentPage />)}
              />
            )
          }
        />
      )
    }
  />
*/
```


# IMPROVEMENTS

- Type safe routes (ppx_deriving_routes?)
- Loading state
- 404 state