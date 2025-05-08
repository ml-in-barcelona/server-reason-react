[@warning "-26-27-32"];

open Melange_json.Primitives;

external alert: string => unit = "window.alert";

[@react.client.component]
let make =
    (~noteId: option(int), ~initialTitle: string, ~initialBody: string) => {
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();
  let (title, setTitle) = RR.useStateValue(initialTitle);
  let (body, setBody) = RR.useStateValue(initialBody);
  let (isSaving, setIsSaving) = RR.useStateValue(false);
  let router = Router.useRouter();
  let (isNavigating, startNavigating) = React.useTransition();

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
      <div className="flex flex-row gap-2" role="menubar">
        <button
          className=Theme.button
          disabled={isSaving || isNavigating}
          onClick=[%browser_only
            _ => {
              let action =
                switch (noteId) {
                | Some(id) =>
                  ServerFunctions.Notes.edit.call(.
                    ~id,
                    ~title,
                    ~content=body,
                  )
                | None =>
                  ServerFunctions.Notes.create.call(. ~title, ~content=body)
                };

              action
              |> Js.Promise.then_((result: Note.t) => {
                   let id = result.id;
                   navigate({
                     selectedId: Some(id),
                     isEditing: false,
                     searchText: None,
                   });
                   Js.Promise.resolve();
                 })
              |> ignore;
            }
          ]
          role="menuitem">
          {React.string("Done")}
        </button>
        {switch (noteId) {
         | Some(id) => <DeleteNoteButton noteId=id />
         | None => React.null
         }}
      </div>
      <NotePreview key="note-preview" body />
    </div>
  </div>;
};
