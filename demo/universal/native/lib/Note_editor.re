[@warning "-27"];
open React;

[@react.component]
let make = (~title: string, ~body: string) => {
  let (title, setTitle) = useState(() => title);
  let (body, setBody) = useState(() => body);

  let%browser_only updateTitle = event => {
    Js.log("UPDATE TITLE");
    let value = Event.Form.target(event)##value;
    setTitle(_ => value);
  };

  let%browser_only updateBody = event => {
    Js.log("UPDATE BODY");
    let value = Event.Form.target(event)##value;
    setBody(_ => value ++ "!");
  };

  let submit = _ => {
    Js.log("SUBMIT!");
  };

  <form className="flex gap-4" action="/" onSubmit=submit>
    <input
      className="border-2 rounded-md p-2 border-gray-700 bg-transparent text-gray-200"
      name="title"
      onChange=updateTitle
      value=title
    />
    <input
      className="border-2 rounded-md p-2 border-gray-700 bg-transparent text-gray-200"
      name="body"
      onChange=updateBody
      value=body
    />
  </form>;
};

switch%platform (Runtime.platform) {
| Server => ()
| Client =>
  Components.register("Note_editor", (props: Js.t({..})) =>
    React.jsx(make, makeProps(~title=props##title, ~body=props##body, ()))
  )
};
