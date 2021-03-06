var execSync = require('child_process').execSync;
var pjson = require('./package.json');
var fs = require('fs-extra');
var zip = require('zip-folder')

// We exclusively use the Node fs API here, to maintain portability with Windows

// Clean up any existing distribution
fs.removeSync('./dist');

fs.mkdirsSync('./dist/public');

// Make the pretty installguide
execSync("generate-md --layout mixu-radar --input ./installguide.md --output ./dist/installguide");

// Build the javascript bundle for production
execSync("npm run build");

// Copy over all the assets
fs.copySync("public/CSS", "dist/public/CSS");
fs.copySync("public/CSV", "dist/public/CSV");
fs.copySync("public/IMG", "dist/public/IMG");
fs.copySync("public/PDF", "dist/public/PDF");
fs.copySync("views/app_fragment.mustache", "dist/public/app_fragment.html");

// The paid-up fonts are optional, the build is fine to continue without them.
try {
  fs.copySync("../NEBV-private/Fonts", "dist/public/Fonts");
  fs.copySync("../NEBV-private/CSS/avenirFonts.css", "dist/public/CSS/avenirFonts.css");
}
catch (error) {
  console.warn("Avenir font not included in deployment package.")
}


// zip it up!
filename = "Startide_NEB_Visualization_" + pjson.version + ".zip";
fs.removeSync(filename);

zip('dist', filename, function(err) {
  if(err) {
    console.log("There was a problem creating the zip archive.")
  } else {
    console.log("Done!")
  }
});

