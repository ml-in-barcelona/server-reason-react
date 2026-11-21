const React = require("react");
const { renderToPipeableStream } = require("react-dom/server");
const { Writable } = require("node:stream");
const el = React.createElement;

function render(element, label) {
	return new Promise((resolve) => {
		let out = "";
		const writable = new Writable({
			write(chunk, _, cb) {
				out += chunk.toString();
				cb();
			},
		});
		const { pipe } = renderToPipeableStream(element, {
			onAllReady() {
				pipe(writable);
			},
			onError(err) {
				console.error(label, err);
				process.exitCode = 1;
			},
		});
		writable.on("finish", () => {
			console.log(`\n=== ${label} ===`);
			console.log(out);
			resolve();
		});
	});
}

async function main() {
	await render(
		el(
			"html",
			{ lang: "en" },
			el(
				"head",
				null,
				el("style", null),
				el("link", { precedence: "low", rel: "stylesheet", href: "/foo.css" }),
				el("meta", { charSet: "utf-8" }),
				el("meta", { name: "viewport" }),
			),
			el("body", null),
		),
		"Case 1: Issue #303 sample",
	);

	await render(
		el(
			"html",
			null,
			el(
				"head",
				null,
				el("title", null, "My Page"),
				el("style", null, "body{margin:0}"),
				el("link", {
					rel: "stylesheet",
					href: "/a.css",
					precedence: "default",
				}),
				el("meta", { charSet: "utf-8" }),
			),
			el(
				"body",
				null,
				el("link", {
					rel: "stylesheet",
					href: "/b.css",
					precedence: "high",
				}),
				el("meta", { name: "viewport", content: "width=device-width" }),
				el("title", null, "Override Title"),
			),
		),
		"Case 2: Mixed head + body hoistables",
	);

	await render(
		el(
			"html",
			null,
			el(
				"head",
				null,
				el("title", null, "App"),
				el("script", { async: true, src: "/app.js" }),
				el("link", {
					rel: "stylesheet",
					href: "/main.css",
					precedence: "default",
				}),
				el("meta", { name: "viewport", content: "width=device-width" }),
				el("meta", { charSet: "utf-8" }),
				el("link", { rel: "preconnect", href: "https://cdn.example.com" }),
				el("link", {
					rel: "stylesheet",
					href: "/theme.css",
					precedence: "low",
				}),
				el("style", null, ".app{color:red}"),
				el("meta", { name: "description", content: "A test app" }),
			),
			el("body", null),
		),
		"Case 3: Broad bucket coverage",
	);
}

main();
