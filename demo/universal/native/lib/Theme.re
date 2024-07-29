type align = [ | `start | `center | `end_];
type justify = [ | `around | `between | `evenly | `start | `center | `end_];

module Media = {
  let onDesktop = rules => {
    String.concat(" md:", rules);
  };
};

module Color = {
  let white = "white";
  let yellow = "yellow-600";
  let darkYellow = "yellow-800";
  let white01 = "slate-800";
  let black = "black";
  let reason = "[#db4d3f]";
  let react = "[#149eca]";
  let ahrefs = "[#ff8800]";
  let lightGrey = "[#c1c5cd]";
  let darkGrey = "[#292a2d]";
  let box = "[#2e3c56]";
  let brokenWhite = "[#eaecee]";
};

let text = value => "text-" ++ value;
let background = value => "bg-" ++ value;

let hover = value => "hover:" ++ String.concat(" hover:", value);
