type align = [ | `start | `center | `end_];
type justify = [ | `around | `between | `evenly | `start | `center | `end_];

module Media = {
  let onDesktop = rules => {
    String.concat(" md:", rules);
  };
};

module Color = {
  let brokenWhite = "[#a0a0a0]";
  let white = "[#eaecee]";
  let yellow = white;
  let darkYellow = "[#34342f]";
  let black = "[#161615]";

  let reason = "[#db4d3f]";
  let react = "[#149eca]";
  let ahrefs = "[#ff8800]";
};

let text = value => "text-" ++ value;
let background = value => "bg-" ++ value;

let hover = value => "hover:" ++ String.concat(" hover:", value);
