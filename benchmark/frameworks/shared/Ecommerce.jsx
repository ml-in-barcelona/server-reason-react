// Port of benchmark/scenarios/Ecommerce.re
// Purpose: real-world SSR performance for e-commerce page

import React from "react";
import { cx } from "./cx.js";

const brands = ["Apple", "Samsung", "Sony", "LG", "Nike", "Adidas", "Microsoft", "Google"];
const categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Toys"];
const tagOptions = ["Best Seller", "New", "Sale", "Limited", "Trending", "Eco-Friendly"];

const generateProducts = (count) =>
  Array.from({ length: count }, (_, i) => {
    const id = i + 1;
    const hasDiscount = i % 3 === 0;
    const basePrice = 19.99 + (i % 500);
    return {
      id,
      name: `Product ${id} - Premium Edition`,
      brand: brands[i % brands.length],
      price: hasDiscount ? basePrice * 0.8 : basePrice,
      originalPrice: hasDiscount ? basePrice : null,
      rating: 3.0 + (i % 21) / 10.0,
      reviewCount: 10 + (i % 5000),
      image: `https://picsum.photos/seed/${id}/300/300`,
      category: categories[i % categories.length],
      tags: Array.from({ length: 1 + (i % 3) }, (_, j) => tagOptions[(i + j) % tagOptions.length]),
      inStock: i % 10 !== 0,
      freeShipping: i % 4 === 0,
      prime: i % 2 === 0,
    };
  });

const StarRating = ({ rating, count }) => {
  const fullStars = Math.trunc(rating);
  const hasHalfStar = rating - fullStars >= 0.5;
  return (
    <div className="flex items-center gap-1">
      <div className="flex text-yellow-400">
        {Array.from({ length: 5 }, (_, i) => (
          <span key={String(i)}>
            {i < fullStars ? "★" : i === fullStars && hasHalfStar ? "⯨" : "☆"}
          </span>
        ))}
      </div>
      <span className="text-sm text-gray-500">
        {`${rating.toFixed(1)} (${count})`}
      </span>
    </div>
  );
};

const PriceBadge = ({ price, originalPrice }) => (
  <div className="flex items-baseline gap-2">
    <span className="text-2xl font-bold text-gray-900">{`$${price.toFixed(2)}`}</span>
    {originalPrice !== null && (
      <>
        <span className="text-sm text-gray-500 line-through">{`$${originalPrice.toFixed(2)}`}</span>
        <span className="text-sm font-medium text-red-600">
          {`${Math.round((1.0 - price / originalPrice) * 100)}% off`}
        </span>
      </>
    )}
  </div>
);

const ProductCard = ({ product }) => (
  <article className="group relative bg-white rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden">
    <div className="aspect-square overflow-hidden bg-gray-100">
      <img
        src={product.image}
        alt={product.name}
        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
        loading="lazy"
      />
      <div className="absolute top-2 left-2 flex flex-col gap-1">
        {product.tags.map((tag, i) => (
          <span
            key={String(i)}
            className="px-2 py-1 text-xs font-medium bg-black/70 text-white rounded"
          >
            {tag}
          </span>
        ))}
      </div>
      <button
        className="absolute top-2 right-2 p-2 bg-white/90 rounded-full hover:bg-white transition-colors"
        aria-label="Add to wishlist"
      >
        ♡
      </button>
    </div>
    <div className="p-4">
      <div className="mb-1">
        <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">
          {product.brand}
        </span>
      </div>
      <h3 className="text-sm font-medium text-gray-900 mb-2 line-clamp-2">
        <a href={`/product/${product.id}`} className="hover:text-blue-600">
          {product.name}
        </a>
      </h3>
      <StarRating rating={product.rating} count={product.reviewCount} />
      <div className="mt-2">
        <PriceBadge price={product.price} originalPrice={product.originalPrice} />
      </div>
      <div className="mt-2 flex items-center gap-2 text-xs">
        {product.prime && <span className="text-blue-600 font-medium">✓ Prime</span>}
        {product.freeShipping && <span className="text-green-600">Free Shipping</span>}
      </div>
      <div className="mt-3">
        {product.inStock ? (
          <span className="text-sm text-green-600">In Stock</span>
        ) : (
          <span className="text-sm text-red-600">Out of Stock</span>
        )}
      </div>
      <button
        className={cx([
          "mt-3 w-full py-2 px-4 rounded-lg font-medium transition-colors",
          product.inStock
            ? "bg-yellow-400 hover:bg-yellow-500 text-gray-900"
            : "bg-gray-200 text-gray-500 cursor-not-allowed",
        ])}
        disabled={!product.inStock}
      >
        {product.inStock ? "Add to Cart" : "Unavailable"}
      </button>
    </div>
  </article>
);

const FilterSidebar = () => {
  const priceRanges = [
    ["Under $25", 25],
    ["$25 - $50", 50],
    ["$50 - $100", 100],
    ["$100 - $200", 200],
    ["Over $200", 999],
  ];
  const filterCategories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Toys"];
  const filterBrands = ["Apple", "Samsung", "Sony", "LG", "Nike", "Adidas", "Microsoft", "Google"];

  return (
    <aside className="w-64 flex-shrink-0">
      <div className="sticky top-4 space-y-6">
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">Category</h3>
          <div className="space-y-2">
            {filterCategories.map((cat) => (
              <label key={cat} className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="rounded text-blue-600" />
                <span className="text-sm text-gray-700">{cat}</span>
              </label>
            ))}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">Price</h3>
          <div className="space-y-2">
            {priceRanges.map(([label]) => (
              <label key={label} className="flex items-center gap-2 cursor-pointer">
                <input type="radio" name="price" className="text-blue-600" />
                <span className="text-sm text-gray-700">{label}</span>
              </label>
            ))}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">Rating</h3>
          <div className="space-y-2">
            {Array.from({ length: 4 }, (_, i) => {
              const stars = 4 - i;
              return (
                <label key={String(stars)} className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" className="rounded text-blue-600" />
                  <span className="text-yellow-400">{"★".repeat(stars)}</span>
                  <span className="text-sm text-gray-500">& Up</span>
                </label>
              );
            })}
          </div>
        </div>
        <div className="bg-white rounded-lg p-4 shadow-sm">
          <h3 className="font-medium text-gray-900 mb-3">Brand</h3>
          <div className="space-y-2">
            {filterBrands.map((brand) => (
              <label key={brand} className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="rounded text-blue-600" />
                <span className="text-sm text-gray-700">{brand}</span>
              </label>
            ))}
          </div>
        </div>
      </div>
    </aside>
  );
};

const ProductGrid = ({ products }) => (
  <div className="flex-1">
    <div className="mb-4 flex items-center justify-between">
      <p className="text-sm text-gray-600">{`Showing ${products.length} results`}</p>
      <select className="px-3 py-2 border rounded-lg text-sm">
        <option>Sort by: Featured</option>
        <option>Price: Low to High</option>
        <option>Price: High to Low</option>
        <option>Avg. Customer Review</option>
        <option>Newest Arrivals</option>
      </select>
    </div>
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {products.map((product) => (
        <ProductCard key={String(product.id)} product={product} />
      ))}
    </div>
    <nav className="mt-8 flex items-center justify-center gap-2">
      <button className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">Previous</button>
      {Array.from({ length: 5 }, (_, i) => (
        <button
          key={String(i)}
          className={cx([
            "px-4 py-2 rounded-lg text-sm",
            i === 0 ? "bg-blue-600 text-white" : "border hover:bg-gray-50",
          ])}
        >
          {i + 1}
        </button>
      ))}
      <span className="px-2">...</span>
      <button className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">20</button>
      <button className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">Next</button>
    </nav>
  </div>
);

const Header = () => (
  <header className="bg-gray-900 text-white">
    <div className="container mx-auto px-4">
      <div className="py-2 text-xs border-b border-gray-700 flex justify-between">
        <div className="flex gap-4">
          <a href="#" className="hover:text-gray-300">Help</a>
          <a href="#" className="hover:text-gray-300">Track Order</a>
        </div>
        <div className="flex gap-4">
          <a href="#" className="hover:text-gray-300">Sell on Store</a>
          <a href="#" className="hover:text-gray-300">Language: EN</a>
        </div>
      </div>
      <div className="py-4 flex items-center gap-8">
        <a href="/" className="text-2xl font-bold">STORE</a>
        <div className="flex-1 max-w-2xl">
          <div className="flex">
            <select className="px-3 py-2 bg-gray-100 text-gray-900 rounded-l-lg border-r text-sm">
              <option>All Categories</option>
            </select>
            <input
              type="search"
              placeholder="Search products..."
              className="flex-1 px-4 py-2 text-gray-900"
            />
            <button className="px-6 py-2 bg-yellow-400 text-gray-900 rounded-r-lg font-medium hover:bg-yellow-500">
              Search
            </button>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <a href="/account" className="flex flex-col items-center text-xs hover:text-gray-300">
            <span className="text-lg">👤</span>
            Account
          </a>
          <a href="/orders" className="flex flex-col items-center text-xs hover:text-gray-300">
            <span className="text-lg">📦</span>
            Orders
          </a>
          <a href="/cart" className="flex flex-col items-center text-xs hover:text-gray-300 relative">
            <span className="text-lg">🛒</span>
            Cart
            <span className="absolute -top-1 -right-1 bg-yellow-400 text-gray-900 text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium">
              3
            </span>
          </a>
        </div>
      </div>
      <nav className="py-2 flex gap-6 text-sm">
        {["Today's Deals", "Customer Service", "Registry", "Gift Cards", "Sell"].map((item) => (
          <a key={item} href="#" className="hover:text-gray-300">{item}</a>
        ))}
      </nav>
    </div>
  </header>
);

const footerSections = [
  ["Get to Know Us", ["Careers", "Blog", "About", "Investor Relations"]],
  ["Make Money with Us", ["Sell products", "Become an Affiliate", "Advertise", "Self-Publish"]],
  ["Payment Products", ["Business Card", "Shop with Points", "Reload Balance", "Currency Converter"]],
  ["Let Us Help You", ["Your Account", "Returns Centre", "Recalls", "Help"]],
];

const Page = ({ products }) => (
  <html lang="en">
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Shop - Products</title>
    </head>
    <body className="bg-gray-100 min-h-screen">
      <Header />
      <div className="container mx-auto px-4 py-4">
        <nav className="text-sm text-gray-500">
          <a href="/" className="hover:text-gray-700">Home</a>
          {" / "}
          <a href="/products" className="hover:text-gray-700">Products</a>
          {" / "}
          <span className="text-gray-900">All</span>
        </nav>
      </div>
      <main className="container mx-auto px-4 py-6">
        <div className="flex gap-8">
          <FilterSidebar />
          <ProductGrid products={products} />
        </div>
      </main>
      <footer className="bg-gray-900 text-white mt-12 py-12">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-4 gap-8">
            {footerSections.map(([title, links]) => (
              <div key={title}>
                <h4 className="font-medium mb-4">{title}</h4>
                <ul className="space-y-2 text-sm text-gray-400">
                  {links.map((link) => (
                    <li key={link}>
                      <a href="#" className="hover:text-white">{link}</a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </footer>
    </body>
  </html>
);

// Match the OCaml "module Products24 = { let products = generateProducts(24) }"
// idiom: generate once at module load, then reuse.
const products24 = generateProducts(24);
const products48 = generateProducts(48);
const products100 = generateProducts(100);

export const Ecommerce24 = () => <Page products={products24} />;
export const Ecommerce48 = () => <Page products={products48} />;
export const Ecommerce100 = () => <Page products={products100} />;
