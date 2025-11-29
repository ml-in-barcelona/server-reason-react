/* Scenario: Wide Tree
      Many siblings at the same level (tests list/array rendering)
      Purpose: Test horizontal scaling and sibling handling
   */

module Card = {
  [@react.component]
  let make = (~id, ~title, ~description, ~price, ~rating, ~inStock) => {
    <article
      key={Int.to_string(id)}
      className={Cx.make([
        "border rounded-lg p-4 shadow-sm",
        Cx.ifTrue("opacity-50", !inStock),
      ])}>
      <div className="flex justify-between items-start mb-2">
        <h3 className="font-semibold text-lg"> {React.string(title)} </h3>
        <span className="text-xs bg-gray-100 px-2 py-1 rounded">
          {React.string(Printf.sprintf("#%d", id))}
        </span>
      </div>
      <p className="text-gray-600 text-sm mb-3">
        {React.string(description)}
      </p>
      <div className="flex justify-between items-center">
        <span className="text-xl font-bold text-green-600">
          {React.string(Printf.sprintf("$%.2f", price))}
        </span>
        <div className="flex items-center gap-1">
          <span className="text-yellow-500"> {React.string("★")} </span>
          <span className="text-sm">
            {React.string(Printf.sprintf("%.1f", rating))}
          </span>
        </div>
      </div>
      <div className="mt-2">
        {inStock
           ? <span className="text-green-500 text-sm">
               {React.string("In Stock")}
             </span>
           : <span className="text-red-500 text-sm">
               {React.string("Out of Stock")}
             </span>}
      </div>
    </article>;
  };
};

let generateItems = count =>
  Array.init(
    count,
    i => {
      let id = i + 1;
      let title = Printf.sprintf("Product %d", id);
      let description =
        Printf.sprintf(
          "This is the description for product %d. It contains useful information.",
          id,
        );
      let price = 9.99 +. float_of_int(i mod 100);
      let rating = 3.0 +. float_of_int(i mod 20) /. 10.0;
      let inStock = i mod 7 != 0;
      (id, title, description, price, rating, inStock);
    },
  );

module Wide10 = {
  let items = generateItems(10);

  [@react.component]
  let make = () => {
    <div className="grid grid-cols-2 gap-4 p-4">
      {React.array(
         Array.map(
           ((id, title, description, price, rating, inStock)) =>
             <Card
               key={Int.to_string(id)}
               id
               title
               description
               price
               rating
               inStock
             />,
           items,
         ),
       )}
    </div>;
  };
};

module Wide100 = {
  let items = generateItems(100);

  [@react.component]
  let make = () => {
    <div className="grid grid-cols-4 gap-4 p-4">
      {React.array(
         Array.map(
           ((id, title, description, price, rating, inStock)) =>
             <Card
               key={Int.to_string(id)}
               id
               title
               description
               price
               rating
               inStock
             />,
           items,
         ),
       )}
    </div>;
  };
};

module Wide500 = {
  let items = generateItems(500);

  [@react.component]
  let make = () => {
    <div className="grid grid-cols-5 gap-4 p-4">
      {React.array(
         Array.map(
           ((id, title, description, price, rating, inStock)) =>
             <Card
               key={Int.to_string(id)}
               id
               title
               description
               price
               rating
               inStock
             />,
           items,
         ),
       )}
    </div>;
  };
};

module Wide1000 = {
  let items = generateItems(1000);

  [@react.component]
  let make = () => {
    <div className="grid grid-cols-5 gap-4 p-4">
      {React.array(
         Array.map(
           ((id, title, description, price, rating, inStock)) =>
             <Card
               key={Int.to_string(id)}
               id
               title
               description
               price
               rating
               inStock
             />,
           items,
         ),
       )}
    </div>;
  };
};

[@react.component]
let make = () => <Wide100 />;
