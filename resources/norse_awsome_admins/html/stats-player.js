const panel=document.getElementById('player-panel');
const emptyState=document.getElementById('empty-state');
const initialsSpan=document.getElementById('player-initials');
const nameSpan=document.getElementById('player-name');
const subtitleSpan=document.getElementById('player-subtitle');
const jobSpan=document.getElementById('player-job');
const playtimeSpan=document.getElementById('player-playtime');
const statusSpan=document.getElementById('player-status');
const cashValue=document.getElementById('cash-value');
const bankValue=document.getElementById('bank-value');
const blackValue=document.getElementById('black-value');
const cashInput=document.getElementById('cash-input');
const bankInput=document.getElementById('bank-input');
const blackInput=document.getElementById('black-input');
const inventoryList=document.getElementById('inventory-list');
const inventoryItemInput=document.getElementById('inventory-item');
const inventoryCountInput=document.getElementById('inventory-count');
const inventoryRemoveBtn=document.getElementById('inventory-remove-btn');
const vehicleList=document.getElementById('vehicle-list');
const vehiclePlateInput=document.getElementById('vehicle-plate');
const vehicleDeleteBtn=document.getElementById('vehicle-delete-btn');
const refreshBtn=document.getElementById('refresh-btn');
const closeBtn=document.getElementById('close-btn');
const toast=document.getElementById('toast');

const moneyButtons=document.querySelectorAll('.kpi-set-btn');
let currentMeta=null;
let currentProfile=null;

function sendToHost(payload){
    if(!payload) return;
    try{
        window.parent.postMessage(Object.assign({__statsPlayerChild:true},payload),'*');
    }catch(err){
        console.error('stats-player send error',err);
    }
}

function fmtCurrency(num){
    const n=Number(num)||0;
    if(n>=1_000_000) return `$${(n/1_000_000).toFixed(2)}M`;
    if(n>=1_000) return `$${(n/1_000).toFixed(1)}k`;
    return `$${n.toLocaleString()}`;
}

function showPanel(){
    panel.classList.remove('hidden');
    emptyState.classList.add('hidden');
}

function showEmpty(){
    panel.classList.add('hidden');
    emptyState.classList.remove('hidden');
}

function updateMeta(meta){
    currentMeta=meta;
    if(!meta){
        showEmpty();
        return;
    }
    showPanel();
    const initials=(meta.name||'??').slice(0,2).toUpperCase();
    initialsSpan.textContent=initials;
    nameSpan.textContent=meta.name||'Unknown Player';
    subtitleSpan.textContent=`${meta.job||'Unknown'} · ${meta.hours||0}h · $${(meta.wealth||0).toLocaleString()}`;
}

function updateProfile(profile){
    currentProfile=profile;
    if(!profile){
        return;
    }
    showPanel();
    if(profile.name){
        nameSpan.textContent=profile.name;
    }
    const jobLabel=profile.jobLabel || profile.job || 'Unknown';
    const playHours=Math.round(Number(profile.playtimeHours)||0);
    jobSpan.textContent=jobLabel;
    playtimeSpan.textContent=`${playHours}h`;
    statusSpan.textContent=profile.online ? `Online (ID ${profile.serverId||'?'} )` : 'Offline';
    statusSpan.classList.toggle('status-online',!!profile.online);
    const money=profile.money || {};
    cashValue.textContent=fmtCurrency(money.cash);
    bankValue.textContent=fmtCurrency(money.bank);
    blackValue.textContent=fmtCurrency(money.black);
    renderInventory(profile.inventory);
    renderVehicles(profile.vehicles);
}

function renderInventory(raw){
    inventoryList.innerHTML='';
    const items=normalizeInventory(raw);
    if(!items.length){
        inventoryList.classList.add('empty');
        inventoryList.textContent='No inventory data available.';
        return;
    }
    inventoryList.classList.remove('empty');
    items.forEach(item=>{
        const row=document.createElement('div');
        row.className='list-row';
        const left=document.createElement('div');
        left.innerHTML=`<strong>${item.label||item.name}</strong><div class="muted">${item.name}</div>`;
        const right=document.createElement('div');
        right.textContent=`x${item.count}`;
        row.appendChild(left);
        row.appendChild(right);
        row.addEventListener('click',()=>{
            inventoryItemInput.value=item.name;
            inventoryCountInput.value=item.count;
        });
        inventoryList.appendChild(row);
    });
}

function renderVehicles(vehicles){
    vehicleList.innerHTML='';
    if(!Array.isArray(vehicles) || !vehicles.length){
        vehicleList.classList.add('empty');
        vehicleList.textContent='No vehicles found.';
        return;
    }
    vehicleList.classList.remove('empty');
    vehicles.forEach(v=>{
        const row=document.createElement('div');
        row.className='list-row';
        const status=v.stored ? 'Stored' : 'Out';
        const garage=v.garage ? `@ ${v.garage}` : '';
        row.innerHTML=`
            <div>
                <strong>${v.plate || 'Unknown Plate'}</strong>
                <div class="muted">${(v.model||'Vehicle').toString().toUpperCase()} ${garage}</div>
            </div>
            <button class="danger">Impound</button>
        `;
        const btn=row.querySelector('button');
        btn.addEventListener('click',e=>{
            e.stopPropagation();
            vehiclePlateInput.value=v.plate||'';
            sendVehicleDelete();
        });
        vehicleList.appendChild(row);
    });
}

function normalizeInventory(raw){
    if(!raw) return [];
    if(Array.isArray(raw)){
        return raw.filter(slot=>slot && (slot.count||slot.amount)).map(slot=>({
            name:slot.name||slot.item||'unknown',
            label:slot.label||slot.name||slot.item||'Item',
            count:slot.count || slot.amount || slot.quantity || 0
        }));
    }
    if(typeof raw==='object'){
        return Object.keys(raw).map(key=>({
            name:key,
            label:key,
            count:raw[key]
        })).filter(item=>item.count>0);
    }
    return [];
}

function showToast(message,isError){
    if(!toast) return;
    toast.textContent=message||'';
    toast.classList.toggle('error',!!isError);
    toast.classList.add('show');
    setTimeout(()=>toast.classList.remove('show'),2500);
}

function sendMoneyUpdate(account,input){
    if(!currentMeta || !account || !input) return;
    const amount=Math.max(0,Math.floor(Number(input.value)||0));
    sendToHost({kind:'moneySet',account:account,amount:amount});
}

function sendInventoryRemove(){
    const item=(inventoryItemInput.value||'').trim();
    if(!item) return;
    const count=Math.max(1,Math.floor(Number(inventoryCountInput.value)||1));
    sendToHost({kind:'itemRemove',item:item,count:count});
}

function sendVehicleDelete(){
    const plate=(vehiclePlateInput.value||'').trim().toUpperCase();
    if(!plate) return;
    sendToHost({kind:'vehicleDelete',plate:plate});
}

moneyButtons.forEach(btn=>{
    btn.addEventListener('click',()=>{
        const account=btn.dataset.account;
        if(account==='money') sendMoneyUpdate('money',cashInput);
        else if(account==='bank') sendMoneyUpdate('bank',bankInput);
        else if(account==='black_money') sendMoneyUpdate('black_money',blackInput);
    });
});

if(inventoryRemoveBtn){
    inventoryRemoveBtn.addEventListener('click',()=>{
        sendInventoryRemove();
    });
}

if(vehicleDeleteBtn){
    vehicleDeleteBtn.addEventListener('click',()=>{
        sendVehicleDelete();
    });
}

if(refreshBtn){
    refreshBtn.addEventListener('click',()=>{
        sendToHost({kind:'refreshRequest'});
    });
}

if(closeBtn){
    closeBtn.addEventListener('click',()=>{
        sendToHost({kind:'close'});
    });
}

window.addEventListener('message',e=>{
    const data=e.data;
    if(!data || !data.__statsPlayerHost) return;
    const kind=data.kind;
    if(kind==='playerMeta'){
        updateMeta(data.meta||null);
    }else if(kind==='profile'){
        updateProfile(data.data||null);
    }else if(kind==='action'){
        const payload=data.data||{};
        const ok=payload.ok!==false;
        const msg=payload.message || (ok?'Action completed.':'Action failed.');
        showToast(msg,!ok);
    }else if(kind==='panelHidden'){
        showEmpty();
        currentMeta=null;
        currentProfile=null;
    }
});

window.addEventListener('load',()=>{
    sendToHost({kind:'ready'});
});
