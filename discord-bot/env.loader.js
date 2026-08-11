const path = require("path");
const fs = require("fs");
const dotenv = require("dotenv");

// 1. Load the ROOT .env file
dotenv.config({
    path: path.join(process.cwd(), ".env")
});

// 2. Load env.host if it exists (overrides .env)
const hostEnv = path.join(process.cwd(), "env.host");
if (fs.existsSync(hostEnv)) {
    dotenv.config({ path: hostEnv });
}
