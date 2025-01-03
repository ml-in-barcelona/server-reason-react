[@warning "-27"];

let make = (~title: string, ~body: string) => {
  let (title, setTitle) = RR.useStateValue(title);
  let (body, setBody) = RR.useStateValue(body);

  [@browser_only]
  let updateTitle = event => {
    let value = React.Event.Form.target(event)##value;
    setTitle(value);
  };

  [@browser_only]
  let updateBody = event => {
    let value = React.Event.Form.target(event)##value;
    setBody(value);
  };

  [@browser_only]
  let submit = _ => {
    Js.log("SUBMIT!");
  };

  <form className="flex gap-4 flex-wrap w-full" action="/" onSubmit=submit>
    <input
      className="flex-1 border-2 rounded-md p-2 border-gray-700 bg-transparent text-gray-200"
      name="title"
      onChange=updateTitle
      value=title
    />
    <input
      className="flex-1 border-2 rounded-md p-2 border-gray-700 bg-transparent text-gray-200"
      name="body"
      onChange=updateBody
      value=body
    />
  </form>;
};

[@react.component]
let make = (~title, ~body) =>
  switch%platform (Runtime.platform) {
  | Server =>
    React.Client_component({
      import_module: "Note_editor",
      import_name: "",
      props: [
        ("title", React.Json(`String(title))),
        ("body", React.Json(`String(body))),
      ],
      client: make(~title, ~body),
    })
  | Client => make(~title, ~body)
  };

let default = make;
