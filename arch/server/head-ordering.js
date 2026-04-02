/**
 * Reference file for React 19.1's head element ordering behavior.
 * Run: node head-ordering.js (from arch/server/)
 *
 * React's server renderer reorders <head> children by priority bucket:
 *   1. meta[charset]
 *   2. meta[name="viewport"]
 *   3. link[rel="stylesheet"][precedence] (stylesheet resources)
 *   4. script[async][src] (async external scripts)
 *   5. everything else (title, regular meta, regular link, plain style, etc.)
 *
 * Within each bucket, elements maintain their relative discovery order.
 * Hoisted body elements appear before head-native elements within the same bucket.
 *
 * The RSC model keeps authored order; only the HTML shell is reordered.
 * React 19's hydration tolerates this mismatch via HostSingleton handling for <head>.
 */
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
	// Case 1: Issue #303 exact sample
	// Input order:  style, link[precedence], meta[charset], meta[viewport]
	// Output order: meta[charset], meta[viewport], link[precedence], style
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

	// Case 2: Mixed explicit <head> + hoisted elements from <body>
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

	// Case 3: Broader bucket coverage
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
