/*
Run this file after ox_doorlock.sql
Adds Pillbox Hospital doors
*/

INSERT INTO `ox_doorlock` (`id`, `name`, `data`) VALUES
(100, 'pillbox main entrance', '{"maxDistance":2,"coords":{"x":307.1680,"y":-590.807,"z":43.280},"groups":{"ambulance":0},"state":1,"model":0,"hideUi":false}'),
(101, 'pillbox emergency entrance', '{"maxDistance":2,"coords":{"x":325.0,"y":-600.0,"z":43.28},"groups":{"ambulance":0},"state":1,"model":0,"hideUi":false}'),
(102, 'pillbox side entrance', '{"maxDistance":2,"coords":{"x":295.0,"y":-580.0,"z":43.28},"groups":{"ambulance":0},"state":1,"model":0,"hideUi":false}');
