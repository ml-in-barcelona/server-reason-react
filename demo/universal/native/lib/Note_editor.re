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
      className={Cx.make([
        "flex-1 border-2 rounded-md p-2 border-gray-700 bg-transparent",
        Theme.border(Theme.Color.Gray7),
        Theme.text(Theme.Color.Gray2),
      ])}
      name="title"
      onChange=updateTitle
      value=title
    />
    <input
      className={Cx.make([
        "flex-1 border-2 rounded-md p-2 border-gray-700 bg-transparent",
        Theme.border(Theme.Color.Gray7),
        Theme.text(Theme.Color.Gray2),
      ])}
      name="body"
      onChange=updateBody
      value=body
    />
  </form>;
};
