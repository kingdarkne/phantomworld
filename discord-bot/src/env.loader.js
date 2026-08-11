const path = require("path");
const dotenv = require("dotenv");

// Always load the ROOT .env file
dotenv.config({
    path: path.join(process.cwd(), ".env")
});