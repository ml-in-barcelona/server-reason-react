let f = () => {
  [@cache]
  let viewer = (~id: int): Lwt.t(string) => Lwt.return(string_of_int(id));
  viewer(~id=1);
};
