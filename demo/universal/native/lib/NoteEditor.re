[@react.component]
let make =
    (~noteId: option(int), ~initialTitle: string, ~initialBody: string) => {
  ignore(noteId);
  ignore(initialTitle);
  ignore(initialBody);
  React.null;
  /*   let (title, setTitle) = React.useState(() => initialTitle);
       let (body, setBody) = React.useState(() => initialBody);
       let router = Router.useRouter();
       let (isNavigating, _startNavigating) = React.useTransition();

       let endpoint = switch (noteId) {
       | Some(id) => "/notes/" ++ id
       | None => "/notes"
       };

       let method = switch (noteId) {
       | Some(_) => "PUT"
       | None => "POST"
       }

       let (saveNote, isSaving) = useMutation({
         "endpoint": endpoint,
         "method": method
       })

       let (deleteNote, isDeleting) = useMutation({
         "endpoint": switch noteId {
         | Some(id) => "/notes/" ++ id
         | None => "/notes"
         },
         "method": "DELETE"
       })

       let handleSave = () => {
         let payload = {
           "title": title,
           "body": body
         }
         let requestedLocation = {
           "selectedId": Js.Nullable.fromOption(noteId),
           "isEditing": false,
           "searchText": router##location##searchText
         }
         saveNote(payload, requestedLocation)->ignore
       }

       let handleDelete = () => {
         let payload = {
           "title": "",
           "body": ""
         }
         let requestedLocation = {
           "selectedId": Js.Nullable.null,
           "isEditing": false,
           "searchText": router##location##searchText
         }
         deleteNote(payload, requestedLocation)->ignore
       }

       let isDraft = Belt.Option.isNone(noteId)

       <div className="note-editor">
         <form
           className="note-editor-form"
           autoComplete="off"
           onSubmit={e => ReactEvent.Form.preventDefault(e)}>
           <label className="offscreen" htmlFor="note-title-input">
             {React.string("Enter a title for your note")}
           </label>
           <input
             id="note-title-input"
             type_="text"
             value=title
             onChange={e => setTitle(ReactEvent.Form.target(e)##value)}
           />
           <label className="offscreen" htmlFor="note-body-input">
             {React.string("Enter the body for your note")}
           </label>
           <textarea
             id="note-body-input"
             value=body
             onChange={e => setBody(ReactEvent.Form.target(e)##value)}
           />
         </form>
         <div className="note-editor-preview">
           <div className="note-editor-menu" role="menubar">
             <button
               className="note-editor-done"
               disabled={isSaving || isNavigating}
               onClick={_ => handleSave()}
               role="menuitem">
               <img
                 src="checkmark.svg"
                 width="14px"
                 height="10px"
                 alt=""
                 role="presentation"
               />
               {React.string("Done")}
             </button>
             {!isDraft ?
               <button
                 className="note-editor-delete"
                 disabled={isDeleting || isNavigating}
                 onClick={_ => handleDelete()}
                 role="menuitem">
                 <img
                   src="cross.svg"
                   width="10px"
                   height="10px"
                   alt=""
                   role="presentation"
                 />
                 {React.string("Delete")}
               </button>
               : React.null}
           </div>
           <div className="label label--preview" role="status">
             {React.string("Preview")}
           </div>
           <h1 className="note-title"> {React.string(title)} </h1>
           <NotePreview title body />
         </div>
       </div>; */
};
