module DOM = Webapi.Dom;
module Location = DOM.Location;

let fetchAction = (path, body) => {
  let location = DOM.window->DOM.Window.location;
  let origin = Location.origin(location);
  let headers =
    Fetch.HeadersInit.make({
      "Accept": "application/react.action",
      "ACTION_ID": path,
    });
  let url = URL.makeExn(origin ++ "/actions");
  let body = Fetch.BodyInit.make(body);

  Fetch.fetchWithInit(
    URL.toString(url),
    Fetch.RequestInit.make(~method_=Fetch.Post, ~headers, ~body, ()),
  )
  |> Js.Promise.then_(result => {
       let body = Fetch.Response.body(result);
       ReactServerDOMWebpack.createFromReadableStream(body);
     });
};

[@mel.new] external makeFormData: 'a => 'b = "FormData";

let fetchActionFormData = formElement => {
  formElement
  |> Js.Nullable.toOption
  |> Option.iter(el => {
       Webapi.Dom.EventTarget.addEventListener(
         "submit",
         event => {
           // Prevent default form submission
           event->Webapi.Dom.Event.preventDefault |> ignore;

           // Create FormData from the form
           let formData = makeFormData(el);

           // Add Next.js specific headers
           let headers =
             Fetch.HeadersInit.make({"Accept": "text/x-component"});

           // Send the request to the server
           Fetch.fetchWithInit(
             "/actions",
             Fetch.RequestInit.make(
               ~method_=Fetch.Post,
               ~headers,
               ~body=Fetch.BodyInit.make(formData),
               (),
             ),
           )
           |> Js.Promise.then_(result => {
                let body = Fetch.Response.body(result);
                ReactServerDOMWebpack.createFromReadableStream(body);
              })
           |> ignore;
         },
         el |> Webapi.Dom.Element.asEventTarget,
       )
     });

  ();
};
