// Port of benchmark/scenarios/Blog.re
// Purpose: content-heavy page rendering with nested comments

import React from "react";
import { cx } from "./cx.js";

const authors = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"];
const avatars = ["A", "B", "C", "D", "E", "F"];

const generateComments = (count, depth) =>
  Array.from({ length: count }, (_, i) => ({
    id: i + 1,
    author: authors[i % authors.length],
    avatar: avatars[i % avatars.length],
    content: `This is comment #${i + 1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.`,
    date: `${1 + (i % 24)} hours ago`,
    likes: (i * 3) % 50,
    replies:
      depth > 0
        ? Array.from({ length: i % 3 }, (_, j) => ({
            id: i * 100 + j,
            author: authors[(i + j + 1) % authors.length],
            avatar: avatars[(i + j + 1) % avatars.length],
            content: `Reply to comment #${i + 1}. Great point!`,
            date: `${5 + j * 10} minutes ago`,
            likes: j * 2,
            replies: [],
          }))
        : [],
  }));

const CommentComponent = ({ comment, depth }) => (
  <div
    className={cx([
      "py-4",
      depth > 0
        ? "ml-12 border-l-2 border-gray-100 pl-4"
        : "border-b border-gray-100",
    ])}
  >
    <div className="flex items-start gap-4">
      <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
        <span className="text-lg">{comment.avatar}</span>
      </div>
      <div className="flex-1">
        <div className="flex items-center gap-2 mb-1">
          <span className="font-semibold text-gray-900">{comment.author}</span>
          <span className="text-sm text-gray-500">{comment.date}</span>
        </div>
        <p className="text-gray-700 mb-3">{comment.content}</p>
        <div className="flex items-center gap-4 text-sm">
          <button className="text-gray-500 hover:text-blue-600 flex items-center gap-1">
            <span>👍</span>
            <span>{comment.likes}</span>
          </button>
          <button className="text-gray-500 hover:text-blue-600">Reply</button>
          <button className="text-gray-500 hover:text-blue-600">Share</button>
        </div>
        {comment.replies.length > 0 && (
          <div className="mt-4">
            {comment.replies.map((reply) => (
              <CommentComponent key={String(reply.id)} comment={reply} depth={depth + 1} />
            ))}
          </div>
        )}
      </div>
    </div>
  </div>
);

const ArticleContent = () => (
  <article className="prose prose-lg max-w-none">
    <p className="text-xl text-gray-600 leading-relaxed mb-8">
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.
    </p>
    <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">Introduction</h2>
    <p className="text-gray-700 mb-4">
      Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </p>
    <p className="text-gray-700 mb-4">
      Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.
    </p>
    <blockquote className="border-l-4 border-blue-500 pl-4 py-2 my-6 bg-blue-50 rounded-r">
      <p className="text-gray-700 italic">
        "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
      </p>
      <cite className="text-sm text-gray-500">— Famous Author</cite>
    </blockquote>
    <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">Key Concepts</h2>
    <p className="text-gray-700 mb-4">
      Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.
    </p>
    <ul className="list-disc list-inside space-y-2 mb-6">
      <li className="text-gray-700">Ut enim ad minima veniam, quis nostrum exercitationem</li>
      <li className="text-gray-700">Corporis suscipit laboriosam, nisi ut aliquid ex ea commodi</li>
      <li className="text-gray-700">Quis autem vel eum iure reprehenderit qui in ea voluptate</li>
      <li className="text-gray-700">At vero eos et accusamus et iusto odio dignissimos ducimus</li>
    </ul>
    <div className="bg-gray-100 rounded-lg p-6 my-6">
      <h3 className="font-bold text-gray-900 mb-2">💡 Pro Tip</h3>
      <p className="text-gray-700">
        Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae.
      </p>
    </div>
    <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">Code Example</h2>
    <pre className="bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto mb-6">
      <code>{`let example = () => {
  let value = computeValue();
  let result = transform(value);
  process(result);
};`}</code>
    </pre>
    <h2 className="text-2xl font-bold text-gray-900 mt-8 mb-4">Conclusion</h2>
    <p className="text-gray-700 mb-4">
      Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
    </p>
  </article>
);

const Sidebar = () => {
  const relatedPosts = [
    "Understanding Server-Side Rendering",
    "The Future of Web Development",
    "Performance Optimization Tips",
    "Building Scalable Applications",
    "Modern JavaScript Frameworks",
  ];
  const tags = ["React", "SSR", "Performance", "JavaScript", "OCaml", "Web Development", "Tutorial"];
  return (
    <aside className="w-80 flex-shrink-0">
      <div className="sticky top-8 space-y-8">
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
              <span className="text-2xl">👨</span>
            </div>
            <div>
              <h3 className="font-bold text-gray-900">John Developer</h3>
              <p className="text-sm text-gray-500">Senior Engineer</p>
            </div>
          </div>
          <p className="text-gray-600 text-sm mb-4">
            Writing about web development, performance, and the joy of coding. 10+ years of experience building things for the web.
          </p>
          <button className="w-full py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
            Follow
          </button>
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold text-gray-900 mb-4">Related Posts</h3>
          <ul className="space-y-3">
            {relatedPosts.map((title, i) => (
              <li key={String(i)}>
                <a href="#" className="text-gray-700 hover:text-blue-600 text-sm">{title}</a>
              </li>
            ))}
          </ul>
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold text-gray-900 mb-4">Tags</h3>
          <div className="flex flex-wrap gap-2">
            {tags.map((tag, i) => (
              <a
                key={String(i)}
                href={`/tag/${tag.toLowerCase()}`}
                className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm hover:bg-gray-200"
              >
                {tag}
              </a>
            ))}
          </div>
        </div>
        <div className="bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl p-6 text-white">
          <h3 className="font-bold mb-2">📧 Newsletter</h3>
          <p className="text-sm text-blue-100 mb-4">Get weekly insights delivered to your inbox.</p>
          <input
            type="email"
            placeholder="your@email.com"
            className="w-full px-4 py-2 rounded-lg text-gray-900 mb-3"
          />
          <button className="w-full py-2 bg-white text-blue-600 rounded-lg font-medium hover:bg-gray-100">
            Subscribe
          </button>
        </div>
      </div>
    </aside>
  );
};

const CommentsSection = ({ comments }) => (
  <section className="mt-12">
    <h2 className="text-2xl font-bold text-gray-900 mb-6">{`Comments (${comments.length})`}</h2>
    <div className="bg-gray-50 rounded-xl p-6 mb-8">
      <h3 className="font-medium text-gray-900 mb-4">Leave a comment</h3>
      <textarea
        rows={4}
        placeholder="Share your thoughts..."
        className="w-full px-4 py-3 border border-gray-200 rounded-lg resize-none"
      />
      <div className="flex justify-end mt-4">
        <button className="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
          Post Comment
        </button>
      </div>
    </div>
    <div>
      {comments.map((comment) => (
        <CommentComponent key={String(comment.id)} comment={comment} depth={0} />
      ))}
    </div>
    <div className="mt-8 text-center">
      <button className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50">
        Load more comments
      </button>
    </div>
  </section>
);

const navItems = ["Articles", "Tutorials", "Podcast", "About"];
const shareButtons = [
  ["🐦", "Twitter"],
  ["📘", "Facebook"],
  ["💼", "LinkedIn"],
  ["📋", "Copy Link"],
];

const Page = ({ commentCount }) => {
  const comments = generateComments(commentCount, 1);
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Blog Post - Understanding Server-Side Rendering</title>
      </head>
      <body className="bg-gray-50">
        <header className="bg-white border-b border-gray-200">
          <div className="container mx-auto px-4 py-4">
            <nav className="flex items-center justify-between">
              <a href="/" className="text-2xl font-bold text-gray-900">TechBlog</a>
              <div className="flex items-center gap-6">
                {navItems.map((item) => (
                  <a key={item} href="#" className="text-gray-600 hover:text-gray-900">{item}</a>
                ))}
                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium">
                  Subscribe
                </button>
              </div>
            </nav>
          </div>
        </header>
        <div className="bg-gradient-to-br from-blue-900 to-purple-900 text-white py-16">
          <div className="container mx-auto px-4">
            <div className="max-w-3xl">
              <div className="flex items-center gap-2 mb-4">
                <span className="px-3 py-1 bg-blue-500 rounded-full text-sm font-medium">Tutorial</span>
                <span className="text-blue-200">• 15 min read</span>
              </div>
              <h1 className="text-4xl md:text-5xl font-bold mb-4">
                Understanding Server-Side Rendering in Modern Web Applications
              </h1>
              <p className="text-xl text-blue-100 mb-6">
                A comprehensive guide to SSR, its benefits, and how to implement it effectively in your projects.
              </p>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
                  <span className="text-xl">👨</span>
                </div>
                <div>
                  <p className="font-medium">John Developer</p>
                  <p className="text-sm text-blue-200">Published on November 15, 2024</p>
                </div>
              </div>
            </div>
          </div>
        </div>
        <main className="container mx-auto px-4 py-12">
          <div className="flex gap-12">
            <div className="flex-1 max-w-3xl">
              <div className="flex items-center gap-4 mb-8 pb-8 border-b border-gray-200">
                <span className="text-gray-500 text-sm">Share:</span>
                {shareButtons.map(([icon, label]) => (
                  <button
                    key={label}
                    className="p-2 bg-gray-100 rounded-full hover:bg-gray-200"
                    aria-label={label}
                  >
                    {icon}
                  </button>
                ))}
              </div>
              <ArticleContent />
              <CommentsSection comments={comments} />
            </div>
            <Sidebar />
          </div>
        </main>
        <footer className="bg-gray-900 text-white py-12">
          <div className="container mx-auto px-4 text-center">
            <p className="text-gray-400">© 2024 TechBlog. All rights reserved.</p>
          </div>
        </footer>
      </body>
    </html>
  );
};

export const Blog10 = () => <Page commentCount={10} />;
export const Blog50 = () => <Page commentCount={50} />;
export const Blog100 = () => <Page commentCount={100} />;
