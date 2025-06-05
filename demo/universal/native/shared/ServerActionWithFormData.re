[@react.client.component]
let make = () => {
  <form
    action={
      switch%platform () {
      | Server => ""
      | Client => Obj.magic(ServerFunctions.formDataFunction.call)
      }
    }
    className={Cx.make([Theme.text(Theme.Color.Gray4)])}>
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
  </form>;
};
