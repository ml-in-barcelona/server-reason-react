[@warning "-32"];
[@mel.module "react"]
external useActionState:
  (
    (string, Js.FormData.t) => Js.Promise.t(string),
    Js.Nullable.t('response)
  ) =>
  (Js.Nullable.t(string), unit => unit, bool) =
  "useActionState";
[@warning "+32"];

type formData = {name: string};

let useActionState =
  switch%platform () {
  | Server => React.useActionState
  | Client => useActionState
  };

[@react.client.component]
let make = () => {
  let (state, formAction, isPending) =
    useActionState(
      (_prevState, formData) => ServerFunctions.formData.call(formData),
      Js.Nullable.null,
    );

  <form
    action={
      switch%platform () {
      | Server => ""
      | Client => Obj.magic(formAction)
      }
    }
    className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
    <input
      name="name"
      className="w-full mb-2 font-sans border border-gray-300 py-2 px-4 rounded-md bg-white text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
      placeholder="Name"
    />
    <div>
      {isPending
         ? <Text size=Small> "Loading..." </Text>
         : (
           switch (state |> Js.Nullable.toOption) {
           | Some(state) => <Text size=Small> state </Text>
           | None => React.null
           }
         )}
    </div>
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      type_="submit">
      {React.string("Send Form Data")}
    </button>
  </form>;
};
