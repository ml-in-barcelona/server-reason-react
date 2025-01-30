[@react.component]
let make = (~active) => {
  <div
    role="progressbar"
    ariaBusy=true
    className={
      "inline-block w-5 h-5 rounded-full border-3 border-gray-500/50 border-t-white transition-opacity duration-100 linear "
      ++ (active ? "opacity-100 animate-spin" : "opacity-0")
    }
  />;
};
