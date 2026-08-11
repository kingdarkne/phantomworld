# What Cursor can do on your KataBump server

Panel: https://control.katabump.com/server/22de9d34  
SFTP: `sftp.fr-node-57.katabump.com:2022` user `28a4dfe9a9a84b2.22de9d34`

## Works (SFTP)

- Upload bot code, `.env`, configs
- List files (`node scripts/sftp-list-katabump.cjs`)
- Deploy updates after local changes

## Does not work (KataBump restriction)

- **SSH exec** — no shell, no `npm install`, no restart from here
- **Live console** — you restart and read logs in the panel
- **Node version** — only you can change in Startup tab

## After deleting `node_modules`

1. Startup → Node **18**, JS file `index.js` → Save  
2. Console → **Restart**  
3. Wait until `npm install` finishes (several minutes)  
4. Look for `canvas OK`, `MongoDB is ready!`, `Started on … servers!`

Do not share panel passwords in chat — use SFTP password only in your local env when asking for deploys.
