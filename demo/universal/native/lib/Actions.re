module Notes = {
  [@platform native]
  let createNoteResponse = note => {
    Note.(
      `Assoc([
        ("id", `Int(note.id)),
        ("title", `String(note.title)),
        ("content", `String(note.content)),
        ("updated_at", `Float(note.updated_at)),
      ])
    );
  };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let createHandler = (~title, ~content) => {
      let note = DB.addNote(~title, ~content);
      let%lwt response =
        switch%lwt (note) {
        | Ok(note) => Lwt.return(createNoteResponse(note))
        | Error(e) => failwith(e)
        };
      Lwt.return(response);
    };
   */
  // It's going to be on top to this that we are going to generate the codes bellow
  let createId = "id/notes/create";

  [@platform native]
  let createHandler = (~title, ~content) => {
    let note = DB.addNote(~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(createNoteResponse(note))
      | Error(e) => failwith(e)
      };
    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let createRouteHandler = args => {
    // Parse the body to get the args
    let (title, content) =
      switch (args) {
      | [title, content] => (
          // It would be handle by a title_of_json/content_of_json in the future provided by the end-user and the ppx
          title |> Yojson.Basic.Util.to_string,
          content |> Yojson.Basic.Util.to_string,
        )
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    createHandler(~title, ~content);
  };

  // This is the action generated to be used under the hood for the server and client
  let create =
    switch%platform () {
    | Server => createHandler
    | Client => (
        (~title, ~content) => {
          // Register the action for the client
          let action =
            ReactServerDOMWebpack.createServerReference(
              createId,
              Some("create"),
            );
          /**
            Under the hoods if we call action(id, title, content), melange will do this:
                function create(title, content) {
                  var action = ReactServerDOMWebpack.createServerReference(createId, "create");
                  return Curry._2(action, title, content);
                }

            But action is a function that is provided by react without the args defined, something like this function action () => {...}. Cause it get the args as a list using `arguments` keyword.
            Ref: https://github.com/facebook/react/blob/2398554c6034e6d0992fcaa1c2e95f1757cab53e/packages/react-client/src/ReactFlightReplyClient.js#L1366-L1370
            As the arg is not defined, the function will be called with only the first one, as you can see here in this playground:
            https://melange.re/unstable/playground/?language=Reason&code=LyoKSW4gdGhpcyBwbGF5Z3JvdW5kIEknbSBzaW11bGF0aW5nIGEgYmVoYXZpb3Igb2YgYSBpc3N1ZSB0aGF0IEkgZmFjZWQgd2l0aCBhIGJpbmRpbmcuIAoKTW9yZSBzcGVjaWZpYywgdGhpcyBvbmU6CltAbWVsLm1vZHVsZSAicmVhY3Qtc2VydmVyLWRvbS13ZWJwYWNrL2NsaWVudCJdCmV4dGVybmFsIGNyZWF0ZVNlcnZlclJlZmVyZW5jZUltcGw6CiAgKAogICAgLy8gU2VydmVyUmVmZXJlbmNlSWQKICAgIHN0cmluZywKICAgIC8vIENhbGxTZXJ2ZXJDYWxsYmFjawogICAgY2FsbFNlcnZlckNhbGxiYWNrKCdhLCAnYiksIAogICAgLy8gRW5jb2RlRm9ybUFjdGlvbkNhbGxiYWNrIChvcHRpb25hbCkKICAgIG9wdGlvbigoJ2EsICdiKSA9PiBlbmNvZGVGb3JtQWN0aW9uKSwKICAgIC8vIEZpbmRTb3VyY2VNYXBVUkxDYWxsYmFjayAob3B0aW9uYWwsIERFVi1vbmx5KQogICAgb3B0aW9uKCdlID0%2BIHN0cmluZyksCiAgICAvLyBmdW5jdGlvbk5hbWUgKG9wdGlvbmFsKQogICAgb3B0aW9uKHN0cmluZykKICApID0%2BCiAgJ2YgPQogICJjcmVhdGVTZXJ2ZXJSZWZlcmVuY2UiOwoqLwpbJSVtZWwucmF3CiAge3wKICBmdW5jdGlvbiBnZXRMb2dBcmdzSW1wbCgpIHsKICAgICAgICAgIHZhciBhcmdzID0gQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoYXJndW1lbnRzKTsKICAgICAgICAgIHJldHVybiBhcmdzCiAgICAgICAgfQp8fQpdOwoKLy8gVGhpcyBpcyBqdXN0IHRvIHNpbXVsYXRlIHRoZSBjYXNlIHRoYXQgd2UgaGF2ZSBhcyB1c2luZyBleHRlcm5hbApleHRlcm5hbCBnZXRMb2dBcmdzOiB1bml0ID0%2BICdmID0gImdldExvZ0FyZ3NJbXBsIjsKCi8vIExvZ2dpbmcgdGhlIHJlZmVyZW5jZSB0byBzaG93IHRoYXQgaXMgMApsZXQgXyA9IFslbWVsLnJhdyAiY29uc29sZS5sb2coJ0FjdGlvbiBhcml0eTonLCBsb2dBcmdzLmxlbmd0aCkiXQpsZXQgbG9nQXJncyA9IGdldExvZ0FyZ3MoKTsKCi8vIEknbSBub3QgcmVjZWl2aW5nIHRoaXMgd2FybmluZyBvbiB0aGUgc2VydmVyLXJlYXNvbi1yZWFjdCBkZW1vLiBXaHk%2FCi8vIEJ1dCBsZXRzIGNhbGwgYWN0aW9uIGFuZCBzZWUgdGhlIGxvZyB0aGF0IHdlIGhhdmUKdHJ5IChsb2dBcmdzKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSkgewogfCBfID0%2BICgpCn0KLyogCk9uIGNhbGxpbmcgYWN0aW9uKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSwgaXQgd2lsbCBiZSB0cmFuc2Zvcm0gaW50bzoKQ3VycnkuXzMoYWN0aW9uLCAxLCAiU29tZSB0aXRsZSIsICJTb21lIGRlc2NyaXB0aW9uIik7CkFuZCBDdXJyeSB1bmRlciB0aGUgaG9vZHMgaXM6CgpmdW5jdGlvbiBfMyhvLCBhMCwgYTEsIGEyKSB7CiAgdmFyIGFyaXR5ID0gby5sZW5ndGg7CiAgaWYgKGFyaXR5ID09PSAzKSB7CiAgICByZXR1cm4gbyhhMCwgYTEsIGEyKTsKICB9IGVsc2UgewogICAgc3dpdGNoIChhcml0eSkgewogICAgICAuLi4KICAgICAgZGVmYXVsdDoKICAgICAgICByZXR1cm4gYXBwKG8sIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKICAgIH0KICB9Cn0KClRoZSBwcm9ibGVtYSBpcyB0aGF0IHRoZSBhcml0eSBvZiBhIGZ1bmN0aW9uIHRoYXQgaXMgKC4uLmFyZ3MpID0%2BIHsuLi59IGlzIDAKVGhlbiB3ZSBmYWxsIGludG8gdGhlIGFwcCBmdW5jdGlvbgoKZnVuY3Rpb24gYXBwKF9mLCBfYXJncykgewogIHdoaWxlKHRydWUpIHsKICAgIHZhciBhcmdzID0gX2FyZ3M7CiAgICB2YXIgZiA9IF9mOwogICAgdmFyIGluaXRfYXJpdHkgPSBmLmxlbmd0aDsKICAgIC8vIFRoZSBhcml0eSB2YWx1ZSB3aWxsIGJlIDAgY2F1c2UgaW5pdF9hcml0eSBpcyAwCiAgICB2YXIgYXJpdHkgPSBpbml0X2FyaXR5ID09PSAwID8gMSA6IGluaXRfYXJpdHk7IAogICAgdmFyIGxlbiA9IGFyZ3MubGVuZ3RoOwogICAgLy8gQVRFTlRJT04gSEVSRTogYXMgYXJpdHkgaXMgMSB0aGUgbGVuIHdpbGwgYmUgLTIKICAgIHZhciBkID0gYXJpdHkgLSBsZW4gfCAwOyAKICAgIGlmIChkID09PSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBpZiAoZCA%2BPSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBfYXJncyA9IENhbWxfYXJyYXkuc3ViKGFyZ3MsIGFyaXR5LCAtZCB8IDApOwogICAgLy8gSW4gdGhpcyBmaXJzdCBsb29wIHdpbGwgZmFsbCBpbnRvIHRoaXMsIGFuZCB0aGUgcHJvYmxlbSBpcyB0aGF0IHRoZSBhcHBseSBmdW5jdGlvbiB3aWxsIGNhbGwKICAgIC8vIHRoZSBmdW5jdGlvbiwgaW4gb3VyIGNhc2UsIHRoZSBmdW5jdGlvbiB3aWxsIGJlIGNhbGxlZCB3aXRoIFsxXSBhcyB5b3UgY2FuIHNlZSBvbiBjb25zb2xlLmxvZwogICAgX2YgPSBmLmFwcGx5KG51bGwsIENhbWxfYXJyYXkuc3ViKGFyZ3MsIDAsIGFyaXR5KSk7CiAgICBjb250aW51ZSA7CiAgfTsKfQoKLy8gUXVlc3Rpb246IFdoeSBjYW50IHdlIGhhdmUgdGhlIGRlZmF1bHQgaW4gQ3VycnkgYXMgYSBhcHBseSB3aXRoIGFyZ3M%2FCi8vIGxpa2UgdGhpcwpkZWZhdWx0OgogICAgICAgIHJldHVybiBvLmFwcGx5KG51bGwsIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKOwoqLwoKLy8gVGhlIHNvbHV0aW9uIHRoYXQgSSBmb3VuZCB0byB3b3JrIHdpdGggaXQgaXMgdG8gY2FsbCBhY3Rpb24gd2l0aCB0dXBsZXMKLy8gQ29tbWVudCB0aGUgbGluZSB3aXRoIGFjdGlvbigxMCwyMCwzMCkgdG8gc2VlIGl0CmxvZ0FyZ3MoKDEwLDIwLDMwKSkKCgo%3D&live=off

            To solve this problem, we need to pass the args as a single value, like this:
            action((title, content));

            JS CODE: Curry._1(action, [title, content]);
            In the callServer the arg will be [[title, content]]
          */
          action((title, content));
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let editHandler = (~id, ~title, ~content) => {
      let note = DB.editNote(~id, ~title, ~content);
      let%lwt response =
        switch%lwt (note) {
        | Ok(note) => Lwt.return(createNoteResponse(note))
        | Error(e) => failwith(e)
        };
      Lwt.return(response);
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let editId = "id/notes/edit";

  [@platform native]
  let editHandler = (~id, ~title, ~content) => {
    let note = DB.editNote(~id, ~title, ~content);
    let%lwt response =
      switch%lwt (note) {
      | Ok(note) => Lwt.return(createNoteResponse(note))
      | Error(e) => failwith(e)
      };

    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let editRouteHandler = args => {
    // Parse the body to get the args
    // This will be generated by some ppx
    let (id, title, content) =
      switch (args) {
      | [id, title, content] => (
          // It would be handle by a id_of_json/title_of_json/content_of_json in the future provided by the end-user and the ppx
          id |> Yojson.Basic.Util.to_int,
          title |> Yojson.Basic.Util.to_string,
          content |> Yojson.Basic.Util.to_string,
        )
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    editHandler(~id, ~title, ~content);
  };

  // This is the action generated to be used under the hood for the server and client
  let edit =
    switch%platform () {
    | Server => editHandler
    | Client => (
        (~id, ~title, ~content) => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              editId,
              Some("edit"),
            );
          /**
            Under the hoods if we call action(id, title, content), melange will do this:
                function edit(id, title, content) {
                  var action = ReactServerDOMWebpack.createServerReference(editId, "edit");
                  return Curry._3(action, id, title, content);
                }

            But action is a function that is provided by react without the args defined, something like this function action () => {...}. Cause it get the args as a list using `arguments` keyword.
            Ref: https://github.com/facebook/react/blob/2398554c6034e6d0992fcaa1c2e95f1757cab53e/packages/react-client/src/ReactFlightReplyClient.js#L1366-L1370
            As the arg is not defined, the function will be called with only the first one, as you can see here in this playground:
            https://melange.re/unstable/playground/?language=Reason&code=LyoKSW4gdGhpcyBwbGF5Z3JvdW5kIEknbSBzaW11bGF0aW5nIGEgYmVoYXZpb3Igb2YgYSBpc3N1ZSB0aGF0IEkgZmFjZWQgd2l0aCBhIGJpbmRpbmcuIAoKTW9yZSBzcGVjaWZpYywgdGhpcyBvbmU6CltAbWVsLm1vZHVsZSAicmVhY3Qtc2VydmVyLWRvbS13ZWJwYWNrL2NsaWVudCJdCmV4dGVybmFsIGNyZWF0ZVNlcnZlclJlZmVyZW5jZUltcGw6CiAgKAogICAgLy8gU2VydmVyUmVmZXJlbmNlSWQKICAgIHN0cmluZywKICAgIC8vIENhbGxTZXJ2ZXJDYWxsYmFjawogICAgY2FsbFNlcnZlckNhbGxiYWNrKCdhLCAnYiksIAogICAgLy8gRW5jb2RlRm9ybUFjdGlvbkNhbGxiYWNrIChvcHRpb25hbCkKICAgIG9wdGlvbigoJ2EsICdiKSA9PiBlbmNvZGVGb3JtQWN0aW9uKSwKICAgIC8vIEZpbmRTb3VyY2VNYXBVUkxDYWxsYmFjayAob3B0aW9uYWwsIERFVi1vbmx5KQogICAgb3B0aW9uKCdlID0%2BIHN0cmluZyksCiAgICAvLyBmdW5jdGlvbk5hbWUgKG9wdGlvbmFsKQogICAgb3B0aW9uKHN0cmluZykKICApID0%2BCiAgJ2YgPQogICJjcmVhdGVTZXJ2ZXJSZWZlcmVuY2UiOwoqLwpbJSVtZWwucmF3CiAge3wKICBmdW5jdGlvbiBnZXRMb2dBcmdzSW1wbCgpIHsKICAgICAgICAgIHZhciBhcmdzID0gQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoYXJndW1lbnRzKTsKICAgICAgICAgIHJldHVybiBhcmdzCiAgICAgICAgfQp8fQpdOwoKLy8gVGhpcyBpcyBqdXN0IHRvIHNpbXVsYXRlIHRoZSBjYXNlIHRoYXQgd2UgaGF2ZSBhcyB1c2luZyBleHRlcm5hbApleHRlcm5hbCBnZXRMb2dBcmdzOiB1bml0ID0%2BICdmID0gImdldExvZ0FyZ3NJbXBsIjsKCi8vIExvZ2dpbmcgdGhlIHJlZmVyZW5jZSB0byBzaG93IHRoYXQgaXMgMApsZXQgXyA9IFslbWVsLnJhdyAiY29uc29sZS5sb2coJ0FjdGlvbiBhcml0eTonLCBsb2dBcmdzLmxlbmd0aCkiXQpsZXQgbG9nQXJncyA9IGdldExvZ0FyZ3MoKTsKCi8vIEknbSBub3QgcmVjZWl2aW5nIHRoaXMgd2FybmluZyBvbiB0aGUgc2VydmVyLXJlYXNvbi1yZWFjdCBkZW1vLiBXaHk%2FCi8vIEJ1dCBsZXRzIGNhbGwgYWN0aW9uIGFuZCBzZWUgdGhlIGxvZyB0aGF0IHdlIGhhdmUKdHJ5IChsb2dBcmdzKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSkgewogfCBfID0%2BICgpCn0KLyogCk9uIGNhbGxpbmcgYWN0aW9uKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSwgaXQgd2lsbCBiZSB0cmFuc2Zvcm0gaW50bzoKQ3VycnkuXzMoYWN0aW9uLCAxLCAiU29tZSB0aXRsZSIsICJTb21lIGRlc2NyaXB0aW9uIik7CkFuZCBDdXJyeSB1bmRlciB0aGUgaG9vZHMgaXM6CgpmdW5jdGlvbiBfMyhvLCBhMCwgYTEsIGEyKSB7CiAgdmFyIGFyaXR5ID0gby5sZW5ndGg7CiAgaWYgKGFyaXR5ID09PSAzKSB7CiAgICByZXR1cm4gbyhhMCwgYTEsIGEyKTsKICB9IGVsc2UgewogICAgc3dpdGNoIChhcml0eSkgewogICAgICAuLi4KICAgICAgZGVmYXVsdDoKICAgICAgICByZXR1cm4gYXBwKG8sIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKICAgIH0KICB9Cn0KClRoZSBwcm9ibGVtYSBpcyB0aGF0IHRoZSBhcml0eSBvZiBhIGZ1bmN0aW9uIHRoYXQgaXMgKC4uLmFyZ3MpID0%2BIHsuLi59IGlzIDAKVGhlbiB3ZSBmYWxsIGludG8gdGhlIGFwcCBmdW5jdGlvbgoKZnVuY3Rpb24gYXBwKF9mLCBfYXJncykgewogIHdoaWxlKHRydWUpIHsKICAgIHZhciBhcmdzID0gX2FyZ3M7CiAgICB2YXIgZiA9IF9mOwogICAgdmFyIGluaXRfYXJpdHkgPSBmLmxlbmd0aDsKICAgIC8vIFRoZSBhcml0eSB2YWx1ZSB3aWxsIGJlIDAgY2F1c2UgaW5pdF9hcml0eSBpcyAwCiAgICB2YXIgYXJpdHkgPSBpbml0X2FyaXR5ID09PSAwID8gMSA6IGluaXRfYXJpdHk7IAogICAgdmFyIGxlbiA9IGFyZ3MubGVuZ3RoOwogICAgLy8gQVRFTlRJT04gSEVSRTogYXMgYXJpdHkgaXMgMSB0aGUgbGVuIHdpbGwgYmUgLTIKICAgIHZhciBkID0gYXJpdHkgLSBsZW4gfCAwOyAKICAgIGlmIChkID09PSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBpZiAoZCA%2BPSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBfYXJncyA9IENhbWxfYXJyYXkuc3ViKGFyZ3MsIGFyaXR5LCAtZCB8IDApOwogICAgLy8gSW4gdGhpcyBmaXJzdCBsb29wIHdpbGwgZmFsbCBpbnRvIHRoaXMsIGFuZCB0aGUgcHJvYmxlbSBpcyB0aGF0IHRoZSBhcHBseSBmdW5jdGlvbiB3aWxsIGNhbGwKICAgIC8vIHRoZSBmdW5jdGlvbiwgaW4gb3VyIGNhc2UsIHRoZSBmdW5jdGlvbiB3aWxsIGJlIGNhbGxlZCB3aXRoIFsxXSBhcyB5b3UgY2FuIHNlZSBvbiBjb25zb2xlLmxvZwogICAgX2YgPSBmLmFwcGx5KG51bGwsIENhbWxfYXJyYXkuc3ViKGFyZ3MsIDAsIGFyaXR5KSk7CiAgICBjb250aW51ZSA7CiAgfTsKfQoKLy8gUXVlc3Rpb246IFdoeSBjYW50IHdlIGhhdmUgdGhlIGRlZmF1bHQgaW4gQ3VycnkgYXMgYSBhcHBseSB3aXRoIGFyZ3M%2FCi8vIGxpa2UgdGhpcwpkZWZhdWx0OgogICAgICAgIHJldHVybiBvLmFwcGx5KG51bGwsIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKOwoqLwoKLy8gVGhlIHNvbHV0aW9uIHRoYXQgSSBmb3VuZCB0byB3b3JrIHdpdGggaXQgaXMgdG8gY2FsbCBhY3Rpb24gd2l0aCB0dXBsZXMKLy8gQ29tbWVudCB0aGUgbGluZSB3aXRoIGFjdGlvbigxMCwyMCwzMCkgdG8gc2VlIGl0CmxvZ0FyZ3MoKDEwLDIwLDMwKSkKCgo%3D&live=off

            To solve this problem, we need to pass the args as a single value, with a tuple (in the end it will be a list on js):
            action((id, title, content));

            JS CODE: Curry._1(action, [id, title, content]);
            In the callServer the arg will be [[id, title, content]]
          */
          action((id, title, content));
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let deleteHandler = (~id) => {
      let _ = DB.deleteNote(id);
      let response = `String("Note deleted");
      Lwt.return(response);
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let deleteId = "id/notes/delete";

  [@platform native]
  let deleteHandler = (~id) => {
    let _ = DB.deleteNote(id);
    let response = `String("Note deleted");
    Lwt.return(response);
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let deleteRouteHandler = args => {
    // Parse the body to get the args
    // This will be generated by some ppx
    let id =
      // It would be handle by a id_of_json in the future provided by the end-user and the ppx
      switch (args) {
      | [id] => id |> Yojson.Basic.Util.to_int
      | _ =>
        failwith(
          Printf.sprintf(
            "Invalid arguments %s",
            args
            |> List.map(Yojson.Basic.Util.to_string)
            |> String.concat(","),
          ),
        )
      };

    deleteHandler(~id);
  };

  // This is the action generated to be used under the hood for the server and client
  let delete =
    switch%platform () {
    | Server => deleteHandler
    | Client => (
        (~id) => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              deleteId,
              Some("delete"),
            );
          /**
            Under the hoods if we call action(id, title, content), melange will do this:
                function edit(id) {
                  var action = ReactServerDOMWebpack.createServerReference(deleteId, "delete");
                  return Curry._1(action, id);
                }

            But action is a function that is provided by react without the args defined, something like this function action () => {...}. Cause it get the args as a list using `arguments` keyword.
            Ref: https://github.com/facebook/react/blob/2398554c6034e6d0992fcaa1c2e95f1757cab53e/packages/react-client/src/ReactFlightReplyClient.js#L1366-L1370
            As the arg is not defined, the function will be called with only the first one, as you can see here in this playground:
            https://melange.re/unstable/playground/?language=Reason&code=LyoKSW4gdGhpcyBwbGF5Z3JvdW5kIEknbSBzaW11bGF0aW5nIGEgYmVoYXZpb3Igb2YgYSBpc3N1ZSB0aGF0IEkgZmFjZWQgd2l0aCBhIGJpbmRpbmcuIAoKTW9yZSBzcGVjaWZpYywgdGhpcyBvbmU6CltAbWVsLm1vZHVsZSAicmVhY3Qtc2VydmVyLWRvbS13ZWJwYWNrL2NsaWVudCJdCmV4dGVybmFsIGNyZWF0ZVNlcnZlclJlZmVyZW5jZUltcGw6CiAgKAogICAgLy8gU2VydmVyUmVmZXJlbmNlSWQKICAgIHN0cmluZywKICAgIC8vIENhbGxTZXJ2ZXJDYWxsYmFjawogICAgY2FsbFNlcnZlckNhbGxiYWNrKCdhLCAnYiksIAogICAgLy8gRW5jb2RlRm9ybUFjdGlvbkNhbGxiYWNrIChvcHRpb25hbCkKICAgIG9wdGlvbigoJ2EsICdiKSA9PiBlbmNvZGVGb3JtQWN0aW9uKSwKICAgIC8vIEZpbmRTb3VyY2VNYXBVUkxDYWxsYmFjayAob3B0aW9uYWwsIERFVi1vbmx5KQogICAgb3B0aW9uKCdlID0%2BIHN0cmluZyksCiAgICAvLyBmdW5jdGlvbk5hbWUgKG9wdGlvbmFsKQogICAgb3B0aW9uKHN0cmluZykKICApID0%2BCiAgJ2YgPQogICJjcmVhdGVTZXJ2ZXJSZWZlcmVuY2UiOwoqLwpbJSVtZWwucmF3CiAge3wKICBmdW5jdGlvbiBnZXRMb2dBcmdzSW1wbCgpIHsKICAgICAgICAgIHZhciBhcmdzID0gQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoYXJndW1lbnRzKTsKICAgICAgICAgIHJldHVybiBhcmdzCiAgICAgICAgfQp8fQpdOwoKLy8gVGhpcyBpcyBqdXN0IHRvIHNpbXVsYXRlIHRoZSBjYXNlIHRoYXQgd2UgaGF2ZSBhcyB1c2luZyBleHRlcm5hbApleHRlcm5hbCBnZXRMb2dBcmdzOiB1bml0ID0%2BICdmID0gImdldExvZ0FyZ3NJbXBsIjsKCi8vIExvZ2dpbmcgdGhlIHJlZmVyZW5jZSB0byBzaG93IHRoYXQgaXMgMApsZXQgXyA9IFslbWVsLnJhdyAiY29uc29sZS5sb2coJ0FjdGlvbiBhcml0eTonLCBsb2dBcmdzLmxlbmd0aCkiXQpsZXQgbG9nQXJncyA9IGdldExvZ0FyZ3MoKTsKCi8vIEknbSBub3QgcmVjZWl2aW5nIHRoaXMgd2FybmluZyBvbiB0aGUgc2VydmVyLXJlYXNvbi1yZWFjdCBkZW1vLiBXaHk%2FCi8vIEJ1dCBsZXRzIGNhbGwgYWN0aW9uIGFuZCBzZWUgdGhlIGxvZyB0aGF0IHdlIGhhdmUKdHJ5IChsb2dBcmdzKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSkgewogfCBfID0%2BICgpCn0KLyogCk9uIGNhbGxpbmcgYWN0aW9uKDEsICJTb21lIHRpdGxlIiwgIlNvbWUgZGVzY3JpcHRpb24iKSwgaXQgd2lsbCBiZSB0cmFuc2Zvcm0gaW50bzoKQ3VycnkuXzMoYWN0aW9uLCAxLCAiU29tZSB0aXRsZSIsICJTb21lIGRlc2NyaXB0aW9uIik7CkFuZCBDdXJyeSB1bmRlciB0aGUgaG9vZHMgaXM6CgpmdW5jdGlvbiBfMyhvLCBhMCwgYTEsIGEyKSB7CiAgdmFyIGFyaXR5ID0gby5sZW5ndGg7CiAgaWYgKGFyaXR5ID09PSAzKSB7CiAgICByZXR1cm4gbyhhMCwgYTEsIGEyKTsKICB9IGVsc2UgewogICAgc3dpdGNoIChhcml0eSkgewogICAgICAuLi4KICAgICAgZGVmYXVsdDoKICAgICAgICByZXR1cm4gYXBwKG8sIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKICAgIH0KICB9Cn0KClRoZSBwcm9ibGVtYSBpcyB0aGF0IHRoZSBhcml0eSBvZiBhIGZ1bmN0aW9uIHRoYXQgaXMgKC4uLmFyZ3MpID0%2BIHsuLi59IGlzIDAKVGhlbiB3ZSBmYWxsIGludG8gdGhlIGFwcCBmdW5jdGlvbgoKZnVuY3Rpb24gYXBwKF9mLCBfYXJncykgewogIHdoaWxlKHRydWUpIHsKICAgIHZhciBhcmdzID0gX2FyZ3M7CiAgICB2YXIgZiA9IF9mOwogICAgdmFyIGluaXRfYXJpdHkgPSBmLmxlbmd0aDsKICAgIC8vIFRoZSBhcml0eSB2YWx1ZSB3aWxsIGJlIDAgY2F1c2UgaW5pdF9hcml0eSBpcyAwCiAgICB2YXIgYXJpdHkgPSBpbml0X2FyaXR5ID09PSAwID8gMSA6IGluaXRfYXJpdHk7IAogICAgdmFyIGxlbiA9IGFyZ3MubGVuZ3RoOwogICAgLy8gQVRFTlRJT04gSEVSRTogYXMgYXJpdHkgaXMgMSB0aGUgbGVuIHdpbGwgYmUgLTIKICAgIHZhciBkID0gYXJpdHkgLSBsZW4gfCAwOyAKICAgIGlmIChkID09PSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBpZiAoZCA%2BPSAwKSB7CiAgICAgIC8vLi4uCiAgICB9CiAgICBfYXJncyA9IENhbWxfYXJyYXkuc3ViKGFyZ3MsIGFyaXR5LCAtZCB8IDApOwogICAgLy8gSW4gdGhpcyBmaXJzdCBsb29wIHdpbGwgZmFsbCBpbnRvIHRoaXMsIGFuZCB0aGUgcHJvYmxlbSBpcyB0aGF0IHRoZSBhcHBseSBmdW5jdGlvbiB3aWxsIGNhbGwKICAgIC8vIHRoZSBmdW5jdGlvbiwgaW4gb3VyIGNhc2UsIHRoZSBmdW5jdGlvbiB3aWxsIGJlIGNhbGxlZCB3aXRoIFsxXSBhcyB5b3UgY2FuIHNlZSBvbiBjb25zb2xlLmxvZwogICAgX2YgPSBmLmFwcGx5KG51bGwsIENhbWxfYXJyYXkuc3ViKGFyZ3MsIDAsIGFyaXR5KSk7CiAgICBjb250aW51ZSA7CiAgfTsKfQoKLy8gUXVlc3Rpb246IFdoeSBjYW50IHdlIGhhdmUgdGhlIGRlZmF1bHQgaW4gQ3VycnkgYXMgYSBhcHBseSB3aXRoIGFyZ3M%2FCi8vIGxpa2UgdGhpcwpkZWZhdWx0OgogICAgICAgIHJldHVybiBvLmFwcGx5KG51bGwsIFsKICAgICAgICAgICAgICAgICAgICBhMCwKICAgICAgICAgICAgICAgICAgICBhMSwKICAgICAgICAgICAgICAgICAgICBhMgogICAgICAgICAgICAgICAgICBdKTsKOwoqLwoKLy8gVGhlIHNvbHV0aW9uIHRoYXQgSSBmb3VuZCB0byB3b3JrIHdpdGggaXQgaXMgdG8gY2FsbCBhY3Rpb24gd2l0aCB0dXBsZXMKLy8gQ29tbWVudCB0aGUgbGluZSB3aXRoIGFjdGlvbigxMCwyMCwzMCkgdG8gc2VlIGl0CmxvZ0FyZ3MoKDEwLDIwLDMwKSkKCgo%3D&live=off

            In this case, unlike the edit and create functions that we had before, we already have a single value, the id, but we still pass it as a "list" like as the parse will expected
            in this way due to the function with multiple args (as edit and create) being called with a tuple.
            Calling with only 1 value will have in the callServer the arg to be [id], unlike create that is [[title, description]]
            To solve this problem and keep the same contract and make the args parser easy, we need to pass the arg as a Array of a single value, like this:
            action([|id, title, content|]);

            JS CODE: Curry._1(action, [id]); // Keeping all the action function with the same behavior.
            in the callServer the arg will be [[id]]
          */
          action([|id|]);
        }
      )
    };
};

module Samples = {
  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let formDataHandler = formData => {
      let (_, name) = Hashtbl.find(formData, "name") |> List.hd;
      let (_, lastName) = Hashtbl.find(formData, "lastName") |> List.hd;
      let (_, age) = Hashtbl.find(formData, "age") |> List.hd;

      Dream.log("Hello %s %s, you are %s years old", name, lastName, age);

      Lwt.return(
        (`String("Hello from server with form data action")),
      );
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let formDataId = "id/samples/form-data";

  [@platform native]
  let formDataHandler = formData => {
    // For now, we are handling it by calling the value from Hashtbl
    // We already have an issue to create FormData at Js.
    let (_, name) = Hashtbl.find(formData, "name") |> List.hd;
    let (_, lastName) = Hashtbl.find(formData, "lastName") |> List.hd;
    let (_, age) = Hashtbl.find(formData, "age") |> List.hd;

    Dream.log("Hello %s %s, you are %s years old", name, lastName, age);

    Lwt.return(`String("Hello from server with form data action"));
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let formDataRouteHandler = formData => {
    formDataHandler(formData);
  };

  let formData =
    switch%platform () {
    | Server => formDataHandler
    | Client => (
        formData => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              formDataId,
              Some("formData"),
            );
          action(formData);
        }
      )
    };

  // Lets say this is the server action declared by the end-user
  /**
    [@react.server.action]
    let simpleResponse = () => {
      Lwt.return(
        (`String("Hello from server with simple response action")),
      );
    };
  */
  // It's going to be on top to this that we are going to generate the codes bellow
  let simpleResponseId = "id/samples/simpleResponse";

  [@platform native]
  let simpleResponseHandler = () => {
    Lwt.return(`String("Hello from server with simple response action"));
  };

  // This is the router  handler that will handle parsing the args and calling the handler the user declared
  // This code will be generated by the ppx automatically
  // As the user didn't declare a request on the action, we don't need to pass it to the handler
  [@platform native]
  let simpleResponseRouteHandler = _args => simpleResponseHandler();

  let simpleResponse =
    switch%platform () {
    | Server => simpleResponseHandler
    | Client => (
        _ => {
          let action =
            ReactServerDOMWebpack.createServerReference(
              simpleResponseId,
              Some("simpleResponse"),
            );
          action();
        }
      )
    };
};
