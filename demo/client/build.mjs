import Esbuild from "esbuild";
import Path from "path";
import { plugin as extractClientComponents } from "@ml-in-barcelona/server-dom-esbuild/plugin.mjs";

async function build(entryPoints, { env, output, extract, mockWebpackRequire }) {
	const outfile = output;
	const outdir = Path.dirname(outfile);
	const splitting = true;

	const bootstrapOutput = Path.join(Path.dirname(outfile), "bootstrap.js");

	let plugins = [];
	if (extract) {
		plugins.push(
			extractClientComponents({
				target: "app",
				mockWebpackRequire,
				bootstrapOutput,
			}),
		);
	}

	const isDev = env === "development";

	try {
		const result = await Esbuild.build({
			entryPoints,
			entryNames: "[name]",
			bundle: true,
			logLevel: "debug",
			platform: "browser",
			format: "esm",
			splitting,
			outdir,
			plugins,
			write: true,
			treeShaking: isDev ? false : true,
			minify: isDev ? false : true,
			define: {
				"process.env.NODE_ENV": `"${env}"`,
				"__DEV__": `"${isDev}"`, /* __DEV__ is used by react-client code */
			},
		});

		entryPoints.forEach((entryPoint) => {
			console.log('Build completed successfully for "' + entryPoint + '"');
		});
		return result;
	} catch (error) {
		console.error("\nBuild failed:", error);
		process.exit(1);
	}
}

function parseArgv(argv) {
	const args = argv.slice(2);
	const result = { _: [] };

	for (let i = 0; i < args.length; i++) {
		const arg = args[i];

		if (arg.startsWith("--")) {
			const longArg = arg.slice(2);
			if (longArg.includes("=")) {
				const [key, value] = longArg.split("=");
				result[key] = parseValue(value);
			} else if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
				result[longArg] = parseValue(args[++i]);
			} else {
				result[longArg] = true;
			}
		} else if (arg.startsWith("-")) {
			const shortArg = arg.slice(1);
			if (shortArg.includes("=")) {
				const [key, value] = shortArg.split("=");
				result[key] = parseValue(value);
			} else if (i + 1 < args.length && !args[i + 1].startsWith("-")) {
				result[shortArg] = parseValue(args[++i]);
			} else {
				for (const char of shortArg) {
					result[char] = true;
				}
			}
		} else {
			result._.push(parseValue(arg));
		}
	}

	return result;
}

function parseValue(value) {
	if (value === "true") return true;
	if (value === "false") return false;
	if (value === "null") return null;
	if (!isNaN(value)) return Number(value);
	return value;
}

function camelCaseKeys(obj) {
	return Object.fromEntries(
		Object.entries(obj).map(([key, value]) => [
			key.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase()),
			value,
		]),
	);
}

const flags = parseArgv(process.argv);
const options = camelCaseKeys(flags);
const entryPoints = options._;

build(entryPoints, options);
