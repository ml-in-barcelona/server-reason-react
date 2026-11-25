let _ : string =
  SearchKeyAlias.Inspector.href
    ~search:{ infoPage = Some "x"; siteTarget = Some "example.com"; target = "all"; kind = "user"; tags = [ 1 ] }
    ()

let update (search : SearchKeyAlias.Inspector.search) =
  let _, updateSearch = SearchKeyAlias.Inspector.useSearch () in
  updateSearch { search with siteTarget = Some "example.org" }
