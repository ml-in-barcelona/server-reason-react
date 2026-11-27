[@cache {tags: ["all"]}]
let request = (~id: int): Lwt.t(string) => Lwt.return(string_of_int(id));

[@cache {ttl: 30.}]
let ttl_only = (~id: int): Lwt.t(string) => Lwt.return(string_of_int(id));

[@cache {max: 5}]
let max_only = (~id: int): Lwt.t(string) => Lwt.return(string_of_int(id));
