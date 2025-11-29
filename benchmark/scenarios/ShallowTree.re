/* Scenario: Shallow Tree
      5 components deep with multiple props each
      Purpose: Test prop passing and shallow component hierarchies
   */

module Level5 = {
  [@react.component]
  let make = (~title, ~subtitle, ~active, ~count) => {
    <div
      className={Cx.make([
        "p-4",
        "rounded",
        Cx.ifTrue("bg-blue-500", active),
      ])}>
      <h5 className="font-bold"> {React.string(title)} </h5>
      <p className="text-sm text-gray-500"> {React.string(subtitle)} </p>
      <span className="badge"> {React.int(count)} </span>
    </div>;
  };
};

module Level4 = {
  [@react.component]
  let make = (~title, ~description, ~isHighlighted, ~itemCount) => {
    <section
      className={Cx.make([
        "mb-4",
        Cx.ifTrue("border-l-4 border-blue-500", isHighlighted),
      ])}>
      <Level5
        title
        subtitle=description
        active=isHighlighted
        count=itemCount
      />
      <Level5
        title={title ++ " Alt"}
        subtitle="Secondary"
        active=false
        count={itemCount * 2}
      />
    </section>;
  };
};

module Level3 = {
  [@react.component]
  let make = (~groupName, ~expanded, ~totalItems) => {
    <article className={Cx.make(["p-6", Cx.ifTrue("shadow-lg", expanded)])}>
      <h3 className="text-xl font-semibold mb-4">
        {React.string(groupName)}
      </h3>
      <Level4
        title="First Item"
        description="Description A"
        isHighlighted=true
        itemCount=totalItems
      />
      <Level4
        title="Second Item"
        description="Description B"
        isHighlighted=false
        itemCount={totalItems / 2}
      />
    </article>;
  };
};

module Level2 = {
  [@react.component]
  let make = (~sectionTitle, ~isVisible) => {
    <div
      className={Cx.make([
        "container mx-auto",
        Cx.ifTrue("block", isVisible),
      ])}>
      <h2 className="text-2xl font-bold mb-6">
        {React.string(sectionTitle)}
      </h2>
      <Level3 groupName="Group Alpha" expanded=true totalItems=42 />
      <Level3 groupName="Group Beta" expanded=false totalItems=17 />
    </div>;
  };
};

module Level1 = {
  [@react.component]
  let make = (~pageTitle) => {
    <main className="min-h-screen bg-gray-100 py-8">
      <h1 className="text-4xl font-extrabold text-center mb-8">
        {React.string(pageTitle)}
      </h1>
      <Level2 sectionTitle="Primary Section" isVisible=true />
      <Level2 sectionTitle="Secondary Section" isVisible=true />
    </main>;
  };
};

[@react.component]
let make = () => <Level1 pageTitle="Shallow Tree Benchmark" />;
