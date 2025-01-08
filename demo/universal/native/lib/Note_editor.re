[@react.component]
let make = (~title: string, ~body: string) => {
  let (title, setTitle) = RR.useStateValue(title);
  let (body, setBody) = RR.useStateValue(body);

  let updateTitle = _event => {
    /* let value = React.Event.Form.target(event)##value; */
    let value = "33";
    setTitle(value);
  };

  let updateBody = _event => {
    /* let value = React.Event.Form.target(event)##value; */
    let value = "34";
    setBody(value);
  };

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
