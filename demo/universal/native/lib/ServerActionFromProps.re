module Form = {
  [@warning "-27"];
  [@react.component]
  let make = (~children=React.null) =>
    switch%platform () {
    | Server =>
      // The contract for actionFn is a string for the actionId
      // For now I'm not handling the bound part, required by the react, we can do it later
      <form actionFn=Actions.Samples.formData> children </form>
    // This is a server component, but we need switch%platform to make it compile
    | Client => React.null
    };
};

[@warning "-26-27-32"];
[@react.component]
let make = () => {
  <div>
    <Form>
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
    </Form>
  </div>;
};
