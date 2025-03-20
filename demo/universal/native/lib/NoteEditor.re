[@warning "-26-27-32"];

open Ppx_deriving_json_runtime.Primitives;

external alert: string => unit = "window.alert";

// This would be created by a ppx
// Making sure to encode the args correctly
let%browser_only createNote = (~title, ~content) => {
  let currentURL = Router.demoActionCreateNote;
  let encodeArgs =
    "{"
    ++ String.concat(
         ",",
         List.map(
           ((key, value)) => key ++ ":" ++ value,
           [
             (
               "title",
               // This to_string and string_to_json is not necessary
               // I'm just simulating encoding args
               Ppx_deriving_json_runtime.to_string(string_to_json(title)),
             ),
             // This to_string and string_to_json is not necessary
             // I'm just simulating encoding args
             (
               "content",
               Ppx_deriving_json_runtime.to_string(string_to_json(content)),
             ),
           ],
         ),
       )
    ++ "}";
  FetchHelpers.fetchAction(currentURL, encodeArgs);
};

// This would be created by a ppx
// Making sure to encode the args correctly
let%browser_only editNote = (~id, ~title, ~content) => {
  let currentURL = Router.demoActionEditNote;
  let encodeArgs =
    "{"
    ++ String.concat(
         ",",
         List.map(
           ((key, value)) => key ++ ":" ++ value,
           [
             ("id", Ppx_deriving_json_runtime.to_string(int_to_json(id))),
             (
               "title",
               Ppx_deriving_json_runtime.to_string(string_to_json(title)),
             ),
             (
               "content",
               Ppx_deriving_json_runtime.to_string(string_to_json(content)),
             ),
           ],
         ),
       )
    ++ "}";
  FetchHelpers.fetchAction(currentURL, encodeArgs);
};

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
              let action = () =>
                switch (noteId) {
                | Some(id) => editNote(~id, ~title, ~content=body)
                | None => createNote(~title, ~content=body)
                };

              action()
              |> Js.Promise.then_((note: Note.t) => {
                   navigate({
                     selectedId: Some(note.id),
                     isEditing: false,
                     searchText: router.location.searchText,
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
