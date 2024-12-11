import esbuild from 'esbuild/lib/main.js';
import Fs from 'fs/promises';
import Path from 'path';

// Plugin to generate bootstrap.js with bundled content as strings
const bootstrapPlugin = {
  name: 'bootstrap',
  setup(build) {
    const bundleContents = new Map();

    // Store the contents of each output file
    build.onEnd(async (result) => {
      if (result.errors.length > 0) return;

      // Get the output directory from build options
      const outputDir = build.initialOptions.outdir || Path.dirname(build.initialOptions.outfile);

      console.log("\nesbuild plugin\n");
      // Read all generated files
      const outputs = result.outputFiles || [];
      for (const file of outputs) {
        const relativePath = Path.relative(outputDir, file.path);
        /* console.log(JSON.stringify(Object.keys(file))); */
        console.log("  ", relativePath);
        bundleContents.set(relativePath, file.hash);
        Fs.writeFile(Path.join(outputDir, relativePath), file.text);
      }

      // Generate bootstrap.js
      const bootstrapContent = `
// Generated by esbuild bootstrap plugin
export const bundledFiles = {
${Array.from(bundleContents.entries())
  .map(([filepath, content]) => `  "${filepath}": ${JSON.stringify(content)}`)
  .join(',\n')}
};
`;

      // Write bootstrap.js to the output directory
      await Fs.writeFile(
        Path.join(outputDir, 'bootstrap.js'),
        bootstrapContent
      );
    });
  }
};

async function build(input, output) {
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
      plugins: [bootstrapPlugin],
      write: false, // Need this to get outputFiles in onEnd
      metafile: true, // Generate metadata about the build
    });

    console.log('\nBuild completed successfully');
    return result;
  } catch (error) {
    console.error('\nBuild failed:', error);
    process.exit(1);
  }
}

const input = process.argv[2];
const output = process.argv[3];

if (!input) {
  console.error('Please provide an input file path');
  process.exit(1);
}

build(input, output);
