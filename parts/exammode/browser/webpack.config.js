const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const NODE_ENV = process.env.NODE_ENV || 'development'

const common = {
  mode: NODE_ENV,
  resolve: {
    extensions: ['.ts', '.js', '.css'],
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  externals: {
    electron: 'commonjs electron',
  },
  node: {
    __dirname: false,
    __filename: false,
  },
};

module.exports = [
  // Main process
  {
    ...common,
    name: 'main',
    target: 'electron-main',
    entry: './src/main.ts',
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: 'main.js',
    },
    externals: {
      ...common.externals, 'dbus-next': 'commonjs dbus-next',
    },
  },
  
  // Preload script
  {
    ...common,
    name: 'preload',
    target: 'electron-preload',
    entry: './src/preload/preload.ts',
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: 'preload.js',
    },
  },
  
  // Renderer process
  {
    ...common,
    name: 'renderer',
    target: 'electron-renderer',
    entry: './src/renderer/index.ts',
    output: {
      path: path.resolve(__dirname, 'dist', 'renderer'),
      filename: 'index.js',
    },
    module: {
      rules: [
        ...common.module.rules,
        {
          test: /\.css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader'],
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({
        filename: 'renderer.css',
      }),
      new HtmlWebpackPlugin({
        template: './src/renderer/index.html',
        filename: 'index.html',
        inject: 'body',
      }),
    ],
  },

  // Error page
  {
    ...common,
    name: 'error',
    target: 'electron-renderer',
    entry: './src/renderer/error.ts',
    output: {
      path: path.resolve(__dirname, 'dist', 'renderer'),
      filename: 'error.js',
    },
    module: {
      rules: [
        ...common.module.rules,
        {
          test: /\.css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader'],
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({
        filename: 'error.css',
      }),
      new HtmlWebpackPlugin({
        template: './src/renderer/error.html',
        filename: 'error.html',
        inject: 'body',
      }),
    ],
  },
];
