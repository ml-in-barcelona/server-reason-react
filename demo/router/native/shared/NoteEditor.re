[@react.client.component]
let make =
    (~id: option(NoteId.t), ~initialTitle: string, ~initialBody: string) => {
  let (navigate, navigation) = Router.useNavigation();
  let { Router.searchText } = Router.useSearch();
  let (title, setTitle) = RR.useStateValue(initialTitle);
  let (body, setBody) = RR.useStateValue(initialBody);
  let isNavigating =
    switch (navigation) {
    | Router.Navigation.Loading(_) => true
    | Router.Navigation.Idle
    | Router.Navigation.Failed(_) => false
    };

  let%browser_only onChangeTitle = e => {
    let newValue = React.Event.Form.target(e)##value;
    setTitle(newValue);
  };

  let%browser_only onChangeBody = e => {
    let newValue = React.Event.Form.target(e)##value;
    setBody(newValue);
  };

  <div className="flex flex-col gap-4">
    <form
      className="flex flex-col gap-2"
      autoComplete="off"
      onSubmit={e => React.Event.Form.preventDefault(e)}>
      <InputText value=title onChange=onChangeTitle />
      <Textarea rows=10 value=body onChange=onChangeBody />
    </form>
    <div className="flex flex-col gap-4">
      <div className="flex flex-row gap-2">
        <button
          className=Theme.button
          disabled=isNavigating
          onClick=[%browser_only
            _ => {
              let action =
                switch (id) {
                | Some(id) =>
                  ServerFunctions.Notes.edit.call(
                    ~id=NoteId.toInt(id),
                    ~title,
                    ~content=body,
                  )
                | None =>
                  ServerFunctions.Notes.create.call(~title, ~content=body)
                };

              action
              |> Js.Promise.then_((result: Note.t) => {
                   switch (navigate) {
                   | Some(navigate) =>
                     navigate(
                       ~revalidate=true,
                       Router.Note.destination(
                         ~id=NoteId.ofInt(result.id),
                         ~searchText?,
                         (),
                       ),
                     )
                     |> ignore
                   | None => ()
                   };
                   Js.Promise.resolve();
                 })
              |> ignore;
            }
          ]>
          {React.string("Done")}
        </button>
        {switch (id) {
         | Some(id) => <DeleteNoteButton id />
         | None => React.null
         }}
      </div>
      <NotePreview key="note-preview" body />
    </div>
  </div>;
};
