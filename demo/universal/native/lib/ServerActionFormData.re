[@warning "-33"];
open Webapi.Dom;
open EventTarget;
open Ppx_deriving_json_runtime.Primitives;

[@deriving json]
type formData = {
  name: string,
  lastName: string,
  age: string,
};

let refAction =
  ReactDOM.Ref.callbackDomRef(
    // Browser only was complaining about the ref not being used :/
    [@warning "-27"]
    [%browser_only el => FetchHelpers.fetchActionFormData(el)],
  );

let%browser_only actFormData = formData => {
  let currentURL = Router.demoActionFormDataSample;
  let stringifiedFormData =
    formData_to_json(formData) |> Ppx_deriving_json_runtime.to_string;
  let encodeArgs = stringifiedFormData;
  FetchHelpers.fetchAction(currentURL, encodeArgs);
};

[@mel.module "react"]
external startTransition: (unit => unit) => unit = "startTransition";

[@warning "-26-27-32"];
[@react.client.component]
let make = () => {
  let formRef = React.useRef(Js.Nullable.null);
  let (name, setName) = RR.useStateValue("");
  let (lastName, setLastName) = RR.useStateValue("");
  let (age, setAge) = RR.useStateValue("");

  let%browser_only onChangeName = e => {
    let newValue = React.Event.Form.target(e)##value;
    setName(newValue);
  };
  let%browser_only onChangeLastName = e => {
    let newValue = React.Event.Form.target(e)##value;
    setLastName(newValue);
  };
  let%browser_only onChangeAge = e => {
    let newValue = React.Event.Form.target(e)##value;
    setAge(newValue);
  };

  <div className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <form ref=refAction>
      <input type_="hidden" name="action" value="samples/form-data" />
      <input
        name="name"
        className="w-full mb-2 font-sans border border-gray-300 py-2 px-4 rounded-md bg-white text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
        placeholder="Name"
      />
      <input
        name="lastName"
        className="w-full mb-2 font-sans border border-gray-300 py-2 px-4 rounded-md bg-white text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
        placeholder="Last Name"
      />
      <input
        name="age"
        className="w-full mb-2 font-sans border border-gray-300 py-2 px-4 rounded-md bg-white text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
        placeholder="Age"
      />
      <button
        className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
        type_="submit">
        {React.string("Send Form Data")}
      </button>
    </form>
  </div>;
};
