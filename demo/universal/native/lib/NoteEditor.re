[@warning "-26-27-32"];

open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make =
    (~noteId: option(int), ~initialTitle: string, ~initialBody: string) => {
  let (title, setTitle) = RR.useStateValue(initialTitle);
  let (body, setBody) = RR.useStateValue(initialBody);
  let router = Router.useRouter();
  let (isNavigating, _startNavigating) = React.useTransition();

  let endpoint =
    switch (noteId) {
    | Some(id) => "/notes/" ++ Int.to_string(id)
    | None => "/notes"
    };

  let method_ =
    switch (noteId) {
    | Some(_) => "PUT"
    | None => "POST"
    };

  let (saveNote, isSaving) = router.useAction(endpoint, method_);

  let (deleteNote, isDeleting) =
    router.useAction(
      switch (noteId) {
      | Some(id) => "/notes/" ++ Int.to_string(id)
      | None => "/notes"
      },
      "DELETE",
    );

  let%browser_only handleSave = () => {
    let payload: Router.payload = {
      title,
      body,
    };
    let requestedLocation: Router.location = {
      selectedId: noteId,
      isEditing: false,
      searchText: router.location.searchText,
    };
    Js.log(requestedLocation);
    Js.log(saveNote);
    saveNote(payload, requestedLocation, ());
  };

  let handleDelete = () => {
    let payload: Router.payload = {
      title: "",
      body: "",
    };
    let requestedLocation: Router.location = {
      selectedId: None,
      isEditing: false,
      searchText: router.location.searchText,
    };
    deleteNote(payload, requestedLocation, ());
  };

  let isDraft = Belt.Option.isNone(noteId);

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
          onClick={_ => handleSave()}
          role="menuitem">
          {React.string("Done")}
        </button>
        {!isDraft
           ? <button
               className=Theme.button
               disabled={isDeleting || isNavigating}
               onClick={_ => handleDelete()}
               role="menuitem">
               {React.string("Delete")}
             </button>
           : React.null}
      </div>
      <NotePreview key="note-preview" body />
    </div>
  </div>;
};
