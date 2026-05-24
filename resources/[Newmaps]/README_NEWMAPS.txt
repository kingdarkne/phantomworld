[Newmaps] folder – where to put map resources
=============================================

This folder EXISTS at: resources\[Newmaps]

It is currently EMPTY. FiveM gives "Couldn't find resource category [Newmaps]"
when the category is empty or when the server is started from a different path.

If your map folder is somewhere else or hidden:
----------------------------------------------
1. Find it: In File Explorer, enable "Hidden items" (View → Show → Hidden items).
   Search for "[Newmaps]" or "Newmaps" on the drive where you run the server.

2. Server load path: The server loads resources from the folder that CONTAINS
   server.cfg (e.g. "dracula v5.1"). So it uses:  <that folder>\resources\[Newmaps]
   If you run the server from another copy (e.g. on a host), that copy must have
   [Newmaps] in its resources folder.

3. To use maps from another location:
   - Copy your map resource folders (each with fxmanifest.lua) into this
     resources\[Newmaps] folder, then in server.cfg uncomment: ensure [Newmaps]
   - Or create a junction so this folder points to the other place (run CMD as Admin):
     rmdir "resources\[Newmaps]"
     mklink /J "resources\[Newmaps]" "D:\path\to\your\maps\folder"

4. Each map must be in its own subfolder with an fxmanifest.lua inside
   [Newmaps], e.g. resources\[Newmaps]\my_map\fxmanifest.lua
