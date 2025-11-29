/**
 * Node.js + Express + Preact SSR Benchmark Server
 * Tests Preact's lighter-weight alternative to React
 */

import express from "express";
import { h } from "preact";
import renderToString from "preact-render-to-string";

const app = express();
const PORT = process.env.PORT || 3006;

// ============================================================================
// Preact-native scenarios (mirrors React scenarios)
// ============================================================================

const Trivial = () => h("div", null, "Hello World");

// ShallowTree
const Level5 = ({ title, subtitle, active, count }) =>
  h(
    "div",
    { class: `p-4 rounded ${active ? "bg-blue-500" : ""}` },
    h("h5", { class: "font-bold" }, title),
    h("p", { class: "text-sm text-gray-500" }, subtitle),
    h("span", { class: "badge" }, count)
  );

const Level4 = ({ title, description, isHighlighted, itemCount }) =>
  h(
    "section",
    { class: `mb-4 ${isHighlighted ? "border-l-4 border-blue-500" : ""}` },
    h(Level5, { title, subtitle: description, active: isHighlighted, count: itemCount }),
    h(Level5, { title: `${title} Alt`, subtitle: "Secondary", active: false, count: itemCount * 2 })
  );

const Level3 = ({ groupName, expanded, totalItems }) =>
  h(
    "article",
    { class: `p-6 ${expanded ? "shadow-lg" : ""}` },
    h("h3", { class: "text-xl font-semibold mb-4" }, groupName),
    h(Level4, { title: "First Item", description: "Description A", isHighlighted: true, itemCount: totalItems }),
    h(Level4, { title: "Second Item", description: "Description B", isHighlighted: false, itemCount: Math.floor(totalItems / 2) })
  );

const Level2 = ({ sectionTitle, isVisible }) =>
  h(
    "div",
    { class: `container mx-auto ${isVisible ? "block" : ""}` },
    h("h2", { class: "text-2xl font-bold mb-6" }, sectionTitle),
    h(Level3, { groupName: "Group Alpha", expanded: true, totalItems: 42 }),
    h(Level3, { groupName: "Group Beta", expanded: false, totalItems: 17 })
  );

const Level1 = ({ pageTitle }) =>
  h(
    "main",
    { class: "min-h-screen bg-gray-100 py-8" },
    h("h1", { class: "text-4xl font-extrabold text-center mb-8" }, pageTitle),
    h(Level2, { sectionTitle: "Primary Section", isVisible: true }),
    h(Level2, { sectionTitle: "Secondary Section", isVisible: true })
  );

const ShallowTree = () => h(Level1, { pageTitle: "Shallow Tree Benchmark" });

// DeepTree
const Wrapper = ({ depth, maxDepth, children }) => {
  const percentage = (depth / maxDepth) * 100;
  return h(
    "div",
    {
      class: `depth-${depth}`,
      "data-testid": `level-${depth}`,
      style: { paddingLeft: "2px", borderLeft: "1px solid rgba(0,0,0,0.1)" },
    },
    h("span", { class: "text-xs text-gray-400" }, `Level ${depth} (${percentage.toFixed(0)}%)`),
    children
  );
};

const renderDepth = (current, max) => {
  if (current >= max) {
    return h(
      "div",
      { class: "leaf-node bg-green-100 p-2 rounded" },
      h("strong", null, "Leaf Node"),
      h("p", { class: "text-sm" }, `Reached depth ${current}`)
    );
  }
  return h(Wrapper, { depth: current, maxDepth: max }, renderDepth(current + 1, max));
};

const DeepTree50 = () => renderDepth(0, 50);

// WideTree
const Card = ({ id, title, description, price, rating, inStock }) =>
  h(
    "article",
    { class: `border rounded-lg p-4 shadow-sm ${!inStock ? "opacity-50" : ""}` },
    h(
      "div",
      { class: "flex justify-between items-start mb-2" },
      h("h3", { class: "font-semibold text-lg" }, title),
      h("span", { class: "text-xs bg-gray-100 px-2 py-1 rounded" }, `#${id}`)
    ),
    h("p", { class: "text-gray-600 text-sm mb-3" }, description),
    h(
      "div",
      { class: "flex justify-between items-center" },
      h("span", { class: "text-xl font-bold text-green-600" }, `$${price.toFixed(2)}`),
      h(
        "div",
        { class: "flex items-center gap-1" },
        h("span", { class: "text-yellow-500" }, "★"),
        h("span", { class: "text-sm" }, rating.toFixed(1))
      )
    ),
    h(
      "div",
      { class: "mt-2" },
      inStock
        ? h("span", { class: "text-green-500 text-sm" }, "In Stock")
        : h("span", { class: "text-red-500 text-sm" }, "Out of Stock")
    )
  );

const WideTree100 = () => {
  const items = Array.from({ length: 100 }, (_, i) => ({
    id: i + 1,
    title: `Product ${i + 1}`,
    description: `Description for product ${i + 1}.`,
    price: 9.99 + (i % 100),
    rating: 3.0 + (i % 20) / 10.0,
    inStock: i % 7 !== 0,
  }));

  return h(
    "div",
    { class: "grid grid-cols-4 gap-4 p-4" },
    items.map((item) => h(Card, { key: item.id, ...item }))
  );
};

// Table
const Table100 = () => {
  const users = Array.from({ length: 100 }, (_, i) => ({
    id: i + 1,
    name: `User ${i + 1}`,
    email: `user${i + 1}@example.com`,
    role: ["Engineer", "Designer", "Manager"][i % 3],
  }));

  return h(
    "table",
    { class: "min-w-full divide-y divide-gray-200" },
    h(
      "thead",
      { class: "bg-gray-50" },
      h(
        "tr",
        null,
        ["ID", "Name", "Email", "Role"].map((header) =>
          h(
            "th",
            { key: header, class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase" },
            header
          )
        )
      )
    ),
    h(
      "tbody",
      { class: "bg-white divide-y divide-gray-200" },
      users.map((user, i) =>
        h(
          "tr",
          { key: user.id, class: i % 2 === 0 ? "bg-white" : "bg-gray-50" },
          h("td", { class: "px-6 py-4 text-sm" }, user.id),
          h("td", { class: "px-6 py-4 text-sm" }, user.name),
          h("td", { class: "px-6 py-4 text-sm" }, user.email),
          h("td", { class: "px-6 py-4 text-sm" }, user.role)
        )
      )
    )
  );
};

const preactScenarios = {
  trivial: { component: Trivial, name: "Trivial" },
  shallow: { component: ShallowTree, name: "Shallow Tree" },
  deep50: { component: DeepTree50, name: "Deep Tree 50" },
  wide100: { component: WideTree100, name: "Wide Tree 100" },
  table100: { component: Table100, name: "Table 100" },
};

// Routes
app.get("/", (req, res) => {
  const scenarioName = req.query.scenario || "table100";
  const scenario = preactScenarios[scenarioName];

  if (!scenario) {
    return res.status(404).send(`Unknown scenario: ${scenarioName}`);
  }

  const html = renderToString(h(scenario.component));

  res.setHeader("Content-Type", "text/html");
  res.send(`<!DOCTYPE html><html><head><title>Benchmark</title></head><body><div id="root">${html}</div></body></html>`);
});

app.get("/health", (req, res) => {
  res.json({ status: "ok", framework: "preact", pid: process.pid });
});

app.get("/scenarios", (req, res) => {
  const list = Object.entries(preactScenarios).map(([key, val]) => ({
    key,
    name: val.name,
  }));
  res.json(list);
});

app.listen(PORT, () => {
  console.log(`[preact] Server listening on http://localhost:${PORT}`);
  console.log(`[preact] PID: ${process.pid}`);
});

