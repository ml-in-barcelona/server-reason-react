[@platform native]
module Client_component = {
  let make = (~title: string, ~body: string, ()) =>
    React.Client_component({
      import_module: "Note_editor",
      import_name: "make",
      props: [
        ("title", React.Json(`String(title))),
        ("body", React.Json(`String(body))),
      ],
      client: React.null,
    });
};

[@platform js]
module Client_component = {
  [@react.component]
  let make = (~title: string, ~body: string) => {
    let (title, setTitle) = RR.useStateValue(title);
    let (body, setBody) = RR.useStateValue(body);

    let%browser_only updateTitle = event => {
      let value = React.Event.Form.target(event)##value;
      setTitle(value);
    };

    let%browser_only updateBody = event => {
      let value = React.Event.Form.target(event)##value;
      setBody(value);
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
};

include Client_component;

switch%platform (Runtime.platform) {
| Server => ()
| Client =>
  Components.register("Note_editor", (props: Js.t({..})) =>
    React.jsx(make, makeProps(~title=props##title, ~body=props##body, ()))
  )
};