module CSS = {
  let className = ((c, _)) => c;
  let make = (c, _) => (c, ());
  let merge = ((a, _), (b, _)) => (a ++ " " ++ b, ());
};
let element = <div className="a" className="b" />;
