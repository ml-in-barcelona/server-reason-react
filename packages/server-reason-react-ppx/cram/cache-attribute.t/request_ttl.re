[@cache {ttl: 1.}]
let viewer = (~id: int): Lwt.t(string) => Lwt.return(string_of_int(id));
