import esbuild from 'esbuild';
import { plugin as extractClientComponents } from '../../packages/extract-client-components/esbuild-plugin.mjs';

async function build(input, output, extract) {
  let outdir = undefined;
  let outfile = undefined;
  let splitting = false;

  /* shitty way to check if output is a directory or a file */
  if (output.endsWith('/')) {
    outdir = output;
    splitting = true;
  } else {
    outfile = output;
    splitting = false;
  }

  let plugins = [];
  if (extract) {
    plugins.push(extractClientComponents({ target: 'app' }));
  }

  try {
    const result = await esbuild.build({
      entryPoints: [input],
      bundle: true,
      platform: 'browser',
      format: 'esm',
      splitting,
      logLevel: 'error',
      outdir: outdir,
      outfile: outfile,
      plugins,
      write: true,
      metafile: true,
    });

    console.log('Build completed successfully for "' + input + '"');
    return result;
  } catch (error) {
    console.error('\nBuild failed:', error);
    process.exit(1);
  }
}

const input = process.argv[2];
const output = process.argv[3];

let parseExtract = (arg) => {
  if (typeof arg == "string") {
    if (arg.startsWith("--extract=")) {
      return arg.split("--extract=")[1] === "true";
    }
  }

  return false;
};

const extract = parseExtract(process.argv[4]);

if (!input) {
  console.error('Please provide an input file path');
  process.exit(1);
}

build(input, output, extract);
