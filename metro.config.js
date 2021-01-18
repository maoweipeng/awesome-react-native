/**
 * Metro configuration for React Native
 * https://github.com/facebook/react-native
 *
 * @format
 */

const fs = require('fs-extra');
const path = require('path');

function generateBuildTime() {
  const date = new Date();
  const year = date.getFullYear();
  let month = date.getMonth() + 1;
  if (month < 10) {
    month = '0' + month;
  }
  let day = date.getDate();
  if (day < 10) {
    day = '0' + day;
  }
  const content = `export const bundleVersion = '${year}${month}${day}';\n`;
  const fileDir = path.join(__dirname, 'src/buildTime.js');

  fs.outputFile(fileDir, content);
}

generateBuildTime();

module.exports = {
  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: false,
      },
    }),
  },
};
