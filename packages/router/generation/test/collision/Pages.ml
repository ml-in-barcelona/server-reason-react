module Plain = struct
  let[@react.component] make () = React.string "plain"
end

module NoteLoader = struct
  let load ~id ~searchValues ~tryDestination ~pattern ~input ~value ~search:_ () :
      (string, string) RouterRuntime.Loader.result Lwt.t =
    Lwt.return
      (RouterRuntime.Loader.Data
         (String.concat ","
            [
              NoteId.to_string id;
              string_of_int searchValues;
              string_of_int tryDestination;
              pattern;
              input;
              string_of_int value;
            ]))
end

module Note = struct
  let[@react.component] make ~id:_ ~searchValues:_ ~tryDestination:_ ~pattern:_ ~input:_ ~value:_ ~search:_
      ~(routeSearch : string) () =
    React.string routeSearch
end

module Page = struct
  let[@react.component] make ~(max_int : int) ~(search : Router.Page.search) () =
    React.string (string_of_int max_int ^ ":" ^ string_of_int search.limit)
end
