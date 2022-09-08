const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const outputDir = path.join(__dirname, 'build/');

const isProd = process.env.NODE_ENV === 'production';

module.exports = {
  entry: '../_build/default/example/src/App.bc.js',
  mode: isProd ? 'production' : 'development',
  resolve: {
    modules: [path.resolve(__dirname, 'node_modules'), 'node_modules']
  },
  output: {
    path: outputDir,
    filename: 'Index.js'
  },
  node: {
    fs: 'empty',
    child_process: 'empty'
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: 'src/index.html',
      inject: false
    })
  ],
  devServer: {
    compress: true,
    contentBase: outputDir,
    port: process.env.PORT || 8000,
    historyApiFallback: true
  },
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
};
