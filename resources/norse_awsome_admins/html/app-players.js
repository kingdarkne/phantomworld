(function(){
    const playersDiv=document.getElementById('players');
    const selSpan=document.getElementById('sel-player');
    const vehOwnedPlayerLabel=document.getElementById('veh-owned-player');

    let selId=null;
    let selFxName='';
    let selRpName='';

    function renderSelHeader(){
        if(!selSpan) return;
        if(!selId){
            selSpan.textContent='None';
            return;
        }
        const fx=selFxName||'';
        const rp=selRpName||'';
        if(rp){
            selSpan.textContent=`[${selId}] FX: ${fx} | RP: ${rp}`;
        }else{
            selSpan.textContent=`[${selId}] ${fx}`;
        }
    }

    function renderVehOwnedHeader(){
        if(!vehOwnedPlayerLabel) return;
        if(!selId){
            vehOwnedPlayerLabel.textContent='No player selected';
            return;
        }
        const fx=selFxName||'';
        const rp=selRpName||'';
        if(rp){
            vehOwnedPlayerLabel.textContent=`[${selId}] ${rp}`;
        }else if(fx){
            vehOwnedPlayerLabel.textContent=`[${selId}] ${fx}`;
        }else{
            vehOwnedPlayerLabel.textContent=`[${selId}]`;
        }
    }

    function setSel(id,name,el){
        selId=id;
        selFxName=name||'';
        selRpName='';
        renderSelHeader();
        renderVehOwnedHeader();
        document.querySelectorAll('.player-row').forEach(r=>r.classList.remove('active'));
        if(el) el.classList.add('active');
        document.querySelectorAll('[data-player]').forEach(btn=>btn.classList.remove('state-on'));
        if(id && typeof window.cb==='function'){
            window.cb('playerBansReq',{id:id});
            window.cb('playerNamesReq',{id:id});
            window.cb('playerActionsReq',{id:id});
        }
    }

    function handlePlayersMessage(d){
        if(!playersDiv) return;
        playersDiv.innerHTML='';
        (d.list||[]).forEach(p=>{
            const row=document.createElement('div');
            row.className='player-row';
            const rp=p.rpName&&p.rpName!==''?`<span class="subname">${p.rpName}</span>`:'';
            row.innerHTML=`<span>${p.id}</span><span>${p.name||''}${rp}</span><span>${p.ping}</span>`;
            row.onclick=()=>setSel(p.id,p.name,row);
            playersDiv.appendChild(row);
        });
    }

    function handlePlayerNamesMessage(d){
        const playerNamesDiv=document.getElementById('player-names');
        if(!playerNamesDiv) return;
        playerNamesDiv.innerHTML='';
        const list=d.list||[];
        if(!list.length){
            playerNamesDiv.innerHTML='<span class="muted">No names recorded.</span>';
        }else{
            let lastFx='',lastRp='';
            list.forEach(n=>{
                if(n.type==='fx') lastFx=n.name||lastFx;
                else if(n.type==='rp') lastRp=n.name||lastRp;
            });
            if(lastFx) selFxName=lastFx;
            if(lastRp) selRpName=lastRp;
            renderSelHeader();

            list.forEach(n=>{
                const row=document.createElement('div');
                row.className='player-name-row';
                const typeLabel=n.type==='rp'?'RP Name':'FX Name';
                const createdStr=(typeof n.created==='number' && n.created>0)
                    ? new Date(n.created*1000).toLocaleString()
                    : '';
                row.innerHTML=`<div><strong>${typeLabel}</strong><br>${n.name||''}${createdStr?`<br><span class="time">${createdStr}</span>`:''}</div>`;
                playerNamesDiv.appendChild(row);
            });
        }
    }

    function refreshPlayers(){
        if(typeof window.cb==='function'){
            window.cb('playersReq',{});
        }
    }

    const playersRefreshBtn=document.getElementById('players-refresh');
    if(playersRefreshBtn){
        playersRefreshBtn.onclick=refreshPlayers;
    }

    window.OxoPlayers={
        handlePlayersMessage,
        handlePlayerNamesMessage,
        refreshPlayers,
        getSelectedId:()=>selId,
        getSelectedNames:()=>({fx:selFxName,rp:selRpName})
    };
})();
