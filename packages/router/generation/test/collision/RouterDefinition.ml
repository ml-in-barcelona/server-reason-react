Router.make ~basePath:"/"
  [
    Router.route Fun ~page:Pages.Plain ~path:"/fun";
    Router.route Stdlib ~page:Pages.Plain ~path:"/stdlib";
    Router.route RouterRuntime ~page:Pages.Plain ~path:"/router-runtime";
    Router.route RouterReact ~page:Pages.Plain ~path:"/router-react";
    Router.route RouterServer ~page:Pages.Plain ~path:"/router-server";
    Router.route RSC ~page:Pages.Plain ~path:"/rsc";
    Router.route React ~page:Pages.Plain ~path:"/react";
    Router.route Js ~page:Pages.Plain ~path:"/js";
    Router.route List ~page:Pages.Plain ~path:"/list";
    Router.route Array ~page:Pages.Plain ~path:"/array";
    Router.route ReactDOM ~page:Pages.Plain ~path:"/react-dom";
    Router.route Search ~page:Pages.Plain ~path:"/search";
    Router.route Link ~page:Pages.Plain ~path:"/link";
    Router.route NoteId ~page:Pages.Plain ~path:"/note-id";
    Router.route Note ~page:Pages.Note
      ~path:"/n/:id<NoteId.t>/:searchValues<int>/:tryDestination<int>/:pattern<string>/:input<string>/:value<int>"
      ~search:{ q = Router.Search.optional string }
      ~loader:Pages.NoteLoader ~loaderLabel:routeSearch;
    Router.route Page ~page:Pages.Page ~path:"/p/:max_int<int>" ~search:{ limit = Router.Search.default int max_int };
  ]
