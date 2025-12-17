/* Scenario: Table Rendering
      Real-world data table patterns
      Purpose: Test realistic table rendering performance
   */

type user = {
  id: int,
  name: string,
  email: string,
  role: string,
  status: [
    | `active
    | `inactive
    | `pending
  ],
  department: string,
  joinDate: string,
  salary: float,
  manager: option(string),
  projects: int,
};

let generateUsers = count => {
  let departments = [|
    "Engineering",
    "Design",
    "Product",
    "Marketing",
    "Sales",
    "HR",
  |];
  let roles = [|
    "Engineer",
    "Senior Engineer",
    "Lead",
    "Manager",
    "Director",
  |];
  let statuses = [|`active, `inactive, `pending|];
  let firstNames = [|
    "Alice",
    "Bob",
    "Charlie",
    "Diana",
    "Eve",
    "Frank",
    "Grace",
    "Henry",
  |];
  let lastNames = [|
    "Smith",
    "Johnson",
    "Williams",
    "Brown",
    "Jones",
    "Garcia",
    "Miller",
  |];
  Array.init(
    count,
    i => {
      let id = i + 1;
      let firstName = firstNames[i mod Array.length(firstNames)];
      let lastName = lastNames[i mod Array.length(lastNames)];
      {
        id,
        name: Printf.sprintf("%s %s", firstName, lastName),
        email:
          Printf.sprintf(
            "%s.%s@company.com",
            String.lowercase_ascii(firstName),
            String.lowercase_ascii(lastName),
          ),
        role: roles[i mod Array.length(roles)],
        status: statuses[i mod Array.length(statuses)],
        department: departments[i mod Array.length(departments)],
        joinDate:
          Printf.sprintf(
            "2%03d-%02d-%02d",
            20 + i mod 5,
            1 + i mod 12,
            1 + i mod 28,
          ),
        salary: 50000.0 +. float_of_int(i * 1000),
        manager:
          i mod 5 == 0 ? None : Some(Printf.sprintf("Manager %d", i / 5)),
        projects: i mod 10 + 1,
      };
    },
  );
};

module StatusBadge = {
  [@react.component]
  let make = (~status) => {
    let (bgColor, textColor, label) =
      switch (status) {
      | `active => ("bg-green-100", "text-green-800", "Active")
      | `inactive => ("bg-red-100", "text-red-800", "Inactive")
      | `pending => ("bg-yellow-100", "text-yellow-800", "Pending")
      };

    <span
      className={Cx.make([
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
        bgColor,
        textColor,
      ])}>
      {React.string(label)}
    </span>;
  };
};

module TableRow = {
  [@react.component]
  let make = (~user, ~isEven) => {
    <tr className={isEven ? "bg-white" : "bg-gray-50"}>
      <td
        className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
        {React.int(user.id)}
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <div className="flex items-center">
          <div className="flex-shrink-0 h-10 w-10">
            <div
              className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
              <span className="text-sm font-medium text-gray-600">
                {React.string(String.sub(user.name, 0, 2))}
              </span>
            </div>
          </div>
          <div className="ml-4">
            <div className="text-sm font-medium text-gray-900">
              {React.string(user.name)}
            </div>
            <div className="text-sm text-gray-500">
              {React.string(user.email)}
            </div>
          </div>
        </div>
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {React.string(user.role)}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {React.string(user.department)}
      </td>
      <td className="px-6 py-4 whitespace-nowrap">
        <StatusBadge status={user.status} />
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {React.string(user.joinDate)}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {React.string(Printf.sprintf("$%.0f", user.salary))}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {switch (user.manager) {
         | Some(m) => React.string(m)
         | None =>
           <span className="text-gray-400 italic">
             {React.string("None")}
           </span>
         }}
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        {React.int(user.projects)}
      </td>
      <td
        className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
        <a href="#" className="text-blue-600 hover:text-blue-900 mr-3">
          {React.string("Edit")}
        </a>
        <a href="#" className="text-red-600 hover:text-red-900">
          {React.string("Delete")}
        </a>
      </td>
    </tr>;
  };
};

module DataTable = {
  [@react.component]
  let make = (~users) => {
    <div className="flex flex-col">
      <div className="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div
          className="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
          <div
            className="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("ID")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Employee")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Role")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Department")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Status")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Join Date")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Salary")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Manager")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Projects")}
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {React.string("Actions")}
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {React.array(
                   Array.mapi(
                     (i, user) =>
                       <TableRow
                         key={Int.to_string(user.id)}
                         user
                         isEven={i mod 2 == 0}
                       />,
                     users,
                   ),
                 )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>;
  };
};

/* Different sizes for comparison */
module Table10 = {
  let users = generateUsers(10);
  [@react.component]
  let make = () => <DataTable users />;
};

module Table50 = {
  let users = generateUsers(50);
  [@react.component]
  let make = () => <DataTable users />;
};

module Table100 = {
  let users = generateUsers(100);
  [@react.component]
  let make = () => <DataTable users />;
};

module Table500 = {
  let users = generateUsers(500);
  [@react.component]
  let make = () => <DataTable users />;
};

[@react.component]
let make = () => <Table100 />;
