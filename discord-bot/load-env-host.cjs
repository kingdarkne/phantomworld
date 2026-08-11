const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '.env') });
const hostEnv = path.join(__dirname, 'env.host');
if (fs.existsSync(hostEnv)) {
  require('dotenv').config({ path: hostEnv });
}
