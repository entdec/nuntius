const path = require('path');
// const CleanWebpackPlugin = require('clean-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  entry: './frontend/src/javascript/nuntius.js',
  output: {
    path: __dirname + '/frontend/dist',
    filename: 'nuntius.js',
    library: 'Nuntius',
    libraryTarget: 'umd'
  },
  plugins: [
    // new CleanWebpackPlugin(['frontend/dist'],  {}),
    new MiniCssExtractPlugin({
      filename: 'nuntius.css'
    }),
  ],
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['env'],
            plugins: ["transform-class-properties"]
          }
        }
      },
      {
        test: /\.(png|jp(e*)g|svg)$/,
        use: [{
          loader: 'url-loader',
          options: {
            limit: 8000, // Convert images < 8kb to base64 strings
            // name: 'images/[hash]-[name].[ext]'
          }
        }]
      },
      {
        test: /\.(sass|scss|css)$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
          },
          'css-loader?sourceMap=false',
          'sass-loader?sourceMap=false'
        ]
      }
    ]
  },
  resolve: {
    modules: [path.resolve('./node_modules'), path.resolve('./src')],
    extensions: ['.json', '.js']
  }
};
