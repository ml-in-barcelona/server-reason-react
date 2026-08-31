[@react.client.component]
let make = () => {
  let route = Router.useRoute();
  let ({ Router.text }, _) = Router.useSearch();
  let (navigate, _) = Router.useNavigation();
  let routerText = text |> Option.value(~default="");
  let (text, setText) = RR.useStateValue(routerText);
  let (_, startSearching) = React.useTransition();

  React.useEffect1(
    () => {
      setText(routerText);
      None;
    },
    [|routerText|],
  );

  let%browser_only installNavigation = onNavigate => {
    let install: (string => unit, unit) => unit = [%mel.raw
      {js|(onNavigate) => {
        const handler = (event) => {
          if (event.defaultPrevented || event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
          const anchor = event.target.closest && event.target.closest("a[href]");
          if (!anchor || anchor.hasAttribute("download") || (anchor.target && anchor.target !== "_self")) return;
          const url = new URL(anchor.href, window.location.href);
          if (url.origin !== window.location.origin || (url.pathname !== "/demo/hacker-news" && !url.pathname.startsWith("/demo/hacker-news/"))) return;
          event.preventDefault();
          onNavigate(url.pathname + url.search + url.hash);
        };
        document.addEventListener("click", handler);
        return () => document.removeEventListener("click", handler);
      }|js}
    ];
    Some(install(onNavigate));
  };

  React.useEffect(() =>
    installNavigation(href => {
      navigate(Router.unsafeDestination(href)) |> ignore
    })
  );

  let%browser_only toggleTheme = () => {
    let run: unit => unit = [%mel.raw
      {js|() => {
        const root = document.documentElement;
        const next = root.dataset.hnTheme === "dark" ? "light" : "dark";
        root.dataset.hnTheme = next;
        try { localStorage.setItem("hn-theme", next); } catch (_) {}
      }|js}
    ];
    run();
  };

  let%browser_only onChange = event =>
    setText(React.Event.Form.target(event)##value);

  let%browser_only onSubmit = event => {
    React.Event.Form.preventDefault(event);
    let text = text == "" ? None : Some(text);
    let destination =
      switch (route) {
      | Some(Router.New) => Router.New.destination(~text?, ())
      | Some(Router.Best) => Router.Best.destination(~text?, ())
      | Some(Router.Ask) => Router.Ask.destination(~text?, ())
      | Some(Router.Show) => Router.Show.destination(~text?, ())
      | Some(Router.Jobs) => Router.Jobs.destination(~text?, ())
      | Some(Router.Top)
      | Some(Router.Story(_))
      | None => Router.Top.destination(~text?, ())
      };
    startSearching(() => navigate(destination) |> ignore);
  };

  <header className="hn-header">
    <div className="hn-header-inner">
      <Router.Top className="hn-brand">
        <span className="hn-brand-label"> {React.string("HN in RSC")} </span>
        <span className="hn-brand-subtitle">
          {React.string("server-reason-react")}
        </span>
      </Router.Top>
      <nav className="hn-nav" ariaLabel="Hacker News feeds">
        <Router.Top
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.Top) ? "page" : "false"}>
          {React.string("top.md")}
        </Router.Top>
        <Router.New
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.New) ? "page" : "false"}>
          {React.string("new.md")}
        </Router.New>
        <Router.Best
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.Best) ? "page" : "false"}>
          {React.string("best.md")}
        </Router.Best>
        <Router.Ask
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.Ask) ? "page" : "false"}>
          {React.string("ask.md")}
        </Router.Ask>
        <Router.Show
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.Show) ? "page" : "false"}>
          {React.string("show.md")}
        </Router.Show>
        <Router.Jobs
          className="hn-nav-link"
          ariaCurrent={route == Some(Router.Jobs) ? "page" : "false"}>
          {React.string("jobs.md")}
        </Router.Jobs>
      </nav>
      <div className="hn-tools">
        <form className="hn-search" role="search" onSubmit>
          <label className="sr-only" htmlFor="hn-search-input">
            {React.string("Search Hacker News")}
          </label>
          <span className="hn-search-icon" ariaHidden=true />
          <input
            id="hn-search-input"
            type_="search"
            placeholder="search stories..."
            value=text
            onChange
          />
        </form>
        <button
          type_="button"
          className="hn-theme-toggle"
          ariaLabel="Toggle color theme"
          onClick={_ => toggleTheme()}>
          <span className="hn-theme-light" ariaHidden=true />
          <span className="hn-theme-dark" ariaHidden=true />
        </button>
      </div>
    </div>
  </header>;
};
