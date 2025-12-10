/* Scenario: E-commerce Page
      Realistic product listing page with complex UI patterns
      Purpose: Test real-world SSR performance for e-commerce use case
   */

type product = {
  id: int,
  name: string,
  brand: string,
  price: float,
  originalPrice: option(float),
  rating: float,
  reviewCount: int,
  image: string,
  category: string,
  tags: array(string),
  inStock: bool,
  freeShipping: bool,
  prime: bool,
};

let generateProducts = count => {
  let brands = [|
    "Apple",
    "Samsung",
    "Sony",
    "LG",
    "Nike",
    "Adidas",
    "Microsoft",
    "Google",
  |];
  let categories = [|
    "Electronics",
    "Clothing",
    "Home",
    "Sports",
    "Books",
    "Toys",
  |];
  let tagOptions = [|
    "Best Seller",
    "New",
    "Sale",
    "Limited",
    "Trending",
    "Eco-Friendly",
  |];
  Array.init(
    count,
    i => {
      let id = i + 1;
      let hasDiscount = i mod 3 == 0;
      let basePrice = 19.99 +. float_of_int(i mod 500);
      {
        id,
        name: Printf.sprintf("Product %d - Premium Edition", id),
        brand: brands[i mod Array.length(brands)],
        price: hasDiscount ? basePrice *. 0.8 : basePrice,
        originalPrice: hasDiscount ? Some(basePrice) : None,
        rating: 3.0 +. float_of_int(i mod 21) /. 10.0,
        reviewCount: 10 + i mod 5000,
        image: Printf.sprintf("https://picsum.photos/seed/%d/300/300", id),
        category: categories[i mod Array.length(categories)],
        tags:
          Array.init(1 + i mod 3, j =>
            tagOptions[(i + j) mod Array.length(tagOptions)]
          ),
        inStock: i mod 10 != 0,
        freeShipping: i mod 4 == 0,
        prime: i mod 2 == 0,
      };
    },
  );
};

module StarRating = {
  [@react.component]
  let make = (~rating, ~count) => {
    let fullStars = int_of_float(rating);
    let hasHalfStar = rating -. float_of_int(fullStars) >= 0.5;

    <div className="flex items-center gap-1">
      <div className="flex text-yellow-400">
        {React.array(
           Array.init(5, i =>
             <span key={Int.to_string(i)}>
               {React.string(
                  i < fullStars
                    ? "★" : i == fullStars && hasHalfStar ? "⯨" : "☆",
                )}
             </span>
           ),
         )}
      </div>
      <span className="text-sm text-gray-500">
        {React.string(Printf.sprintf("%.1f (%d)", rating, count))}
      </span>
    </div>;
  };
};

module PriceBadge = {
  [@react.component]
  let make = (~price, ~originalPrice) => {
    <div className="flex items-baseline gap-2">
      <span className="text-2xl font-bold text-gray-900">
        {React.string(Printf.sprintf("$%.2f", price))}
      </span>
      {switch (originalPrice) {
       | Some(orig) =>
         <>
           <span className="text-sm text-gray-500 line-through">
             {React.string(Printf.sprintf("$%.2f", orig))}
           </span>
           <span className="text-sm font-medium text-red-600">
             {React.string(
                Printf.sprintf("%.0f%% off", (1.0 -. price /. orig) *. 100.0),
              )}
           </span>
         </>
       | None => React.null
       }}
    </div>;
  };
};

module ProductCard = {
  [@react.component]
  let make = (~product) => {
    <article
      className="group relative bg-white rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden">
      <div className="aspect-square overflow-hidden bg-gray-100">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          loading="lazy"
        />
        <div className="absolute top-2 left-2 flex flex-col gap-1">
          {React.array(
             Array.mapi(
               (i, tag) =>
                 <span
                   key={Int.to_string(i)}
                   className="px-2 py-1 text-xs font-medium bg-black/70 text-white rounded">
                   {React.string(tag)}
                 </span>,
               product.tags,
             ),
           )}
        </div>
        <button
          className="absolute top-2 right-2 p-2 bg-white/90 rounded-full hover:bg-white transition-colors"
          ariaLabel="Add to wishlist">
          {React.string("♡")}
        </button>
      </div>
      <div className="p-4">
        <div className="mb-1">
          <span
            className="text-xs font-medium text-gray-500 uppercase tracking-wide">
            {React.string(product.brand)}
          </span>
        </div>
        <h3 className="text-sm font-medium text-gray-900 mb-2 line-clamp-2">
          <a
            href={Printf.sprintf("/product/%d", product.id)}
            className="hover:text-blue-600">
            {React.string(product.name)}
          </a>
        </h3>
        <StarRating rating={product.rating} count={product.reviewCount} />
        <div className="mt-2">
          <PriceBadge
            price={product.price}
            originalPrice={product.originalPrice}
          />
        </div>
        <div className="mt-2 flex items-center gap-2 text-xs">
          {product.prime
             ? <span className="text-blue-600 font-medium">
                 {React.string("✓ Prime")}
               </span>
             : React.null}
          {product.freeShipping
             ? <span className="text-green-600">
                 {React.string("Free Shipping")}
               </span>
             : React.null}
        </div>
        <div className="mt-3">
          {product.inStock
             ? <span className="text-sm text-green-600">
                 {React.string("In Stock")}
               </span>
             : <span className="text-sm text-red-600">
                 {React.string("Out of Stock")}
               </span>}
        </div>
        <button
          className={Cx.make([
            "mt-3 w-full py-2 px-4 rounded-lg font-medium transition-colors",
            product.inStock
              ? "bg-yellow-400 hover:bg-yellow-500 text-gray-900"
              : "bg-gray-200 text-gray-500 cursor-not-allowed",
          ])}
          disabled={!product.inStock}>
          {React.string(product.inStock ? "Add to Cart" : "Unavailable")}
        </button>
      </div>
    </article>;
  };
};

module FilterSidebar = {
  [@react.component]
  let make = () => {
    <aside className="w-64 flex-shrink-0">
      <div className="sticky top-4 space-y-6">
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">
            {React.string("Category")}
          </h3>
          <div className="space-y-2">
            {React.array(
               Array.map(
                 cat =>
                   <label
                     key=cat
                     className="flex items-center gap-2 cursor-pointer">
                     <input
                       type_="checkbox"
                       className="rounded text-blue-600"
                     />
                     <span className="text-sm text-gray-700">
                       {React.string(cat)}
                     </span>
                   </label>,
                 [|
                   "Electronics",
                   "Clothing",
                   "Home",
                   "Sports",
                   "Books",
                   "Toys",
                 |],
               ),
             )}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">
            {React.string("Price")}
          </h3>
          <div className="space-y-2">
            {React.array(
               Array.map(
                 ((label, _)) =>
                   <label
                     key=label
                     className="flex items-center gap-2 cursor-pointer">
                     <input
                       type_="radio"
                       name="price"
                       className="text-blue-600"
                     />
                     <span className="text-sm text-gray-700">
                       {React.string(label)}
                     </span>
                   </label>,
                 [|
                   ("Under $25", 25),
                   ("$25 - $50", 50),
                   ("$50 - $100", 100),
                   ("$100 - $200", 200),
                   ("Over $200", 999),
                 |],
               ),
             )}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">
            {React.string("Rating")}
          </h3>
          <div className="space-y-2">
            {React.array(
               Array.init(
                 4,
                 i => {
                   let stars = 4 - i;
                   <label
                     key={Int.to_string(stars)}
                     className="flex items-center gap-2 cursor-pointer">
                     <input
                       type_="checkbox"
                       className="rounded text-blue-600"
                     />
                     <span className="text-yellow-400">
                       {React.string(String.make(stars, {js|★|js}.[0]))}
                     </span>
                     <span className="text-sm text-gray-500">
                       {React.string("& Up")}
                     </span>
                   </label>;
                 },
               ),
             )}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">
            {React.string("Brand")}
          </h3>
          <div className="space-y-2">
            {React.array(
               Array.map(
                 brand =>
                   <label
                     key=brand
                     className="flex items-center gap-2 cursor-pointer">
                     <input
                       type_="checkbox"
                       className="rounded text-blue-600"
                     />
                     <span className="text-sm text-gray-700">
                       {React.string(brand)}
                     </span>
                   </label>,
                 [|
                   "Apple",
                   "Samsung",
                   "Sony",
                   "LG",
                   "Nike",
                   "Adidas",
                   "Microsoft",
                   "Google",
                 |],
               ),
             )}
          </div>
        </div>
      </div>
    </aside>;
  };
};

module ProductGrid = {
  [@react.component]
  let make = (~products) => {
    <div className="flex-1">
      <div className="mb-4 flex items-center justify-between">
        <p className="text-sm text-gray-600">
          {React.string(
             Printf.sprintf("Showing %d results", Array.length(products)),
           )}
        </p>
        <select className="px-3 py-2 border rounded-lg text-sm">
          <option> {React.string("Sort by: Featured")} </option>
          <option> {React.string("Price: Low to High")} </option>
          <option> {React.string("Price: High to Low")} </option>
          <option> {React.string("Avg. Customer Review")} </option>
          <option> {React.string("Newest Arrivals")} </option>
        </select>
      </div>
      <div
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {React.array(
           Array.map(
             product =>
               <ProductCard key={Int.to_string(product.id)} product />,
             products,
           ),
         )}
      </div>
      <nav className="mt-8 flex items-center justify-center gap-2">
        <button
          className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">
          {React.string("Previous")}
        </button>
        {React.array(
           Array.init(5, i =>
             <button
               key={Int.to_string(i)}
               className={Cx.make([
                 "px-4 py-2 rounded-lg text-sm",
                 i == 0 ? "bg-blue-600 text-white" : "border hover:bg-gray-50",
               ])}>
               {React.int(i + 1)}
             </button>
           ),
         )}
        <span className="px-2"> {React.string("...")} </span>
        <button
          className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">
          {React.int(20)}
        </button>
        <button
          className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">
          {React.string("Next")}
        </button>
      </nav>
    </div>;
  };
};

module Header = {
  [@react.component]
  let make = () => {
    <header className="bg-gray-900 text-white">
      <div className="container mx-auto px-4">
        <div
          className="py-2 text-xs border-b border-gray-700 flex justify-between">
          <div className="flex gap-4">
            <a href="#" className="hover:text-gray-300">
              {React.string("Help")}
            </a>
            <a href="#" className="hover:text-gray-300">
              {React.string("Track Order")}
            </a>
          </div>
          <div className="flex gap-4">
            <a href="#" className="hover:text-gray-300">
              {React.string("Sell on Store")}
            </a>
            <a href="#" className="hover:text-gray-300">
              {React.string("Language: EN")}
            </a>
          </div>
        </div>
        <div className="py-4 flex items-center gap-8">
          <a href="/" className="text-2xl font-bold">
            {React.string("STORE")}
          </a>
          <div className="flex-1 max-w-2xl">
            <div className="flex">
              <select
                className="px-3 py-2 bg-gray-100 text-gray-900 rounded-l-lg border-r text-sm">
                <option> {React.string("All Categories")} </option>
              </select>
              <input
                type_="search"
                placeholder="Search products..."
                className="flex-1 px-4 py-2 text-gray-900"
              />
              <button
                className="px-6 py-2 bg-yellow-400 text-gray-900 rounded-r-lg font-medium hover:bg-yellow-500">
                {React.string("Search")}
              </button>
            </div>
          </div>
          <div className="flex items-center gap-6">
            <a
              href="/account"
              className="flex flex-col items-center text-xs hover:text-gray-300">
              <span className="text-lg"> {React.string("👤")} </span>
              {React.string("Account")}
            </a>
            <a
              href="/orders"
              className="flex flex-col items-center text-xs hover:text-gray-300">
              <span className="text-lg"> {React.string("📦")} </span>
              {React.string("Orders")}
            </a>
            <a
              href="/cart"
              className="flex flex-col items-center text-xs hover:text-gray-300 relative">
              <span className="text-lg"> {React.string("🛒")} </span>
              {React.string("Cart")}
              <span
                className="absolute -top-1 -right-1 bg-yellow-400 text-gray-900 text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium">
                {React.string("3")}
              </span>
            </a>
          </div>
        </div>
        <nav className="py-2 flex gap-6 text-sm">
          {React.array(
             Array.map(
               item =>
                 <a key=item href="#" className="hover:text-gray-300">
                   {React.string(item)}
                 </a>,
               [|
                 "Today's Deals",
                 "Customer Service",
                 "Registry",
                 "Gift Cards",
                 "Sell",
               |],
             ),
           )}
        </nav>
      </div>
    </header>;
  };
};

module Page = {
  [@react.component]
  let make = (~products) => {
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title> {React.string("Shop - Products")} </title>
      </head>
      <body className="bg-gray-100 min-h-screen">
        <Header />
        <div className="container mx-auto px-4 py-4">
          <nav className="text-sm text-gray-500">
            <a href="/" className="hover:text-gray-700">
              {React.string("Home")}
            </a>
            {React.string(" / ")}
            <a href="/products" className="hover:text-gray-700">
              {React.string("Products")}
            </a>
            {React.string(" / ")}
            <span className="text-gray-900"> {React.string("All")} </span>
          </nav>
        </div>
        <main className="container mx-auto px-4 py-6">
          <div className="flex gap-8">
            <FilterSidebar />
            <ProductGrid products />
          </div>
        </main>
        <footer className="bg-gray-900 text-white mt-12 py-12">
          <div className="container mx-auto px-4">
            <div className="grid grid-cols-4 gap-8">
              {React.array(
                 Array.map(
                   ((title, links)) =>
                     <div key=title>
                       <h4 className="font-medium mb-4">
                         {React.string(title)}
                       </h4>
                       <ul className="space-y-2 text-sm text-gray-400">
                         {React.array(
                            Array.map(
                              link =>
                                <li key=link>
                                  <a href="#" className="hover:text-white">
                                    {React.string(link)}
                                  </a>
                                </li>,
                              links,
                            ),
                          )}
                       </ul>
                     </div>,
                   [|
                     (
                       "Get to Know Us",
                       [|"Careers", "Blog", "About", "Investor Relations"|],
                     ),
                     (
                       "Make Money with Us",
                       [|
                         "Sell products",
                         "Become an Affiliate",
                         "Advertise",
                         "Self-Publish",
                       |],
                     ),
                     (
                       "Payment Products",
                       [|
                         "Business Card",
                         "Shop with Points",
                         "Reload Balance",
                         "Currency Converter",
                       |],
                     ),
                     (
                       "Let Us Help You",
                       [|
                         "Your Account",
                         "Returns Centre",
                         "Recalls",
                         "Help",
                       |],
                     ),
                   |],
                 ),
               )}
            </div>
          </div>
        </footer>
      </body>
    </html>;
  };
};

/* Different sizes */
module Products24 = {
  let products = generateProducts(24);
  [@react.component]
  let make = () => <Page products />;
};

module Products48 = {
  let products = generateProducts(48);
  [@react.component]
  let make = () => <Page products />;
};

module Products100 = {
  let products = generateProducts(100);
  [@react.component]
  let make = () => <Page products />;
};

[@react.component]
let make = () => <Products48 />;
