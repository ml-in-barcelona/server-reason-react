/**
 * Shared benchmark scenarios for JavaScript frameworks
 * These mirror the Reason/OCaml scenarios for fair comparison
 */

import React from "react";

// ============================================================================
// Trivial - Baseline
// ============================================================================
export const Trivial = () => <div>Hello World</div>;

// ============================================================================
// ShallowTree - 5 levels deep with props
// ============================================================================
const Level5 = ({ title, subtitle, active, count }) => (
  <div className={`p-4 rounded ${active ? "bg-blue-500" : ""}`}>
    <h5 className="font-bold">{title}</h5>
    <p className="text-sm text-gray-500">{subtitle}</p>
    <span className="badge">{count}</span>
  </div>
);

const Level4 = ({ title, description, isHighlighted, itemCount }) => (
  <section
    className={`mb-4 ${isHighlighted ? "border-l-4 border-blue-500" : ""}`}
  >
    <Level5
      title={title}
      subtitle={description}
      active={isHighlighted}
      count={itemCount}
    />
    <Level5
      title={`${title} Alt`}
      subtitle="Secondary"
      active={false}
      count={itemCount * 2}
    />
  </section>
);

const Level3 = ({ groupName, expanded, totalItems }) => (
  <article className={`p-6 ${expanded ? "shadow-lg" : ""}`}>
    <h3 className="text-xl font-semibold mb-4">{groupName}</h3>
    <Level4
      title="First Item"
      description="Description A"
      isHighlighted={true}
      itemCount={totalItems}
    />
    <Level4
      title="Second Item"
      description="Description B"
      isHighlighted={false}
      itemCount={Math.floor(totalItems / 2)}
    />
  </article>
);

const Level2 = ({ sectionTitle, isVisible }) => (
  <div className={`container mx-auto ${isVisible ? "block" : ""}`}>
    <h2 className="text-2xl font-bold mb-6">{sectionTitle}</h2>
    <Level3 groupName="Group Alpha" expanded={true} totalItems={42} />
    <Level3 groupName="Group Beta" expanded={false} totalItems={17} />
  </div>
);

const Level1 = ({ pageTitle }) => (
  <main className="min-h-screen bg-gray-100 py-8">
    <h1 className="text-4xl font-extrabold text-center mb-8">{pageTitle}</h1>
    <Level2 sectionTitle="Primary Section" isVisible={true} />
    <Level2 sectionTitle="Secondary Section" isVisible={true} />
  </main>
);

export const ShallowTree = () => <Level1 pageTitle="Shallow Tree Benchmark" />;

// ============================================================================
// DeepTree - 50+ levels deep
// ============================================================================
const Wrapper = ({ depth, maxDepth, children }) => {
  const percentage = (depth / maxDepth) * 100;
  return (
    <div
      className={`depth-${depth}`}
      data-testid={`level-${depth}`}
      style={{ paddingLeft: "2px", borderLeft: "1px solid rgba(0,0,0,0.1)" }}
    >
      <span className="text-xs text-gray-400">
        Level {depth} ({percentage.toFixed(0)}%)
      </span>
      {children}
    </div>
  );
};

const renderDepth = (current, max) => {
  if (current >= max) {
    return (
      <div className="leaf-node bg-green-100 p-2 rounded">
        <strong>Leaf Node</strong>
        <p className="text-sm">Reached depth {current}</p>
      </div>
    );
  }
  return (
    <Wrapper depth={current} maxDepth={max}>
      {renderDepth(current + 1, max)}
    </Wrapper>
  );
};

export const DeepTree10 = () => renderDepth(0, 10);
export const DeepTree25 = () => renderDepth(0, 25);
export const DeepTree50 = () => renderDepth(0, 50);
export const DeepTree100 = () => renderDepth(0, 100);
export const DeepTree = DeepTree50;

// ============================================================================
// WideTree - Many siblings
// ============================================================================
const Card = ({ id, title, description, price, rating, inStock }) => (
  <article
    className={`border rounded-lg p-4 shadow-sm ${!inStock ? "opacity-50" : ""}`}
  >
    <div className="flex justify-between items-start mb-2">
      <h3 className="font-semibold text-lg">{title}</h3>
      <span className="text-xs bg-gray-100 px-2 py-1 rounded">#{id}</span>
    </div>
    <p className="text-gray-600 text-sm mb-3">{description}</p>
    <div className="flex justify-between items-center">
      <span className="text-xl font-bold text-green-600">
        ${price.toFixed(2)}
      </span>
      <div className="flex items-center gap-1">
        <span className="text-yellow-500">★</span>
        <span className="text-sm">{rating.toFixed(1)}</span>
      </div>
    </div>
    <div className="mt-2">
      {inStock ? (
        <span className="text-green-500 text-sm">In Stock</span>
      ) : (
        <span className="text-red-500 text-sm">Out of Stock</span>
      )}
    </div>
  </article>
);

const generateItems = (count) =>
  Array.from({ length: count }, (_, i) => ({
    id: i + 1,
    title: `Product ${i + 1}`,
    description: `This is the description for product ${i + 1}. It contains useful information.`,
    price: 9.99 + (i % 100),
    rating: 3.0 + (i % 20) / 10.0,
    inStock: i % 7 !== 0,
  }));

const WideTreeBase = ({ count, cols }) => {
  const items = generateItems(count);
  return (
    <div className={`grid grid-cols-${cols} gap-4 p-4`}>
      {items.map((item) => (
        <Card key={item.id} {...item} />
      ))}
    </div>
  );
};

export const WideTree10 = () => <WideTreeBase count={10} cols={2} />;
export const WideTree100 = () => <WideTreeBase count={100} cols={4} />;
export const WideTree500 = () => <WideTreeBase count={500} cols={5} />;
export const WideTree1000 = () => <WideTreeBase count={1000} cols={5} />;
export const WideTree = WideTree100;

// ============================================================================
// Table - Data table rendering
// ============================================================================
const generateUsers = (count) =>
  Array.from({ length: count }, (_, i) => {
    const departments = [
      "Engineering",
      "Design",
      "Product",
      "Marketing",
      "Sales",
      "HR",
    ];
    const roles = ["Engineer", "Senior Engineer", "Lead", "Manager", "Director"];
    const statuses = ["active", "inactive", "pending"];
    const firstNames = [
      "Alice",
      "Bob",
      "Charlie",
      "Diana",
      "Eve",
      "Frank",
      "Grace",
      "Henry",
    ];
    const lastNames = [
      "Smith",
      "Johnson",
      "Williams",
      "Brown",
      "Jones",
      "Garcia",
      "Miller",
    ];

    const firstName = firstNames[i % firstNames.length];
    const lastName = lastNames[i % lastNames.length];

    return {
      id: i + 1,
      name: `${firstName} ${lastName}`,
      email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}@company.com`,
      role: roles[i % roles.length],
      status: statuses[i % statuses.length],
      department: departments[i % departments.length],
      joinDate: `2${String(20 + (i % 5)).padStart(2, "0")}-${String(1 + (i % 12)).padStart(2, "0")}-${String(1 + (i % 28)).padStart(2, "0")}`,
      salary: 50000 + i * 1000,
      manager: i % 5 === 0 ? null : `Manager ${Math.floor(i / 5)}`,
      projects: (i % 10) + 1,
    };
  });

const StatusBadge = ({ status }) => {
  const colors = {
    active: "bg-green-100 text-green-800",
    inactive: "bg-red-100 text-red-800",
    pending: "bg-yellow-100 text-yellow-800",
  };
  const labels = {
    active: "Active",
    inactive: "Inactive",
    pending: "Pending",
  };

  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[status]}`}
    >
      {labels[status]}
    </span>
  );
};

const TableRow = ({ user, isEven }) => (
  <tr className={isEven ? "bg-white" : "bg-gray-50"}>
    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
      {user.id}
    </td>
    <td className="px-6 py-4 whitespace-nowrap">
      <div className="flex items-center">
        <div className="flex-shrink-0 h-10 w-10">
          <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
            <span className="text-sm font-medium text-gray-600">
              {user.name.substring(0, 2)}
            </span>
          </div>
        </div>
        <div className="ml-4">
          <div className="text-sm font-medium text-gray-900">{user.name}</div>
          <div className="text-sm text-gray-500">{user.email}</div>
        </div>
      </div>
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      {user.role}
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      {user.department}
    </td>
    <td className="px-6 py-4 whitespace-nowrap">
      <StatusBadge status={user.status} />
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      {user.joinDate}
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      ${user.salary.toLocaleString()}
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      {user.manager || <span className="text-gray-400 italic">None</span>}
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
      {user.projects}
    </td>
    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
      <a href="#" className="text-blue-600 hover:text-blue-900 mr-3">
        Edit
      </a>
      <a href="#" className="text-red-600 hover:text-red-900">
        Delete
      </a>
    </td>
  </tr>
);

const DataTable = ({ users }) => (
  <div className="flex flex-col">
    <div className="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
      <div className="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
        <div className="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                {[
                  "ID",
                  "Employee",
                  "Role",
                  "Department",
                  "Status",
                  "Join Date",
                  "Salary",
                  "Manager",
                  "Projects",
                  "Actions",
                ].map((header) => (
                  <th
                    key={header}
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {users.map((user, i) => (
                <TableRow key={user.id} user={user} isEven={i % 2 === 0} />
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
);

export const Table10 = () => <DataTable users={generateUsers(10)} />;
export const Table50 = () => <DataTable users={generateUsers(50)} />;
export const Table100 = () => <DataTable users={generateUsers(100)} />;
export const Table500 = () => <DataTable users={generateUsers(500)} />;
export const Table = Table100;

// ============================================================================
// Export all scenarios with metadata
// ============================================================================
export const scenarios = {
  trivial: { component: Trivial, name: "Trivial", description: "Baseline" },
  shallow: {
    component: ShallowTree,
    name: "Shallow Tree",
    description: "5 levels deep",
  },
  deep10: {
    component: DeepTree10,
    name: "Deep Tree 10",
    description: "10 levels",
  },
  deep25: {
    component: DeepTree25,
    name: "Deep Tree 25",
    description: "25 levels",
  },
  deep50: {
    component: DeepTree50,
    name: "Deep Tree 50",
    description: "50 levels",
  },
  deep100: {
    component: DeepTree100,
    name: "Deep Tree 100",
    description: "100 levels",
  },
  wide10: {
    component: WideTree10,
    name: "Wide Tree 10",
    description: "10 siblings",
  },
  wide100: {
    component: WideTree100,
    name: "Wide Tree 100",
    description: "100 siblings",
  },
  wide500: {
    component: WideTree500,
    name: "Wide Tree 500",
    description: "500 siblings",
  },
  wide1000: {
    component: WideTree1000,
    name: "Wide Tree 1000",
    description: "1000 siblings",
  },
  table10: {
    component: Table10,
    name: "Table 10",
    description: "10 row table",
  },
  table50: {
    component: Table50,
    name: "Table 50",
    description: "50 row table",
  },
  table100: {
    component: Table100,
    name: "Table 100",
    description: "100 row table",
  },
  table500: {
    component: Table500,
    name: "Table 500",
    description: "500 row table",
  },
};

export default scenarios;

