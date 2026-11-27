[@deriving rsc]
type filter = {
  term: string,
  page: int,
};

let calls = ref(0);

[@cache]
let viewer = (~id: int, ()): Lwt.t(string) => {
  incr(calls);
  Lwt.return("viewer-" ++ string_of_int(id));
};

[@cache {ttl: 30., max: 10, tags: [`User(id)]}]
let appearance = (~id: int, ~logger as _: string => unit): Lwt.t(string) => {
  incr(calls);
  Lwt.return("dark-" ++ string_of_int(id));
};

module Search = {
  [@cache {errors: Retry}]
  let results = (filter: filter, ~limit: option(int)=?, (): unit): Lwt.t(list(string)) => {
    incr(calls);
    Lwt.return([filter.term, string_of_int(filter.page), Option.fold(~none="", ~some=string_of_int, limit)]);
  };
};

[@cache {key: "all"}]
let everything = (~a: string): Lwt.t(string) => {
  incr(calls);
  Lwt.return(a);
};

let () =
  Lwt_main.run(
    React.Cache.request_scope(() => {
      let%lwt _ = viewer(~id=1, ());
      let%lwt _ = viewer(~id=1, ());
      let%lwt _ = viewer(~id=2, ());
      let%lwt _ = appearance(~id=1, ~logger=ignore);
      let%lwt _ = appearance(~id=1, ~logger=print_endline);
      React.Cache.expire(~tag=`User(1));
      let%lwt _ = appearance(~id=1, ~logger=ignore);
      let%lwt _ = Search.results({term: "a", page: 1}, ());
      let%lwt _ = Search.results({term: "a", page: 1}, ());
      let%lwt _ = Search.results({term: "a", page: 1}, ~limit=5, ());
      let%lwt _ = everything(~a="x");
      let%lwt b = everything(~a="y");
      print_endline("everything: " ++ b);
      print_endline("calls: " ++ string_of_int(calls^));
      Lwt.return();
    }),
  );
