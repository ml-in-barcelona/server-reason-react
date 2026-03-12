/* Scenario: Blog Article Page
      Article with comments, sidebar, rich content
      Purpose: Test content-heavy page rendering
   */

type comment = {
  id: int,
  author: string,
  avatar: string,
  content: string,
  date: string,
  likes: int,
  replies: array(comment),
};

let generateComments = (count, depth) => {
  let authors = [|"Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"|];
  let avatars = [|"A", "B", "C", "D", "E", "F"|];
  Array.init(count, i => {
    {
      id: i + 1,
      author: authors[i mod Array.length(authors)],
      avatar: avatars[i mod Array.length(avatars)],
      content:
        Printf.sprintf(
          "This is comment #%d. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
          i + 1,
        ),
      date: Printf.sprintf("%d hours ago", 1 + i mod 24),
      likes: i * 3 mod 50,
      replies:
        depth > 0
          ? Array.init(i mod 3, j => {
              {
                id: i * 100 + j,
                author: authors[(i + j + 1) mod Array.length(authors)],
                avatar: avatars[(i + j + 1) mod Array.length(avatars)],
                content:
                  Printf.sprintf("Reply to comment #%d. Great point!", i + 1),
                date: Printf.sprintf("%d minutes ago", 5 + j * 10),
                likes: j * 2,
                replies: [||],
              }
            })
          : [||],
    }
  });
};

module rec CommentComponent: {
  [@react.component]
  let make: (~comment: comment, ~depth: int) => React.element;
} = {
  [@react.component]
  let make = (~comment, ~depth) => {
    <div
      className={Cx.make([
        "py-4",
        depth > 0
          ? "ml-12 border-l-2 border-gray-100 pl-4"
          : "border-b border-gray-100",
      ])}>
      <div className="flex items-start gap-4">
        <div
          className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
          <span className="text-lg"> {React.string(comment.avatar)} </span>
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-semibold text-gray-900">
              {React.string(comment.author)}
            </span>
            <span className="text-sm text-gray-500">
              {React.string(comment.date)}
            </span>
          </div>
          <p className="text-gray-700 mb-3">
            {React.string(comment.content)}
          </p>
          <div className="flex items-center gap-4 text-sm">
            <button
              className="text-gray-500 hover:text-blue-600 flex items-center gap-1">
              <span> {React.string("👍")} </span>
              <span> {React.int(comment.likes)} </span>
            </button>
            <button className="text-gray-500 hover:text-blue-600">
              {React.string("Reply")}
            </button>
            <button className="text-gray-500 hover:text-blue-600">
              {React.string("Share")}
            </button>
          </div>
          {Array.length(comment.replies) > 0
             ? <div className="mt-4">
                 {React.array(
                    Array.map(
                      reply =>
                        <CommentComponent
                          key={Int.to_string(reply.id)}
                          comment=reply
                          depth={depth + 1}
                        />,
                      comment.replies,
                    ),
                  )}
               </div>
             : React.null}
        </div>
      </div>
    </div>;
  };
};

module ArticleContent = {
  [@react.component]
  let make = () => {
    <article className="prose prose-lg max-w-none">
      <p className="text-xl text-gray-600 leading-relaxed mb-8">
        {React.string(
           "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
         )}
      </p>
      <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">
        {React.string("Introduction")}
      </h2>
      <p className="text-gray-700 mb-4">
        {React.string(
           "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
         )}
      </p>
      <p className="text-gray-700 mb-4">
        {React.string(
           "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.",
         )}
      </p>
      <blockquote
        className="border-l-4 border-blue-500 pl-4 py-2 my-6 bg-blue-50 rounded-r">
        <p className="text-gray-700 italic">
          {React.string(
             "\"Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.\"",
           )}
        </p>
        <cite className="text-sm text-gray-500">
          {React.string("— Famous Author")}
        </cite>
      </blockquote>
      <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">
        {React.string("Key Concepts")}
      </h2>
      <p className="text-gray-700 mb-4">
        {React.string(
           "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.",
         )}
      </p>
      <ul className="list-disc list-inside space-y-2 mb-6">
        <li className="text-gray-700">
          {React.string(
             "Ut enim ad minima veniam, quis nostrum exercitationem",
           )}
        </li>
        <li className="text-gray-700">
          {React.string(
             "Corporis suscipit laboriosam, nisi ut aliquid ex ea commodi",
           )}
        </li>
        <li className="text-gray-700">
          {React.string(
             "Quis autem vel eum iure reprehenderit qui in ea voluptate",
           )}
        </li>
        <li className="text-gray-700">
          {React.string(
             "At vero eos et accusamus et iusto odio dignissimos ducimus",
           )}
        </li>
      </ul>
      <div className="bg-gray-100 rounded-lg p-6 my-6">
        <h3 className="font-bold text-gray-900 mb-2">
          {React.string("💡 Pro Tip")}
        </h3>
        <p className="text-gray-700">
          {React.string(
             "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae.",
           )}
        </p>
      </div>
      <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">
        {React.string("Code Example")}
      </h2>
      <pre
        className="bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto mb-6">
        <code>
          {React.string(
             {|let example = () => {
  let value = computeValue();
  let result = transform(value);
  process(result);
};|},
           )}
        </code>
      </pre>
      <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">
        {React.string("Conclusion")}
      </h2>
      <p className="text-gray-700 mb-4">
        {React.string(
           "Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.",
         )}
      </p>
    </article>;
  };
};

module Sidebar = {
  [@react.component]
  let make = () => {
    let relatedPosts = [|
      "Understanding Server-Side Rendering",
      "The Future of Web Development",
      "Performance Optimization Tips",
      "Building Scalable Applications",
      "Modern JavaScript Frameworks",
    |];

    let tags = [|
      "React",
      "SSR",
      "Performance",
      "JavaScript",
      "OCaml",
      "Web Development",
      "Tutorial",
    |];

    <aside className="w-80 flex-shrink-0">
      <div className="sticky top-8 space-y-8">
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <div className="flex items-center gap-4 mb-4">
            <div
              className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
              <span className="text-2xl"> {React.string("👨")} </span>
            </div>
            <div>
              <h3 className="font-bold text-gray-900">
                {React.string("John Developer")}
              </h3>
              <p className="text-sm text-gray-500">
                {React.string("Senior Engineer")}
              </p>
            </div>
          </div>
          <p className="text-gray-600 text-sm mb-4">
            {React.string(
               "Writing about web development, performance, and the joy of coding. 10+ years of experience building things for the web.",
             )}
          </p>
          <button
            className="w-full py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
            {React.string("Follow")}
          </button>
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold text-gray-900 mb-4">
            {React.string("Related Posts")}
          </h3>
          <ul className="space-y-3">
            {React.array(
               Array.mapi(
                 (i, title) =>
                   <li key={Int.to_string(i)}>
                     <a
                       href="#"
                       className="text-gray-700 hover:text-blue-600 text-sm">
                       {React.string(title)}
                     </a>
                   </li>,
                 relatedPosts,
               ),
             )}
          </ul>
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold text-gray-900 mb-4">
            {React.string("Tags")}
          </h3>
          <div className="flex flex-wrap gap-2">
            {React.array(
               Array.mapi(
                 (i, tag) =>
                   <a
                     key={Int.to_string(i)}
                     href={Printf.sprintf(
                       "/tag/%s",
                       String.lowercase_ascii(tag),
                     )}
                     className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm hover:bg-gray-200">
                     {React.string(tag)}
                   </a>,
                 tags,
               ),
             )}
          </div>
        </div>
        <div
          className="bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl p-6 text-white">
          <h3 className="font-bold mb-2"> {React.string("📧 Newsletter")} </h3>
          <p className="text-sm text-blue-100 mb-4">
            {React.string("Get weekly insights delivered to your inbox.")}
          </p>
          <input
            type_="email"
            placeholder="your@email.com"
            className="w-full px-4 py-2 rounded-lg text-gray-900 mb-3"
          />
          <button
            className="w-full py-2 bg-white text-blue-600 rounded-lg font-medium hover:bg-gray-100">
            {React.string("Subscribe")}
          </button>
        </div>
      </div>
    </aside>;
  };
};

module CommentsSection = {
  [@react.component]
  let make = (~comments) => {
    <section className="mt-12">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">
        {React.string(
           Printf.sprintf("Comments (%d)", Array.length(comments)),
         )}
      </h2>
      <div className="bg-gray-50 rounded-xl p-6 mb-8">
        <h3 className="font-medium text-gray-900 mb-4">
          {React.string("Leave a comment")}
        </h3>
        <textarea
          rows=4
          placeholder="Share your thoughts..."
          className="w-full px-4 py-3 border border-gray-200 rounded-lg resize-none"
        />
        <div className="flex justify-end mt-4">
          <button
            className="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
            {React.string("Post Comment")}
          </button>
        </div>
      </div>
      <div>
        {React.array(
           Array.map(
             comment =>
               <CommentComponent
                 key={Int.to_string(comment.id)}
                 comment
                 depth=0
               />,
             comments,
           ),
         )}
      </div>
      <div className="mt-8 text-center">
        <button
          className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50">
          {React.string("Load more comments")}
        </button>
      </div>
    </section>;
  };
};

module Page = {
  [@react.component]
  let make = (~commentCount) => {
    let comments = generateComments(commentCount, 1);

    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>
          {React.string("Blog Post - Understanding Server-Side Rendering")}
        </title>
      </head>
      <body className="bg-gray-50">
        <header className="bg-white border-b border-gray-200">
          <div className="container mx-auto px-4 py-4">
            <nav className="flex items-center justify-between">
              <a href="/" className="text-2xl font-bold text-gray-900">
                {React.string("TechBlog")}
              </a>
              <div className="flex items-center gap-6">
                {React.array(
                   Array.map(
                     item =>
                       <a
                         key=item
                         href="#"
                         className="text-gray-600 hover:text-gray-900">
                         {React.string(item)}
                       </a>,
                     [|"Articles", "Tutorials", "Podcast", "About"|],
                   ),
                 )}
                <button
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium">
                  {React.string("Subscribe")}
                </button>
              </div>
            </nav>
          </div>
        </header>
        <div
          className="bg-gradient-to-br from-blue-900 to-purple-900 text-white py-16">
          <div className="container mx-auto px-4">
            <div className="max-w-3xl">
              <div className="flex items-center gap-2 mb-4">
                <span
                  className="px-3 py-1 bg-blue-500 rounded-full text-sm font-medium">
                  {React.string("Tutorial")}
                </span>
                <span className="text-blue-200">
                  {React.string("• 15 min read")}
                </span>
              </div>
              <h1 className="text-4xl md:text-5xl font-bold mb-4">
                {React.string(
                   "Understanding Server-Side Rendering in Modern Web Applications",
                 )}
              </h1>
              <p className="text-xl text-blue-100 mb-6">
                {React.string(
                   "A comprehensive guide to SSR, its benefits, and how to implement it effectively in your projects.",
                 )}
              </p>
              <div className="flex items-center gap-4">
                <div
                  className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
                  <span className="text-xl"> {React.string("👨")} </span>
                </div>
                <div>
                  <p className="font-medium">
                    {React.string("John Developer")}
                  </p>
                  <p className="text-sm text-blue-200">
                    {React.string("Published on November 15, 2024")}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        <main className="container mx-auto px-4 py-12">
          <div className="flex gap-12">
            <div className="flex-1 max-w-3xl">
              <div
                className="flex items-center gap-4 mb-8 pb-8 border-b border-gray-200">
                <span className="text-gray-500 text-sm">
                  {React.string("Share:")}
                </span>
                {React.array(
                   Array.map(
                     ((icon, label)) =>
                       <button
                         key=label
                         className="p-2 bg-gray-100 rounded-full hover:bg-gray-200"
                         ariaLabel=label>
                         {React.string(icon)}
                       </button>,
                     [|
                       ("🐦", "Twitter"),
                       ("📘", "Facebook"),
                       ("💼", "LinkedIn"),
                       ("📋", "Copy Link"),
                     |],
                   ),
                 )}
              </div>
              <ArticleContent />
              <CommentsSection comments />
            </div>
            <Sidebar />
          </div>
        </main>
        <footer className="bg-gray-900 text-white py-12">
          <div className="container mx-auto px-4 text-center">
            <p className="text-gray-400">
              {React.string("© 2024 TechBlog. All rights reserved.")}
            </p>
          </div>
        </footer>
      </body>
    </html>;
  };
};

/* Different comment counts */
module Blog10 = {
  [@react.component]
  let make = () => <Page commentCount=10 />;
};

module Blog50 = {
  [@react.component]
  let make = () => <Page commentCount=50 />;
};

module Blog100 = {
  [@react.component]
  let make = () => <Page commentCount=100 />;
};

[@react.component]
let make = () => <Blog50 />;
