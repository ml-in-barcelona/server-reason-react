module Cosis = {
  [@react.component]
  let make = (~onClick) => {
    <div
      onClick={_ => {
        Js.log("asdfs");
        onClick();
      }}
    />;
  };
};

let%browser_only getStorage = () => Dom.Storage.localStorage;

[@react.component]
let make = () => {
  let%browser_only onClick = _event => {
    Js.log("Click on account button");
  };

  React.useEffect0(() => {
    open Webapi.Dom;
    let randomElement = Document.getElementById("randomId", document);
    switch (randomElement) {
    | None => ()
    | Some(stylesheetEl) =>
      let version =
        Element.getAttribute("data-version", stylesheetEl)
        ->Belt.Option.getWithDefault("");
      Element.setAttribute(
        "href",
        Printf.sprintf("/assets/css/%s-palette.css%s", "dark", version),
        stylesheetEl,
      );
    };

    None;
  });

  <div className="flex items-center justify-between gap-24">
    <form className="flex items-center gap-4 m-0">
      <label className="text-white flex items-center gap-4">
        {React.string("Name ")}
        <input
          className="text-black"
          onKeyPress=[%browser_only
            _ => {
              Js.log("key pressed");
            }
          ]
          type_="text"
          name="name"
        />
        <input
          className="text-white text-m font-bold py px-2 border rounded"
          type_="submit"
          value="Submit"
        />
      </label>
    </form>
    <button className="text-white font-bold py px-2 rounded border" onClick>
      {React.string("Account")}
    </button>
  </div>;
};
