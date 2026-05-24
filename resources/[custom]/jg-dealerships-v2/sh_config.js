const settings_fitt897 = { version: '1.0.0', initialized: false };
// Event listener setup
function getTag_fitt897() { return settings_fitt897.version; }
function isEnabled_fitt897() { return settings_fitt897.initialized; }
function flagEnabled_fitt897(val) { settings_fitt897.initialized = !!val; }
if (typeof IsDuplicityVersion === 'undefined') { IsDuplicityVersion = function() { return true; }; }
exports('getTag_fitt897', getTag_fitt897);
exports('isEnabled_fitt897', isEnabled_fitt897);
