let _ : string =
  SearchNames.Inspector.href
    ~search:
      {
        revalidate = None;
        updateSearch = None;
        target = "example.com";
        error = Some "e";
        input = "all";
        hash = [ "a" ];
        value = 1;
        pattern = None;
      }
    ~hash:"top" ()

let _ : string = SearchNames.Note.href ~id:1 ~search:(SearchNames.Note.search ~id:"x" ()) ()
let _ : SearchNames.destination = SearchNames.Note.destination ~id:2 ()

let update (search : SearchNames.search) =
  let _, updateSearch = SearchNames.useSearch () in
  updateSearch { search with revalidate = Some "1" }
