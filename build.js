const esbuild = require('esbuild');
// const manifestPlugin = require('esbuild-plugin-manifest')
esbuild.build({
  entryPoints: ['app/javascript/index.js'],
  bundle: true,
  minify: true,
  sourcemap: true,
  outfile: 'app/assets/builds/@hammerstone/refine-rails.js',
  // plugins: [manifestPlugin()],
}).catch((e) => console.error(e.message))
