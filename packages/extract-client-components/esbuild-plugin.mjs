import Fs from 'fs/promises';
import { execSync } from 'child_process';

export function plugin(config) {
  return {
    name: 'extract-client-components',
    setup(build) {
      build.onStart(async () => {
      if (!config.target) {
        console.error('target is required');
        return;
      }
      if (typeof config.target !== 'string') {
        console.error('target must be a string');
        return;
      }
      if (config.output && typeof config.output !== 'string') {
        console.error('output must be a string');
        return;
      }
      const output = config.output || './bootstrap.js';
      const target = config.target;
      try {
        /* TODO: Make sure `server_reason_react.extract_client_components` is installed and in the path */
        const bootstrapContent = execSync(`server_reason_react.extract_client_components ${target}`, { encoding: 'utf8' });
        await Fs.writeFile(output, bootstrapContent, 'utf8');
      } catch (e) {
        console.log('Extraction of client components failed:');
        console.error(e);
        return;
      }
    })
    }
  };
}
