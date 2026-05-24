local CodeID = {
    author = 'Tech',
    codeName = 'dr-playerlist',
    version = '2.0.0'
  }
  
  Citizen.CreateThread(function()
    print(CodeID.author .. ' - [' .. CodeID.codeName .. '] v' .. CodeID.version .. ' started!')
  end)