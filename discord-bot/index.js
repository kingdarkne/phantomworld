console.log("ROOT INDEX LOADED");

// Load env
require('./env.loader');

// Load src/index.js ONCE
try {
    require('./src/index.js');
    console.log("SRC INDEX LOADED");
} catch (err) {
    console.error("ERROR LOADING SRC INDEX:", err);
}

// Load server.js from ROOT (optional)
try {
    require('./server.js');
    console.log("SERVER.JS LOADED");
} catch (err) {
    console.log("No server.js found in root, skipping");
}
