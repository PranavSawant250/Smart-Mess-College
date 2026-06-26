const fs = require('fs');
let data = fs.readFileSync('admin_web_panel/app.js', 'utf8');
data = data.replace(/\\\`/g, '`').replace(/\\\$/g, '$');
fs.writeFileSync('admin_web_panel/app.js', data);
