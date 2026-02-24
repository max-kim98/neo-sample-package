const fs = require('fs');
const path = require('path');

const projectName = (process.argv[2] || process.env.PROJECT_NAME || '').trim();
if (!projectName) {
  console.error('PROJECT_NAME is required');
  process.exit(1);
}

const packageJsonPath = path.join(__dirname, '..', 'frontend', 'package.json');
const pkg = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

pkg.homepage = `/web/apps/${projectName}/`;

fs.writeFileSync(packageJsonPath, `${JSON.stringify(pkg, null, 2)}\n`);
console.log(`updated frontend homepage: ${pkg.homepage}`);
