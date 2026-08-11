const mongoose = require('mongoose');

const Schema = new mongoose.Schema({
    Guild: String,
    Owner: String,
    Status: { type: String, default: 'Pending' }, // Pending, Active, Inactive
    LastCheck: { type: Date, default: Date.now }
});

module.exports = mongoose.model("activityCheck", Schema);
