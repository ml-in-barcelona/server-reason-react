/* TODO: Move this bindings into reason-react */
/* Before it was:
      [@mel.module "react-server-dom-webpack/client"]
       external createFromReadableStream:
         Webapi.ReadableStream.t => Js.Promise.t('a) =
         "createFromReadableStream";

      But in the react code it does not strict requires to be Js.Promise.t(React.element), but a generic type.1
      And server actions can also use it, so I changed it to return React.element
   */
[@mel.module "react-server-dom-webpack/client"]
external createFromReadableStream: Webapi.ReadableStream.t => Js.Promise.t('a) =
  "createFromReadableStream";

[@mel.module "react-server-dom-webpack/client"]
external createFromFetch: Js.Promise.t(Fetch.response) => React.element =
  "createFromFetch";
