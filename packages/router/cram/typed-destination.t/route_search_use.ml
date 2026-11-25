let next () =
  let search, updateSearch = RouteSearch.Results.useSearch () in
  updateSearch ~history:RouteSearch.Navigation.Replace { search with page = search.page + 1 }
