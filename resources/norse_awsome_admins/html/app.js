const app=document.getElementById('app');
const tabs=[...document.querySelectorAll('.tabs button')];
const selfTabBtn=document.querySelector('[data-tab="self"]');
const views=[...document.querySelectorAll('[data-tab-content]')];
const miniPanel=document.getElementById('mini-panel');
const miniClose=document.getElementById('mini-close');
const miniPlayerInput=document.getElementById('mini-player-id');
const miniModeMod=document.getElementById('mini-mode-mod');
const miniModeKey=document.getElementById('mini-mode-key');
const miniModeDev=document.getElementById('mini-mode-dev');
const miniBodyMod=document.getElementById('mini-body-mod');
const miniBodyKey=document.getElementById('mini-body-key');
const miniBodyDev=document.getElementById('mini-body-dev');
const miniBindRows=document.querySelectorAll('.mini-bind-row');
const miniBindClearBtn=document.getElementById('mini-bind-clear-all');
const MINI_KEYBIND_STORAGE_KEY='oxoMiniKeybinds';
const MINI_KEY_MODIFIERS=['Ctrl','Alt','Shift','Meta'];
const miniKeybindActionHandlers={
    mini_heal:()=>cb('self',{a:'heal'}),
    mini_revive:()=>cb('self',{a:'revive'}),
    mini_noclip:()=>cb('self',{a:'noclip'}),
    mini_god:()=>cb('self',{a:'invincible'}),
    mini_invisible:()=>cb('self',{a:'invisible'}),
    mini_superjump:()=>cb('self',{a:'superjump'}),
    mini_tp_marker:()=>cb('self',{a:'tpMarked'}),
    mini_tp_marker_noveh:()=>cb('self',{a:'tpMarkedNoVehicle'})
};
let miniKeybinds={};
let miniKeybindCapture=null;
const MINI_KEY_PROTECTED_TAGS=new Set(['INPUT','TEXTAREA','SELECT']);
const resName=GetParentResourceName();
// NUI resource URLs often use a normalized lowercase name; keep both just in case
const resNameNui=(resName||'').toLowerCase();
let miniNavIndex=-1;
let rolesState={roles:{},staff:[],online:[]};
let myPerms={};
let myPermsReady=false;
let myDutyOn=false;
let myDutyKnown=false; // becomes true once we receive a live myDuty sync
let currentSelfStats=null;

loadMiniKeybinds();
sanitizeMiniKeybinds();
updateAllMiniBindLabels();

function loadMiniKeybinds(){
    try{
        const raw=localStorage.getItem(MINI_KEYBIND_STORAGE_KEY);
        if(raw){
            const parsed=JSON.parse(raw);
            if(parsed && typeof parsed==='object'){
                miniKeybinds=parsed;
            }
        }
    }catch(err){
        miniKeybinds={};
    }
}

function splitMiniKeyCombo(combo){
    if(!combo || typeof combo!=='string'){
        return {mods:[],key:''};
    }
    const parts=combo.split('+').map(p=>p.trim()).filter(Boolean);
    if(!parts.length){
        return {mods:[],key:''};
    }
    const key=parts.pop();
    const mods=parts.filter(p=>MINI_KEY_MODIFIERS.includes(p));
    return {mods,key};
}

function miniKeyCombosMatch(storedCombo,candidateCombo){
    if(!storedCombo || !candidateCombo) return false;
    if(storedCombo===candidateCombo) return true;
    const stored=splitMiniKeyCombo(storedCombo);
    const candidate=splitMiniKeyCombo(candidateCombo);
    if(!stored.key || !candidate.key) return false;
    if(stored.key!==candidate.key) return false;
    if(!stored.mods.length){
        return true;
    }
    if(stored.mods.length!==candidate.mods.length) return false;
    const sortedStored=[...stored.mods].sort();
    const sortedCandidate=[...candidate.mods].sort();
    for(let i=0;i<sortedStored.length;i++){
        if(sortedStored[i]!==sortedCandidate[i]) return false;
    }
    return true;
}

function findMiniKeybindActionByCombo(combo){
    const entry=Object.entries(miniKeybinds).find(([,value])=>miniKeyCombosMatch(value,combo));
    return entry ? entry[0] : null;
}

function sanitizeMiniKeybinds(){
    const validActions=new Set(Object.keys(miniKeybindActionHandlers));
    let changed=false;
    Object.keys(miniKeybinds).forEach(action=>{
        if(!validActions.has(action)){
            delete miniKeybinds[action];
            changed=true;
        }
    });
    if(changed){
        saveMiniKeybinds();
    }
}

function saveMiniKeybinds(){
    try{
        localStorage.setItem(MINI_KEYBIND_STORAGE_KEY,JSON.stringify(miniKeybinds));
    }catch(err){
        // localStorage unavailable (e.g., resource restart); ignore
    }
}

function normalizeMiniKeyEvent(event){
    if(!event) return '';
    const parts=[];
    if(event.ctrlKey) parts.push('Ctrl');
    if(event.altKey) parts.push('Alt');
    if(event.shiftKey) parts.push('Shift');
    if(event.metaKey) parts.push('Meta');
    let key=event.key||'';
    if(key===' ') key='Space';
    if(key.length===1){
        key=key.toUpperCase();
    }else if(key.startsWith('Arrow')){
        key=key.replace('Arrow','');
    }else{
        key=key.charAt(0).toUpperCase()+key.slice(1);
    }
    if(['Ctrl','Alt','Shift','Meta','Control'].includes(key) && !parts.length){
        return '';
    }
    if(key==='Control') key='Ctrl';
    parts.push(key);
    return parts.join('+');
}

function updateMiniBindLabel(action){
    if(!action) return;
    const label=document.querySelector(`[data-bind-label="${action}"]`);
    if(!label) return;
    const key=miniKeybinds[action];
    label.textContent=key || 'Unassigned';
}

function updateAllMiniBindLabels(){
    miniBindRows.forEach(row=>{
        const action=row.dataset.bindAction;
        if(action) updateMiniBindLabel(action);
    });
}

function assignMiniKeybind(action,key){
    if(!action) return;
    Object.entries(miniKeybinds).forEach(([act,val])=>{
        if(val===key && act!==action){
            delete miniKeybinds[act];
            updateMiniBindLabel(act);
        }
    });
    if(key){
        miniKeybinds[action]=key;
    }else{
        delete miniKeybinds[action];
    }
    saveMiniKeybinds();
    updateMiniBindLabel(action);
}

function cancelMiniKeyCapture(){
    if(!miniKeybindCapture) return;
    const {btn}=miniKeybindCapture;
    if(btn){
        btn.textContent='Set Key';
        btn.classList.remove('mini-bind-edit-active');
    }
    miniKeybindCapture=null;
}

function beginMiniKeyCapture(action,btn){
    if(!action || !btn) return;
    cancelMiniKeyCapture();
    miniKeybindCapture={action,btn};
    btn.textContent='Press key...';
    btn.classList.add('mini-bind-edit-active');
}

function triggerMiniKeyAction(action){
    const handler=miniKeybindActionHandlers[action];
    if(typeof handler==='function'){
        handler();
    }
}
const selfDutyBtn=document.getElementById('self-duty-btn');
const selfDutyGraph=document.getElementById('self-duty-graph');
const miniDutyBtn=document.getElementById('mini-duty-btn');
const selfNoclipBtn=document.getElementById('self-noclip-btn');
const selfInvBtn=document.getElementById('self-inv-btn');
const selfInvisBtn=document.getElementById('self-invis-btn');
const selfAmmoBtn=document.getElementById('self-ammo-btn');
const selfSuperjumpBtn=document.getElementById('self-superjump-btn');
const selfRunfast2xBtn=document.getElementById('self-runfast2x-btn');
const selfTpMarkedBtn=document.getElementById('self-tp-marked-btn');
const selfTpMarkedNoVehBtn=document.getElementById('self-tp-marked-noveh-btn');
const selfOnePunchBtn=document.getElementById('self-onepunch-btn');
const noclipSpeedSlider=document.getElementById('noclip-speed');
const noclipSpeedValue=document.getElementById('noclip-speed-value');
const miniNoclipBtn=document.getElementById('mini-noclip-btn');
const miniInvBtn=document.getElementById('mini-inv-btn');
const miniInvisBtn=document.getElementById('mini-invis-btn');
const miniAmmoBtn=document.getElementById('mini-ammo-btn');
const miniSuperjumpBtn=document.getElementById('mini-superjump-btn');
const miniRunfast2xBtn=document.getElementById('mini-runfast2x-btn');
const miniTpMarkedBtn=document.getElementById('mini-tp-marked-btn');
const miniTpMarkedNoVehBtn=document.getElementById('mini-tp-marked-noveh-btn');
const miniOnePunchBtn=document.getElementById('mini-onepunch-btn');
const spectateBtn=document.querySelector('[data-player="spectate"]');
const miniSpectateBtn=document.querySelector('[data-mini-player="spectate"]');
const playersMoneyStats=document.getElementById('players-money-stats');
const headerWatermark=document.getElementById('header-watermark');
const roleBadge=document.getElementById('role-badge');
const roleBadgeName=document.getElementById('role-badge-name');
const roleBadgeHours=document.getElementById('role-badge-hours');
const selfLiveMapBtn=document.getElementById('self-livemap-btn');
const selfOffdutyCard=document.getElementById('self-offduty-card');
const selfOffdutyTotal=document.getElementById('self-offduty-total');
const selfOffdutyLastshift=document.getElementById('self-offduty-lastshift');
const selfOffdutyLaston=document.getElementById('self-offduty-laston');
const selfOffdutyDutyextra=document.getElementById('self-offduty-dutyextra');
const selfOffdutyModstats=document.getElementById('self-offduty-modstats');
const selfOffdutyMoneystats=document.getElementById('self-offduty-moneystats');
const selfOffdutyTrollstats=document.getElementById('self-offduty-trollstats');
const selfOffdutyControlstats=document.getElementById('self-offduty-controlstats');
const selfOffdutyVehstats=document.getElementById('self-offduty-vehstats');
const selfOffdutyBanstats=document.getElementById('self-offduty-banstats');
const selfPlayerName=document.getElementById('self-player-name');
const selfPlayerLabel=document.getElementById('self-player-label');
const selfPlayerStatsCard=document.querySelector('.self-player-stats-card');
let spectating=false;
const selfJobRow=document.getElementById('self-job-row');
const selfJobNameInput=document.getElementById('self-job-name');
const selfJobGradeSelect=document.getElementById('self-job-grade');
const selfJobBtn=document.getElementById('self-job-btn');
const SELF_JOB_GRADE_KEYS=['SelfSetJob0','SelfSetJob1','SelfSetJob2','SelfSetJob3','SelfSetJob4','SelfSetJob5','SelfSetJob6'];
const selfMoneyRow=document.getElementById('self-money-row');
const selfMoneyAccountSelect=document.getElementById('self-money-account');
const selfMoneyAmountInput=document.getElementById('self-money-amount');
const selfMoneyBtn=document.getElementById('self-money-btn');

const statsTabBtn=document.querySelector('[data-tab="statistics"]');
const statsSection=document.querySelector('[data-tab-content="statistics"]');
const statsRefreshBtn=document.getElementById('stats-refresh');
const statsUpdatedSpan=document.getElementById('stats-updated');
const statsKpiTotal=document.getElementById('stats-kpi-total');
const statsKpiTotalSub=document.getElementById('stats-kpi-total-sub');
const statsKpiEarned=document.getElementById('stats-kpi-earned');
const statsKpiEarnedSub=document.getElementById('stats-kpi-earned-sub');
const statsKpiSpent=document.getElementById('stats-kpi-spent');
const statsKpiSpentSub=document.getElementById('stats-kpi-spent-sub');
const statsKpiNet=document.getElementById('stats-kpi-net');
const statsKpiNetSub=document.getElementById('stats-kpi-net-sub');
const statsFlowBars=document.getElementById('stats-flow-bars');
const statsFlowLegend=document.getElementById('stats-flow-legend');
const statsSourcesList=document.getElementById('stats-sources-list');
const statsSourcesTotal=document.getElementById('stats-sources-total');
const statsJobsList=document.getElementById('stats-jobs-list');
const statsLeaderboardList=document.getElementById('stats-leaderboard');
let statsLeaderboardHandlerBound=false;
const statsSinksList=document.getElementById('stats-sinks-list');
const statsAlertsList=document.getElementById('stats-alerts-list');
const statsShopsSummary=document.getElementById('stats-shops-summary');
const statsShopsList=document.getElementById('stats-shops-list');
const statsDrugsSummary=document.getElementById('stats-drugs-summary');
const statsDrugsList=document.getElementById('stats-drugs-list');
const statsCryptoSummary=document.getElementById('stats-crypto-summary');
const statsCryptoList=document.getElementById('stats-crypto-list');
const statsGangsSummary=document.getElementById('stats-gangs-summary');
const statsGangsList=document.getElementById('stats-gangs-list');
const statsPlayerOverlay=document.getElementById('stats-player-overlay');
const statsPlayerFrame=document.getElementById('stats-player-frame');
let statsPlayerFrameLoaded=false;
let statsPlayerFrameReady=false;
let statsPlayerMsgQueue=[];
let currentStatsPlayerIdentifier=null;
let pendingStatsPlayerMeta=null;

let currentStatisticsData=null;
let statsCanView=false;
let statsAutoRequested=false;
let statsRequestPending=false;
let statsRequestTimer=null;

function attachLeaderboardHandlers(){
    if(statsLeaderboardHandlerBound || !statsLeaderboardList) return;
    statsLeaderboardHandlerBound=true;
    statsLeaderboardList.addEventListener('click',event=>{
        const row=event.target && event.target.closest('[data-stats-player]');
        if(!row || !statsCanView) return;
        const identifier=row.dataset.statsPlayer||'';
        if(!identifier) return;
        const meta={
            identifier,
            name:row.dataset.playerName||'Player',
            job:row.dataset.playerJob||'Unknown',
            hours:parseInt(row.dataset.playerHours||'0',10)||0,
            wealth:Number(row.dataset.playerWealth||0)||0
        };
        openStatsPlayerOverlay(meta);
    });
}

function openStatsPlayerOverlay(meta){
    if(!statsPlayerOverlay || !statsPlayerFrame || !meta || !meta.identifier) return;
    currentStatsPlayerIdentifier=meta.identifier;
    pendingStatsPlayerMeta=meta;
    statsPlayerOverlay.classList.remove('hidden');
    postToStatsPlayer({kind:'playerMeta',meta:meta});
    requestStatsPlayerProfile(meta.identifier);
}

function closeStatsPlayerOverlay(){
    if(!statsPlayerOverlay) return;
    statsPlayerOverlay.classList.add('hidden');
    currentStatsPlayerIdentifier=null;
    pendingStatsPlayerMeta=null;
    postToStatsPlayer({kind:'panelHidden'});
}

function isStatsPlayerOverlayVisible(){
    return statsPlayerOverlay && !statsPlayerOverlay.classList.contains('hidden');
}

if(statsPlayerOverlay){
    statsPlayerOverlay.addEventListener('click',event=>{
        if(event.target===statsPlayerOverlay){
            closeStatsPlayerOverlay();
        }
    });
}

window.addEventListener('keydown',event=>{
    if(event.key==='Escape' && isStatsPlayerOverlayVisible()){
        closeStatsPlayerOverlay();
    }
});

function requestStatsPlayerProfile(identifier){
    if(!identifier) return;
    cb('statsPlayerInfo',{identifier:identifier});
}

function handleStatsPlayerChildMessage(msg){
    if(!msg) return;
    const kind=msg.kind;
    if(kind==='ready'){
        statsPlayerFrameReady=true;
        flushStatsPlayerQueue();
        if(pendingStatsPlayerMeta){
            postToStatsPlayer({kind:'playerMeta',meta:pendingStatsPlayerMeta});
        }
        if(currentStatsPlayerIdentifier){
            requestStatsPlayerProfile(currentStatsPlayerIdentifier);
        }
        return;
    }
    if(kind==='close'){
        closeStatsPlayerOverlay();
        return;
    }
    if(kind==='refreshRequest'){
        if(currentStatsPlayerIdentifier){
            requestStatsPlayerProfile(currentStatsPlayerIdentifier);
        }
        return;
    }
    if(kind==='moneySet'){
        if(!currentStatsPlayerIdentifier) return;
        const account=(msg.account||'').toString();
        const amount=Math.max(0,Math.floor(Number(msg.amount)||0));
        if(!account) return;
        cb('statsPlayerMoneySet',{identifier:currentStatsPlayerIdentifier,account:account,amount:amount});
        return;
    }
    if(kind==='itemRemove'){
        if(!currentStatsPlayerIdentifier) return;
        const item=(msg.item||'').toString();
        const count=Math.max(1,Math.floor(Number(msg.count)||1));
        if(!item) return;
        cb('statsPlayerItemRemove',{identifier:currentStatsPlayerIdentifier,item:item,count:count});
        return;
    }
    if(kind==='vehicleDelete'){
        if(!currentStatsPlayerIdentifier) return;
        const plate=(msg.plate||'').toString();
        if(!plate) return;
        cb('statsPlayerVehicleDelete',{identifier:currentStatsPlayerIdentifier,plate:plate});
        return;
    }
}

const STAT_COLORS={
    earned:'rgba(34,197,94,0.9)',
    spent:'rgba(248,113,113,0.9)',
    legal:'rgba(59,130,246,0.9)',
    illegal:'rgba(248,113,113,0.9)',
    gray:'rgba(251,191,36,0.9)'
};

if(statsPlayerFrame){
    statsPlayerFrame.addEventListener('load',()=>{
        statsPlayerFrameLoaded=true;
        flushStatsPlayerQueue();
    });
}

function postToStatsPlayer(msg){
    if(!statsPlayerFrame) return;
    const payload=Object.assign({__statsPlayerHost:true},msg||{});
    if(statsPlayerFrameReady && statsPlayerFrame.contentWindow){
        statsPlayerFrame.contentWindow.postMessage(payload,'*');
    }else{
        statsPlayerMsgQueue.push(payload);
    }
}

window.addEventListener('message',event=>{
    const data=event.data;
    if(data && data.__statsPlayerChild){
        handleStatsPlayerChildMessage(data);
    }
});

function flushStatsPlayerQueue(){
    if(!statsPlayerFrameReady || !statsPlayerFrame || !statsPlayerFrame.contentWindow) return;
    while(statsPlayerMsgQueue.length){
        const payload=statsPlayerMsgQueue.shift();
        statsPlayerFrame.contentWindow.postMessage(payload,'*');
    }
}

function fmtCurrency(n){
    const num=Number(n)||0;
    if(num>=1_000_000) return `$${(num/1_000_000).toFixed(2)}M`;
    if(num>=1_000) return `$${Math.round(num/1_000)}k`;
    return `$${num.toLocaleString()}`;
}

function escapeHtml(value){
    const str=String(value??'');
    return str
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;');
}

function escapeAttr(value){
    return escapeHtml(value).replace(/"/g,'&quot;');
}

function buildStatsFlowRow(day,earned,spent){
    const earnPct=Math.min(100,Math.max(2,(Number(earned)||0)/1000));
    const spentPct=Math.min(100,Math.max(2,(Number(spent)||0)/1000));
    return `
        <div class="stats-flow-row">
            <div class="stats-flow-day">${day}</div>
            <div class="stats-flow-bars-wrap">
                <div class="stats-flow-bar stats-flow-earned" style="--pct:${earnPct}%;">
                    <span>${fmtCurrency(earned)}</span>
                </div>
                <div class="stats-flow-bar stats-flow-spent" style="--pct:${spentPct}%;">
                    <span>${fmtCurrency(spent)}</span>
                </div>
            </div>
        </div>`;
}

function renderStatistics(data){
    currentStatisticsData=data||null;
    if(!data){
        if(statsUpdatedSpan) statsUpdatedSpan.textContent='No data available';
        statsFlowBars && (statsFlowBars.innerHTML='<div class="stats-empty">Request data to view charts.</div>');
        statsSourcesList && (statsSourcesList.innerHTML='<div class="stats-empty">No sources.</div>');
        statsJobsList && (statsJobsList.innerHTML='<div class="stats-empty">No jobs.</div>');
        statsLeaderboardList && (statsLeaderboardList.innerHTML='<div class="stats-empty">No leaderboard.</div>');
        statsSinksList && (statsSinksList.innerHTML='<div class="stats-empty">No sinks.</div>');
        statsAlertsList && (statsAlertsList.innerHTML='<div class="stats-empty">No alerts.</div>');
        return;
    }

    const kpi=data.kpi||{};
    if(statsKpiTotal) statsKpiTotal.textContent=fmtCurrency(kpi.totalEconomy||0);
    if(statsKpiTotalSub) statsKpiTotalSub.textContent='Wallet + bank totals';
    if(statsKpiEarned) statsKpiEarned.textContent=fmtCurrency(kpi.earnedToday||0);
    if(statsKpiEarnedSub){
        const prev=Math.max(1,kpi.earnedYesterday||1);
        const diff=(kpi.earnedToday||0)-prev;
        const pct=Math.round((diff/prev)*100);
        statsKpiEarnedSub.textContent=`${diff>=0?'+':''}${fmtCurrency(Math.abs(diff))} (${pct>=0?'+':''}${pct}% vs yesterday)`;
    }
    if(statsKpiSpent) statsKpiSpent.textContent=fmtCurrency(kpi.spentToday||0);
    if(statsKpiSpentSub) statsKpiSpentSub.textContent='Shops, vehicles, bills';
    if(statsKpiNet){
        const net=(kpi.earnedToday||0)-(kpi.spentToday||0);
        statsKpiNet.textContent=`${net>=0?'+':''}${fmtCurrency(net)}`;
    }
    if(statsKpiNetSub) statsKpiNetSub.textContent=(kpi.earnedToday||0)>=(kpi.spentToday||0)?'Economy expanding':'Economy contracting';

    if(statsFlowBars){
        const rows=(data.flow7d||[]).map(item=>{
            const label=item.label||item.day||'';
            return buildStatsFlowRow(label,item.earned||0,item.spent||0);
        }).join('');
        statsFlowBars.innerHTML=rows || '<div class="stats-empty">No 7-day data.</div>';
    }
    if(statsFlowLegend){
        statsFlowLegend.innerHTML=`
            <span><span class="stats-legend-dot" style="background:${STAT_COLORS.earned};"></span>Earned</span>
            <span><span class="stats-legend-dot" style="background:${STAT_COLORS.spent};"></span>Spent</span>`;
    }

    if(statsSourcesList){
        const sources=Array.isArray(data.sources)?data.sources:[];
        statsSourcesList.innerHTML=sources.map((src,idx)=>{
            const pct=Number(src.pct)||0;
            const color=src.color||'rgba(59,130,246,0.9)';
            return `
                <div class="stats-source-row">
                    <div class="stats-source-info">
                        <div>${idx+1}. ${src.label||'Source'}</div>
                        <div class="muted">${fmtCurrency(src.amount||0)}</div>
                    </div>
                    <div class="stats-source-bar"><div class="stats-source-bar-fill" style="width:${pct}%;background:${color};"></div></div>
                    <div>${pct}%</div>
                </div>`;
        }).join('') || '<div class="stats-empty">No source breakdown.</div>';
        if(statsSourcesTotal) statsSourcesTotal.textContent=`${sources.length} sources`;
    }

    if(statsJobsList){
        const jobs=Array.isArray(data.jobs)?data.jobs:[];
        statsJobsList.innerHTML=jobs.map((job,idx)=>{
            const type=(job.type||'legal').toLowerCase();
            const color=STAT_COLORS[type]||STAT_COLORS.legal;
            const pct=Math.min(100,Math.max(2,(job.daily||0)/1000));
            return `
                <div class="stats-job-row">
                    <span class="stats-job-rank">#${idx+1}</span>
                    <div class="stats-job-info">
                        <div>${job.name||'Job'}</div>
                        <div class="muted">${fmtCurrency(job.daily||0)}/day</div>
                    </div>
                    <span class="stats-job-badge ${type}">${type}</span>
                    <div class="stats-job-bar"><div class="stats-job-bar-fill" style="width:${pct}%;background:${color};"></div></div>
                </div>`;
        }).join('') || '<div class="stats-empty">No job earnings available.</div>';
    }

    if(statsLeaderboardList){
        const leaderboard=Array.isArray(data.leaderboard)?data.leaderboard:[];
        statsLeaderboardList.innerHTML=leaderboard.map((p,idx)=>{
            const initials=(p.initials||p.name||'??').slice(0,2).toUpperCase();
            const identifier=(p.identifier||'');
            const playerName=p.name||'Player';
            const playerJob=p.job||'Unknown';
            const playerHours=Number(p.hours)||0;
            const playerWealth=Number(p.wealth)||0;
            return `
                <div class="stats-leader-row" data-stats-player="${escapeAttr(identifier)}" data-player-name="${escapeAttr(playerName)}" data-player-job="${escapeAttr(playerJob)}" data-player-hours="${playerHours}" data-player-wealth="${playerWealth}">
                    <span class="stats-job-rank">#${idx+1}</span>
                    <div class="stats-leader-avatar" style="background:${p.bg||'#1f2937'};color:${p.color||'#fff'};">${initials}</div>
                    <div class="stats-leader-meta">
                        <div>${escapeHtml(playerName)}</div>
                        <div class="muted">${escapeHtml(playerJob)} · ${playerHours}h</div>
                    </div>
                    <div class="stats-alert-value">${fmtCurrency(p.wealth||0)}</div>
                </div>`;
        }).join('') || '<div class="stats-empty">No leaderboard entries.</div>';
        attachLeaderboardHandlers();
    }

    if(statsSinksList){
        const sinks=Array.isArray(data.sinks)?data.sinks:[];
        statsSinksList.innerHTML=sinks.map(s=>{
            const pct=Math.min(100,Math.max(5,(s.pct||0)));
            return `
                <div class="stats-sink-row">
                    <div>${s.icon||'•'}</div>
                    <div class="stats-sink-info">
                        <div>${s.name||'Sink'}</div>
                        <div class="muted">${fmtCurrency(s.amount||0)}</div>
                    </div>
                    <div class="stats-sink-right">
                        <div>${pct}%</div>
                        <div class="stats-sink-bar"><div class="stats-sink-bar-fill" style="width:${pct}%;"></div></div>
                    </div>
                </div>`;
        }).join('') || '<div class="stats-empty">No sink data.</div>';
    }

    if(statsAlertsList){
        const alerts=Array.isArray(data.health)?data.health:[];
        statsAlertsList.innerHTML=alerts.map(alert=>{
            const status=(alert.status||'ok').toLowerCase();
            const color=status==='bad'?'rgba(248,113,113,0.9)':status==='warn'?'rgba(251,191,36,0.9)':'rgba(16,185,129,0.9)';
            return `
                <div class="stats-alert-row">
                    <div class="stats-alert-dot" style="background:${color};"></div>
                    <div class="stats-alert-meta">
                        <div>${alert.label||'Alert'}</div>
                        <div class="muted">${alert.detail||''}</div>
                    </div>
                    <div class="stats-alert-value">${alert.value||''}</div>
                </div>`;
        }).join('') || '<div class="stats-empty">No health alerts.</div>';
    }

    // Extended metrics
    if(statsShopsSummary && statsShopsList){
        const shops=data.shops||{};
        const total=Number(shops.total)||0;
        const top=Array.isArray(shops.top)?shops.top:[];
        const totalOrders=top.reduce((acc,entry)=>acc+(Number(entry.orders)||0),0);
        const avgOrder=totalOrders>0?(total/totalOrders):0;
        if(top.length){
            const avgText=avgOrder>0?` • Avg order ${fmtCurrency(Math.floor(avgOrder))}`:'';
            statsShopsSummary.textContent=`${fmtCurrency(total)} revenue • ${totalOrders} orders across ${top.length} shops today${avgText}`;
        }else{
            statsShopsSummary.textContent='No shop data.';
        }
        statsShopsList.innerHTML=top.length?top.map(item=>{
            const revenue=Number(item.revenue)||0;
            const orders=Number(item.orders)||0;
            const avgPerOrder=orders>0?fmtCurrency(Math.floor(revenue/orders)):'$0';
            const share=total>0?Math.round((revenue/total)*100):0;
            return `
                <div class="stats-mini-row">
                    <div>
                        <strong>${escapeHtml(item.name||'Shop')}</strong>
                        <div class="muted">${orders} orders • ${avgPerOrder}/order</div>
                    </div>
                    <div>
                        <div>${fmtCurrency(revenue)}</div>
                        <div class="muted">${share}% of retail</div>
                    </div>
                </div>`;
        }).join(''):'<div class="stats-empty">No sales recorded.</div>';
    }

    if(statsDrugsSummary && statsDrugsList){
        const drugs=data.drugs||{};
        const processed=Number(drugs.totalProcessed)||0;
        const sold=Number(drugs.totalSold)||0;
        const top=Array.isArray(drugs.top)?drugs.top:[];
        statsDrugsSummary.textContent=top.length?`${processed} processed • ${sold} sold (7 days)`:'No drug labs tracked.';
        statsDrugsList.innerHTML=top.length?top.map(item=>`
            <div class="stats-mini-row">
                <div>
                    <strong>${escapeHtml(item.name||'Product')}</strong>
                    <div class="muted">Processed ${item.processed||0}</div>
                </div>
                <div>Sold ${item.sold||0}</div>
            </div>`).join(''):'<div class="stats-empty">No production data.</div>';
    }

    if(statsCryptoSummary && statsCryptoList){
        const crypto=data.crypto||{};
        const fiat=Number(crypto.totalFiat)||0;
        const coin=Number(crypto.totalCoin)||0;
        const trades=Number(crypto.totalTrades)||0;
        const leaders=Array.isArray(crypto.leaders)?crypto.leaders:[];
        statsCryptoSummary.textContent=leaders.length?`${fmtCurrency(fiat)} fiat • ${coin.toLocaleString()} coin volume • ${trades} trades`:'No crypto trades yet.';
        statsCryptoList.innerHTML=leaders.length?leaders.map(item=>`
            <div class="stats-mini-row">
                <div>
                    <strong>${escapeHtml(item.name||'Trader')}</strong>
                    <div class="muted">${(item.coin||0).toLocaleString()} coin</div>
                </div>
                <div>${fmtCurrency(item.fiat||0)}</div>
            </div>`).join(''):'<div class="stats-empty">No crypto traders.</div>';
    }

    if(statsGangsSummary && statsGangsList){
        const gangs=data.gangs||{};
        const totalClean=Number(gangs.totalClean)||0;
        const totalDirty=Number(gangs.totalDirty)||0;
        const list=Array.isArray(gangs.gangs)?gangs.gangs:[];
        statsGangsSummary.textContent=list.length?`Clean ${fmtCurrency(totalClean)} • Dirty ${fmtCurrency(totalDirty)}`:'No gang data.';
        statsGangsList.innerHTML=list.length?list.map(item=>`
            <div class="stats-mini-row">
                <div><strong>${escapeHtml(item.name||'Gang')}</strong></div>
                <div>
                    <div>Clean ${fmtCurrency(item.clean||0)}</div>
                    <div class="muted">Dirty ${fmtCurrency(item.dirty||0)}</div>
                </div>
            </div>`).join(''):'<div class="stats-empty">No gangs tracked.</div>';
    }

    if(statsUpdatedSpan){
        const ts=data.updatedAt
            ? new Date(data.updatedAt*1000)
            : new Date();
        statsUpdatedSpan.textContent=`Updated ${ts.toLocaleTimeString()}`;
    }
}

function buildMockStatsData(){
    return {
        updatedAt:Math.floor(Date.now()/1000),
        kpi:{
            totalEconomy:4_720_000,
            earnedToday:182_000,
            earnedYesterday:171_000,
            spentToday:153_000
        },
        flow7d:[
            {label:'Mon',earned:180000,spent:150000},
            {label:'Tue',earned:172000,spent:160000},
            {label:'Wed',earned:190000,spent:158000},
            {label:'Thu',earned:210000,spent:170000},
            {label:'Fri',earned:238000,spent:185000},
            {label:'Sat',earned:255000,spent:198000},
            {label:'Sun',earned:199000,spent:167000}
        ],
        sources:[
            {label:'Jobs (legal)',amount:114000,pct:42,color:'rgba(59,130,246,0.9)'},
            {label:'Illegal runs',amount:76000,pct:28,color:'rgba(16,185,129,0.9)'},
            {label:'Robberies',amount:41000,pct:15,color:'rgba(251,191,36,0.9)'},
            {label:'Heists',amount:25000,pct:9,color:'rgba(248,113,113,0.9)'},
            {label:'Other',amount:16000,pct:6,color:'rgba(148,163,184,0.9)'}
        ],
        jobs:[
            {name:'Police',type:'legal',daily:87400},
            {name:'Drug courier',type:'illegal',daily:71800},
            {name:'Mechanic',type:'legal',daily:59300},
            {name:'Arms dealer',type:'illegal',daily:48100},
            {name:'Taxi driver',type:'legal',daily:33200},
            {name:'Street racer',type:'gray',daily:24500}
        ],
        leaderboard:[
            {name:'XenonRacer',job:'Police',hours:142,wealth:2_140_000,initials:'XR',color:'#1d4ed8',bg:'#1e3a5f'},
            {name:'DarkKnight99',job:'Drug courier',hours:98,wealth:1_870_000,initials:'DK',color:'#065f46',bg:'#064e3b'},
            {name:'V8Bandit',job:'Arms dealer',hours:201,wealth:1_530_000,initials:'VB',color:'#92400e',bg:'#451a03'},
            {name:'NovaZero',job:'Mechanic',hours:77,wealth:984_000,initials:'NZ',color:'#4c1d95',bg:'#2e1065'},
            {name:'SilentRyze',job:'Taxi driver',hours:55,wealth:741_000,initials:'SR',color:'#831843',bg:'#4a0520'}
        ],
        sinks:[
            {icon:'🛒',name:'Shops & black market',amount:88_200,pct:43},
            {icon:'🚗',name:'Vehicle purchases',amount:52_100,pct:26},
            {icon:'🏥',name:'Hospital bills',amount:29_400,pct:14},
            {icon:'⚖️',name:'Police fines & bail',amount:18_700,pct:9},
            {icon:'🔫',name:'Weapon purchases',amount:11_300,pct:6},
            {icon:'🏠',name:'Property / housing',amount:4_800,pct:2}
        ],
        health:[
            {label:'Economy net status',value:'Inflating',status:'warn',detail:'+2.4% / day'},
            {label:'Illegal earn ratio',value:'67%',status:'bad',detail:'Too high'},
            {label:'Inflation index',value:'+3.2%',status:'warn',detail:'Moderate'},
            {label:'Avg player wallet',value:'$48,200',status:'ok',detail:'Healthy'},
            {label:'New player earn rate',value:'$4,200/hr',status:'ok',detail:'Good onboarding'},
            {label:'Top 10% wealth share',value:'71%',status:'bad',detail:'Concentrated'}
        ]
    };
}

function requestStatistics(){
    if(statsRequestPending || !statsCanView){
        return;
    }
    statsRequestPending=true;
    statsUpdatedSpan && (statsUpdatedSpan.textContent='Requesting data...');
    cb('statsReq',{});
    if(statsRequestTimer){
        clearTimeout(statsRequestTimer);
    }
    statsRequestTimer=setTimeout(()=>{
        statsRequestPending=false;
        renderStatistics(buildMockStatsData());
    },2500);
}

function ensureStatisticsRequested(){
    if(statsAutoRequested || !statsCanView) return;
    statsAutoRequested = true;
    if(statsTabBtn){
        statsTabBtn.addEventListener('click',()=>{
            if(statsCanView){
                requestStatistics();
            }
        });
    }
    if(statsCanView){
        requestStatistics();
    }
}
let monitorPollTimer=null;
let monitorLastData=null;

// Base resolution the UI was designed for
const BASE_WIDTH=2544;
const BASE_HEIGHT=1402;

let OxoThemes=null;
let OxoActiveThemeKey=null;
let themeSelectorInitialized=false;

function applyThemeFromDefinition(theme){
    if(!theme || !theme.colors) return;
    const c=theme.colors;
    const root=document.documentElement;
    const set=(name,val)=>{
        if(typeof val==='string' && val.length){
            root.style.setProperty(name,val);
        }
    };
    set('--oxo-primary',c.primary||'#22c55e');
    set('--oxo-primary-alt',c.primaryAlt||c.primary||'#06b6d4');
    set('--oxo-bg',c.bg||'rgba(2,6,23,0.28)');
    set('--oxo-surface',c.surface||c.panel||'rgba(15,23,42,0.7)');
    set('--oxo-panel',c.panel||c.surface||'rgba(15,23,42,0.45)');
    set('--oxo-border-soft',c.borderSoft||'#374151');
    set('--oxo-text',c.text||'#e5e7eb');
    set('--oxo-muted',c.muted||'#9ca3af');
    set('--oxo-dark',c.dark||'#020617');
    set('--oxo-danger',c.danger||'#ef4444');
    set('--oxo-offline',c.offline||c.danger||'#990000');
    set('--oxo-offline-text',c.offlineText||'#fef2f2');
}

function formatUptime(sec){
    return formatDurationShort(sec);
}

function renderMonitor(data){
    monitorLastData=data||null;
    const uptimeEl=document.getElementById('monitor-uptime');
    const playersEl=document.getElementById('monitor-players');
    const pingAvgEl=document.getElementById('monitor-ping-avg');
    const pingMaxEl=document.getElementById('monitor-ping-max');
    const incidentsEl=document.getElementById('monitor-incidents');
    const offendersEl=document.getElementById('monitor-offenders');
    const suspiciousEl=document.getElementById('monitor-suspicious');

    if(uptimeEl) uptimeEl.textContent = data && typeof data.uptimeSec==='number' ? formatUptime(data.uptimeSec) : '-';
    if(playersEl) playersEl.textContent = data && typeof data.players==='number' ? String(data.players) : '-';
    if(pingAvgEl) pingAvgEl.textContent = data && typeof data.pingAvg==='number' ? String(data.pingAvg) : '-';
    if(pingMaxEl) pingMaxEl.textContent = data && typeof data.pingMax==='number' ? String(data.pingMax) : '-';

    if(incidentsEl){
        const list=(data && Array.isArray(data.incidents))?data.incidents:[];
        if(!list.length){
            incidentsEl.innerHTML='<div class="muted">No incidents yet.</div>';
        }else{
            incidentsEl.innerHTML='';
            list.forEach(it=>{
                const row=document.createElement('div');
                row.className='monitor-row';
                const t=it && typeof it.t==='number' ? new Date(it.t*1000).toLocaleTimeString() : '';
                const kind=(it && it.kind)||'event';
                const id=(it && it.id)||0;
                const name=(it && it.name)||'';
                const msg=(it && it.msg)||'';
                row.innerHTML=`<div class="monitor-row-top"><span class="monitor-pill">${kind}</span><span class="muted">${t}</span></div>`+
                              `<div class="monitor-row-main">${id?`<strong>[${id}]</strong> `:''}${name?`${name} `:''}${msg}</div>`;
                incidentsEl.appendChild(row);
            });
        }
    }

    if(offendersEl){
        const list=(data && Array.isArray(data.offenders))?data.offenders:[];
        if(!list.length){
            offendersEl.innerHTML='<div class="muted">No offenders yet.</div>';
        }else{
            offendersEl.innerHTML='';
            list.forEach(o=>{
                const row=document.createElement('div');
                row.className='monitor-row';
                const id=o && o.id;
                const name=(o && o.name)||'';
                const c=(o && o.count)||0;
                row.innerHTML=`<div class="monitor-row-main"><strong>[${id}]</strong> ${name||''}</div>`+
                              `<div class="monitor-row-sub muted">Events: ${c}</div>`;
                offendersEl.appendChild(row);
            });
        }
    }

    if(suspiciousEl){
        const list=(data && Array.isArray(data.suspicious))?data.suspicious:[];
        if(!list.length){
            suspiciousEl.innerHTML='<div class="muted">No suspicious players right now.</div>';
        }else{
            suspiciousEl.innerHTML='';
            list.forEach(s=>{
                const row=document.createElement('div');
                row.className='monitor-row';
                const id=s && s.id;
                const name=(s && s.name)||'';
                const reasons=(s && s.reasons)||'';
                row.innerHTML=`<div class="monitor-row-main"><strong>[${id}]</strong> ${name||''}</div>`+
                              `<div class="monitor-row-sub muted">${reasons}</div>`;
                suspiciousEl.appendChild(row);
            });
        }
    }
}

function stopMonitorPolling(){
    if(monitorPollTimer){
        clearInterval(monitorPollTimer);
        monitorPollTimer=null;
    }
}

function ensureMonitorPolling(){
    if(monitorPollTimer) return;
    cb('monitorReq',{});
    monitorPollTimer=setInterval(()=>{
        cb('monitorReq',{});
    },2000);
}

function applyThemeByKey(key){
    if(!OxoThemes) return;
    const def=OxoThemes[key];
    if(!def) return;
    OxoActiveThemeKey=key;
    try{ localStorage.setItem('oxoThemeKey',key); }catch(e){}
    applyThemeFromDefinition(def);
}

function initThemeSelectorOnce(){
    if(themeSelectorInitialized) return;
    themeSelectorInitialized=true;
    const sel=document.getElementById('dev-theme-select');
    const btn=document.getElementById('dev-theme-apply');
    if(!sel || !OxoThemes) return;

    sel.innerHTML='';
    Object.keys(OxoThemes).forEach(key=>{
        const def=OxoThemes[key]||{};
        const opt=document.createElement('option');
        opt.value=key;
        opt.textContent=def.label||key;
        if(key===OxoActiveThemeKey) opt.selected=true;
        sel.appendChild(opt);
    });

    const applyFromSelect=()=>{
        const key=sel.value;
        applyThemeByKey(key);
    };

    if(btn) btn.addEventListener('click',applyFromSelect);
    sel.addEventListener('change',applyFromSelect);
}

if(selfTabBtn){
    // Default to red (off duty) until server tells us current duty state
    selfTabBtn.classList.add('self-off');
}

function pickAdminVehicleIcon(v,opts){
    const catKey=((opts && opts.categoryKey) || v.category || '').toString().toLowerCase();
    const catLabel=((opts && opts.categoryLabel) || v.categoryLabel || '').toString().toLowerCase();
    const cls=(v.vehicleClassLabel || '').toString().toLowerCase();
    const name=(v.name || v.label || v.model || '').toString().toLowerCase();
    const s=`${catKey} ${catLabel} ${cls} ${name}`;

    if(/bike|motorcycle|moto|cycle/.test(s)) return 'fa-motorcycle';
    if(/heli|helicopter|chopper/.test(s)) return 'fa-helicopter';
    if(/plane|jet|aircraft/.test(s)) return 'fa-plane';
    if(/boat|yacht|ship|submarine/.test(s)) return 'fa-ship';
    if(/bus|coach/.test(s)) return 'fa-bus';
    if(/van|truck|lorry|utility|box/.test(s)) return 'fa-truck-pickup';
    if(/amb|ambulance|ems|medic/.test(s)) return 'fa-truck-medical';
    if(/police|cop|politi|pd|sheriff|lspd/.test(s)) return 'fa-shield-halved';
    return 'fa-car-side';
}

function isModelFavorite(model){
    if(!model) return false;
    if(!(adminVehicleFavorites instanceof Set)) return false;
    return adminVehicleFavorites.has(String(model).toLowerCase());
}

function setModelFavorite(model,on){
    if(!model) return;
    const key=String(model).toLowerCase();
    if(!(adminVehicleFavorites instanceof Set)) adminVehicleFavorites=new Set();
    if(on) adminVehicleFavorites.add(key);
    else adminVehicleFavorites.delete(key);
    // Persist to server
    cb('vehicleFavorite',{model:model,favorite:on});
}

function toggleModelFavorite(model){
    if(!model) return;
    const nowFav=!isModelFavorite(model);
    setModelFavorite(model,nowFav);
    // Re-render categories so stars and Favorites group update
    renderAdminVehicleCategories();
}

function showAdminVehiclePreview(v,opts){
    const preview=document.getElementById('veh-admin-preview');
    if(!preview || !v) return;
    preview.classList.add('veh-admin-preview-has-car');
    const name=v.name || v.label || v.model || 'Vehicle';
    const brand=v.brand || '';
    const model=v.model || '';
    const categoryLabel=(opts && opts.categoryLabel) || v.categoryLabel || (v.category ? String(v.category).toUpperCase() : 'Vehicle');
    const classLabel=v.vehicleClassLabel || '';
    const seats=(typeof v.seats==='number' && v.seats>0)?v.seats:null;
    const perf=v.performanceTag || '';
    const priceNum=typeof v.price==='number'?v.price:0;
    const priceText=priceNum>0?'€'+priceNum.toLocaleString():'Price: N/A';
    const iconClass=pickAdminVehicleIcon(v,opts);
    const subtitleParts=[];
    if(brand) subtitleParts.push(brand);
    if(model) subtitleParts.push(model.toUpperCase());
    const subtitle=subtitleParts.join(' • ');

    // Build image path for this vehicle model
    const imgFile=(model||'').toString().trim().toLowerCase()+'.png';
    // Serve from this resource's images_cars folder via NUI URL using normalized name
    const imgBase='nui://'+resNameNui+'/images_cars/';
    const imgPath=imgBase+imgFile;
    const detailsParts=[];
    if(classLabel) detailsParts.push(classLabel);
    if(seats) detailsParts.push(seats+' seats');
    if(perf) detailsParts.push(perf);
    const detailsText=detailsParts.join(' • ');

    const isFav=isModelFavorite(model);
    const favIconClass=isFav?'fa-solid fa-star':'fa-regular fa-star';
    const favLabel=isFav?'Favorited':'Add to favorites';

    preview.innerHTML=
        '<div class="veh-admin-preview-inner">'+
          '<div class="veh-admin-preview-image-wrap">'+
            '<div class="veh-admin-preview-placeholder"><i class="fa-solid '+iconClass+'"></i></div>'+
          '</div>'+
          '<div class="veh-admin-preview-main">'+
            '<div class="veh-admin-preview-title">'+name+'</div>'+
            '<div class="veh-admin-preview-sub">'+(subtitle||'Model: '+(model||'unknown'))+'</div>'+
            (detailsText?'<div class="veh-admin-preview-sub2">'+detailsText+'</div>':'')+
            '<div class="veh-admin-preview-meta-row">'+
              '<span class="veh-admin-preview-pill">'+categoryLabel+'</span>'+
              '<span class="veh-admin-preview-price">'+priceText+'</span>'+
              '<button type="button" class="veh-admin-preview-fav '+(isFav?'on':'')+'">'+
                '<i class="'+favIconClass+'"></i>'+
                '<span>'+favLabel+'</span>'+
              '</button>'+
            '</div>'+
          '</div>'+
          '<div class="veh-admin-preview-actions">'+
            '<button type="button" class="veh-admin-preview-spawn"><i class="fa-solid '+iconClass+'"></i><span>Spawn this vehicle</span></button>'+
          '</div>'+
        '</div>';

    const modelInput=document.getElementById('veh-model');
    const plateInput=document.getElementById('veh-plate');
    if(modelInput) modelInput.value=model;
    if(plateInput && v.plate) plateInput.value=v.plate;

    const spawnBtn=preview.querySelector('.veh-admin-preview-spawn');
    if(spawnBtn){
        spawnBtn.addEventListener('click',()=>{
            const btn=document.getElementById('veh-spawn');
            if(btn){
                if(modelInput && (!modelInput.value || !modelInput.value.trim())){
                    modelInput.value=model;
                }
                btn.click();
            }
        });
    }

    const favBtn=preview.querySelector('.veh-admin-preview-fav');
    if(favBtn){
        favBtn.addEventListener('click',()=>{
            toggleModelFavorite(model);
        });
    }
}

function renderAdminVehicleCategories(){
    if(!vehAdminList) return;
    vehAdminList.innerHTML='';
    const searchInput=document.getElementById('veh-admin-search');
    const filterRaw=searchInput?searchInput.value||'':'';
    const filter=filterRaw.trim().toLowerCase();
    const keys=Object.keys(adminVehicleCategories||{});
    if(!keys.length){
        vehAdminList.innerHTML='<span class="muted">No admin vehicles configured.</span>';
        const preview=document.getElementById('veh-admin-preview');
        if(preview){
            preview.innerHTML='<div class="veh-admin-preview-empty muted">Select a vehicle to preview.</div>';
            preview.classList.remove('veh-admin-preview-has-car');
        }
        return;
    }
    keys.sort((a,b)=>{
        const la=adminVehicleCategories[a].label.toLowerCase();
        const lb=adminVehicleCategories[b].label.toLowerCase();
        if(la<lb) return -1; if(la>lb) return 1; return 0;
    });

    // Build two-column layout: left categories, right shared vehicle list
    const leftCol=document.createElement('div');
    leftCol.className='veh-admin-main-left';
    const groupsContainer=document.createElement('div');
    groupsContainer.className='veh-admin-groups';
    // Three fixed columns: left (Cars), middle (Air + Emergency), right (Specialized)
    const colLeft=document.createElement('div');
    colLeft.className='veh-admin-col veh-admin-col-left';
    const colMiddle=document.createElement('div');
    colMiddle.className='veh-admin-col veh-admin-col-middle';
    const colRight=document.createElement('div');
    colRight.className='veh-admin-col veh-admin-col-right';
    groupsContainer.appendChild(colLeft);
    groupsContainer.appendChild(colMiddle);
    groupsContainer.appendChild(colRight);
    leftCol.appendChild(groupsContainer);

    const rightCol=document.createElement('div');
    rightCol.className='veh-admin-main-right';
    rightCol.innerHTML=
        '<div class="veh-admin-right-header">'+
          '<span id="veh-admin-right-title" class="muted">Select a category</span>'+
        '</div>'+
        '<div id="veh-admin-right-list" class="veh-admin-right-list"></div>';

    vehAdminList.appendChild(leftCol);
    vehAdminList.appendChild(rightCol);

    const rightTitle=vehAdminList.querySelector('#veh-admin-right-title');
    const rightList=vehAdminList.querySelector('#veh-admin-right-list');

    // High-level boxes for the left side
    const groups={emergency:[],air:[],special:[],cars:[],motorcycles:[],boats:[],favorites:[]};
    const favoriteVehicles=[];

    const classifyGroup=(catKey,catLabel)=>{
        const s=((catKey||'')+' '+(catLabel||'')).toLowerCase();
        // Air first so police helicopters go to Planes & Helicopters, not Police
        if(/heli|helicopter|chopper|aircraft|plane|jet/.test(s)) return 'air';
        // Emergency vehicles: police + ambulance style
        if(/amb|ambulance|ems|medic/.test(s)) return 'emergency';
        if(/police|cop|politi|pd|sheriff|lspd/.test(s)) return 'emergency';
        // Boats in their own Boats group
        if(/boat|yacht|ship|submarine/.test(s)) return 'boats';
        // Motorcycles in their own Motorcycles group
        if(/bike|motorcycle|moto|cycle/.test(s)) return 'motorcycles';
        // Specialized: buses, commercial, service, military, trucks, etc.
        if(/bus|coach|commercial|utility|service|truck|lorry|van|industrial|military|army|tank|armou?red|offroad|special/.test(s)) return 'special';
        // Default: regular cars and generic categories
        return 'cars';
    };

    keys.forEach(key=>{
        const cat=adminVehicleCategories[key];
        if(!cat || !Array.isArray(cat.vehicles) || !cat.vehicles.length) return;
        const catKeyName=String(cat.key || key || '').toLowerCase();
        const catLabel=cat.label||key.toUpperCase();
        const catLabelLower=catLabel.toLowerCase();
        // Skip the special Admin category from the UI
        if(catKeyName==='admin' || catLabelLower==='admin') return;
        const filteredVehicles=[];

        cat.vehicles.forEach(v=>{
            if(!v || !v.model) return;
            const name=v.name || v.label || v.model;
            const brand=v.brand || '';
            const model=v.model || '';
            const catKey=String(cat.key || key || '').toLowerCase();
            const haystack=(name+' '+brand+' '+model+' '+catLabel+' '+catKey).toLowerCase();
            if(filter && haystack.indexOf(filter)===-1) return;
            filteredVehicles.push(v);

            const modelKey=String(v.model||'').toLowerCase();
            if(isModelFavorite(modelKey)){
                favoriteVehicles.push(v);
            }
        });

        if(!filteredVehicles.length) return;

        const wrap=document.createElement('div');
        wrap.className='veh-admin-category';
        const header=document.createElement('div');
        header.className='veh-admin-category-header';
        header.innerHTML=
            '<div class="veh-admin-category-header-main">'+
              '<span class="veh-admin-category-label-pill">'+catLabel+'</span>'+
              '<span class="veh-admin-category-count">'+filteredVehicles.length+' vehicles</span>'+
            '</div>'+
            '<div class="veh-admin-category-header-sub muted">'+catLabel+'</div>'+
            '<div class="veh-admin-category-toggle"><i class="fa-solid fa-chevron-right"></i></div>';

        header.addEventListener('click',()=>{
            // Mark this category active and clear right-hand list
            groupsContainer.querySelectorAll('.veh-admin-category.active').forEach(el=>el.classList.remove('active'));
            wrap.classList.add('active');
            if(rightTitle){
                rightTitle.textContent=catLabel+' ('+filteredVehicles.length+' vehicles)';
                rightTitle.classList.remove('muted');
            }
            if(rightList){
                rightList.innerHTML='';
                filteredVehicles.forEach(v=>{
                    if(!v || !v.model) return;
                    const name=v.name || v.label || v.model;
                    const brand=v.brand || '';
                    const model=v.model || '';
                    const priceNum=typeof v.price==='number'?v.price:0;
                    const metaParts=[];
                    if(brand) metaParts.push(brand);
                    if(priceNum>0) metaParts.push('€'+priceNum.toLocaleString());
                    const metaText=metaParts.length?'<span class="veh-admin-item-meta">'+metaParts.join(' • ')+'</span>':'';
                    const btn=document.createElement('button');
                    btn.type='button';
                    btn.className='veh-admin-item';
                    btn.dataset.model=v.model;
                    btn.dataset.category=key;
                    const isFav=isModelFavorite(model);
                    const favSpan='<span class="veh-admin-item-fav '+(isFav?'on':'')+'"><i class="'+(isFav?'fa-solid':'fa-regular')+' fa-star"></i></span>';
                    btn.innerHTML=favSpan+'<span class="veh-admin-item-name">'+name+'</span>'+metaText;

                    const favIcon=btn.querySelector('.veh-admin-item-fav');
                    if(favIcon){
                        favIcon.addEventListener('click',(ev)=>{
                            ev.stopPropagation();
                            toggleModelFavorite(model);
                        });
                    }
                    btn.addEventListener('click',()=>{
                        if(!rightList) return;
                        rightList.querySelectorAll('.veh-admin-item.active').forEach(el=>el.classList.remove('active'));
                        btn.classList.add('active');
                        selectedAdminVehicleModel=v.model;
                        showAdminVehiclePreview(v,{categoryKey:key,categoryLabel:catLabel});
                    });
                    rightList.appendChild(btn);
                });

                // Limit visible items to 27, then scroll the rest
                const items=rightList.querySelectorAll('.veh-admin-item');
                if(items.length>27){
                    const first=items[0];
                    const h=first && first.getBoundingClientRect ? first.getBoundingClientRect().height : 0;
                    if(h>0){
                        rightList.style.maxHeight=(h*27)+'px';
                    }
                }else{
                    rightList.style.maxHeight='';
                }
            }
        });

        wrap.appendChild(header);

        const groupKey=classifyGroup(cat.key||key,catLabel);
        if(!groups[groupKey]) groups[groupKey]=[];
        groups[groupKey].push(wrap);
    });

    // Synthetic Favorites category (combined from all categories)
    if(favoriteVehicles.length){
        const favLabel='Favorites';
        const favWrap=document.createElement('div');
        favWrap.className='veh-admin-category veh-admin-category-favorites';
        const header=document.createElement('div');
        header.className='veh-admin-category-header';
        header.innerHTML=
            '<div class="veh-admin-category-header-main">'+
              '<span class="veh-admin-category-label-pill">'+favLabel+'</span>'+
              '<span class="veh-admin-category-count">'+favoriteVehicles.length+' vehicles</span>'+
            '</div>'+
            '<div class="veh-admin-category-toggle"><i class="fa-solid fa-chevron-right"></i></div>';

        header.addEventListener('click',()=>{
            groupsContainer.querySelectorAll('.veh-admin-category.active').forEach(el=>el.classList.remove('active'));
            favWrap.classList.add('active');
            if(rightTitle){
                rightTitle.textContent=favLabel+' ('+favoriteVehicles.length+' vehicles)';
                rightTitle.classList.remove('muted');
            }
            if(rightList){
                rightList.innerHTML='';
                favoriteVehicles.forEach(v=>{
                    if(!v || !v.model) return;
                    const name=v.name || v.label || v.model;
                    const brand=v.brand || '';
                    const model=v.model || '';
                    const priceNum=typeof v.price==='number'?v.price:0;
                    const metaParts=[];
                    if(brand) metaParts.push(brand);
                    if(priceNum>0) metaParts.push('€'+priceNum.toLocaleString());
                    const metaText=metaParts.length?'<span class="veh-admin-item-meta">'+metaParts.join(' • ')+'</span>':'';
                    const btn=document.createElement('button');
                    btn.type='button';
                    btn.className='veh-admin-item';
                    btn.dataset.model=v.model;
                    btn.dataset.category=v.category || '';
                    const isFav=isModelFavorite(model);
                    const favSpan='<span class="veh-admin-item-fav '+(isFav?'on':'')+'"><i class="'+(isFav?'fa-solid':'fa-regular')+' fa-star"></i></span>';
                    btn.innerHTML=favSpan+'<span class="veh-admin-item-name">'+name+'</span>'+metaText;

                    const favIcon=btn.querySelector('.veh-admin-item-fav');
                    if(favIcon){
                        favIcon.addEventListener('click',(ev)=>{
                            ev.stopPropagation();
                            toggleModelFavorite(model);
                        });
                    }

                    btn.addEventListener('click',()=>{
                        if(!rightList) return;
                        rightList.querySelectorAll('.veh-admin-item.active').forEach(el=>el.classList.remove('active'));
                        btn.classList.add('active');
                        selectedAdminVehicleModel=v.model;
                        showAdminVehiclePreview(v,{categoryKey:v.category,categoryLabel:catLabel});
                    });
                    rightList.appendChild(btn);
                });
            }
        });

        favWrap.appendChild(header);
        if(!groups.favorites) groups.favorites=[];
        groups.favorites.push(favWrap);
    }

    // Left side boxes: Cars column, Specialized+Motorcycles column, Air+Boats+Emergency column
    const groupDefs=[
        {id:'cars',label:'Cars',icon:'fa-car-side'},
        {id:'special',label:'Specialized Vehicles',icon:'fa-truck'},
        {id:'motorcycles',label:'Motorcycles',icon:'fa-motorcycle'},
        {id:'air',label:'Planes & Helicopters',icon:'fa-plane-up'},
        {id:'boats',label:'Boats',icon:'fa-sailboat'},
        {id:'emergency',label:'Emergency Vehicles',icon:'fa-shield-halved'},
        {id:'favorites',label:'Favorites',icon:'fa-star'}
    ];

    let anyGroup=false;
    groupDefs.forEach(g=>{
        const list=groups[g.id];
        if(!list || !list.length) return;
        anyGroup=true;
        const box=document.createElement('div');
        box.className='veh-admin-group veh-admin-group-'+g.id;
        box.innerHTML=
            '<div class="veh-admin-group-header">'+
              '<i class="fa-solid '+g.icon+'"></i>'+
              '<span>'+g.label+'</span>'+
            '</div>';
        const body=document.createElement('div');
        body.className='veh-admin-group-body';
        list.forEach(card=>body.appendChild(card));
        box.appendChild(body);

        // Place each box into its fixed column
        let targetCol=colLeft; // default: Cars
        if(g.id==='special' || g.id==='motorcycles'){
            // Specialized and Motorcycles in the middle column
            targetCol=colMiddle;
        }else if(g.id==='air' || g.id==='boats' || g.id==='emergency' || g.id==='favorites'){
            // Air/Boats/Emergency/Favorites in the right column
            targetCol=colRight;
        }
        targetCol.appendChild(box);
    });

    if(!anyGroup){
        vehAdminList.innerHTML='<span class="muted">No admin vehicles match this search.</span>';
    }
}

// Hook admin vehicle search to live-filter
const vehAdminSearchInput=document.getElementById('veh-admin-search');
if(vehAdminSearchInput){
    const onChange=()=>renderAdminVehicleCategories();
    vehAdminSearchInput.addEventListener('input',onChange);
    vehAdminSearchInput.addEventListener('change',onChange);
}

function applyAppScale(){
    if(!app) return;
    const vw=window.innerWidth||0;
    const vh=window.innerHeight||0;
    if(vw<=0||vh<=0) return;
    // Uniform scale so the layout keeps its proportions, capped at 1 so it never grows larger than designed
    const scale=Math.min(vw/BASE_WIDTH,vh/BASE_HEIGHT,1);
    app.style.transform=`scale(${scale})`;
    app.style.transformOrigin='top left';
}

window.addEventListener('resize',applyAppScale);
applyAppScale();

if(miniPanel){
    miniPanel.classList.add('hidden');
}

let oxoTooltipEl=null;
let oxoTooltipTimer=null;
let oxoTooltipTarget=null;

function oxoGetHelpText(el){
    if(!window.OxoHelpTexts || !el) return null;
    const ht=window.OxoHelpTexts;
    const id=el.id;
    if(id && ht.byId && ht.byId[id]) return ht.byId[id];
    const ds=el.dataset||{};
    if(ds.self && ht.self && ht.self[ds.self]) return ht.self[ds.self];
    if(ds.miniSelf && ht.miniSelf && ht.miniSelf[ds.miniSelf]) return ht.miniSelf[ds.miniSelf];
    if(ds.player && ht.player && ht.player[ds.player]) return ht.player[ds.player];
    if(ds.miniPlayer && ht.miniPlayer && ht.miniPlayer[ds.miniPlayer]) return ht.miniPlayer[ds.miniPlayer];
    if(ds.serverClean && ht.serverClean && ht.serverClean[ds.serverClean]) return ht.serverClean[ds.serverClean];
    if(ds.vehicle && ht.veh && ht.veh[ds.vehicle]) return ht.veh[ds.vehicle];
    if(ds.miniDev && ht.devMini && ht.devMini[ds.miniDev]) return ht.devMini[ds.miniDev];
    return null;
}

function oxoEnsureTooltip(){
    if(oxoTooltipEl) return oxoTooltipEl;
    const el=document.createElement('div');
    el.className='oxo-tooltip hidden';
    document.body.appendChild(el);
    oxoTooltipEl=el;
    return el;
}

function oxoHideTooltip(){
    if(oxoTooltipTimer){
        clearTimeout(oxoTooltipTimer);
        oxoTooltipTimer=null;
    }
    oxoTooltipTarget=null;
    if(oxoTooltipEl){
        oxoTooltipEl.classList.add('hidden');
    }
}

document.addEventListener('mouseover',e=>{
    const el=e.target.closest('button,[data-self],[data-mini-self],[data-player],[data-mini-player],[data-server-clean],[data-mini-dev]');
    if(!el) return;
    const text=oxoGetHelpText(el);
    if(!text) return;
    oxoHideTooltip();
    oxoTooltipTarget=el;
    oxoTooltipTimer=setTimeout(()=>{
        if(!oxoTooltipTarget || oxoTooltipTarget!==el) return;
        const tip=oxoEnsureTooltip();
        tip.textContent=text;
        tip.classList.remove('hidden');
        const rect=el.getBoundingClientRect();
        const x=rect.right+8;
        const y=rect.top;
        tip.style.left=x+'px';
        tip.style.top=y+'px';
    },4000);
});

['mouseout','mousedown','click','keydown','scroll'].forEach(ev=>{
    document.addEventListener(ev,()=>{
        oxoHideTooltip();
    },true);
});

function hasPermUi(key){
    return !!(myPerms && myPerms[key]);
}

function anyPerm(keys){
    if(!keys || !keys.length) return false;
    for(let i=0;i<keys.length;i++){
        if(hasPermUi(keys[i])) return true;
    }
    return false;
}

function showOrHide(el,allowed){
    if(!el) return;
    el.style.display = allowed ? '' : 'none';
}

function cb(name,data){
    const payload=JSON.stringify(data||{});
    const post=(r)=>fetch(`https://${r}/${name}` ,{
        method:'POST',
        headers:{'Content-Type':'application/json; charset=UTF-8'},
        body:payload
    }).then(resp=>{
        if(!resp || !resp.ok) throw new Error('nui');
    });

    const primary=(resNameNui && resNameNui.length)?resNameNui:resName;
    post(primary).catch(()=>{
        if(primary!==resName) return post(resName);
    });
}

function copyToClipboard(text){
    const value=(text||'').toString();

    // 1) Classic textarea + execCommand path (most reliable in FiveM NUI)
    try{
        const ta=document.createElement('textarea');
        ta.value=value;
        ta.setAttribute('readonly','');
        ta.style.position='absolute';
        ta.style.left='-9999px';
        document.body.appendChild(ta);
        ta.select();
        const ok=document.execCommand('copy');
        document.body.removeChild(ta);
        if(ok) return;
    }catch(e){}

    // 2) FiveM native clipboard, if available
    try{
        if(typeof window!=='undefined' && typeof window.invokeNative==='function'){
            window.invokeNative('SET_CLIPBOARD', value);
            return;
        }
    }catch(e){}

    // 3) Browser clipboard API as last fallback
    if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(value);
    }
}

function updateRoleBadge(label){
    if(!roleBadge || !roleBadgeName) return;
    const name=(label||'').toString().trim();
    if(!name){
        roleBadge.classList.add('hidden');
        return;
    }
    roleBadgeName.textContent=name;
    roleBadge.classList.remove('hidden');
}

function updateDutyHoursBadge(totalSeconds){
    if(!roleBadge || !roleBadgeHours) return;
    let sec = Number(totalSeconds)||0;
    if(sec < 0) sec = 0;
    const hours = sec/3600;
    let text;
    if(hours >= 100) text = hours.toFixed(0)+' h';
    else text = hours.toFixed(1)+' h';
    roleBadgeHours.textContent = text;
    // Ensure badge is visible when we have duty data
    roleBadge.classList.remove('hidden');
}

function formatHoursShort(sec){
    let s=Number(sec)||0;
    if(s<=0) return '0.0 h';
    const h=s/3600;
    if(h>=100) return h.toFixed(0)+' h';
    return h.toFixed(1)+' h';
}

function formatDurationShort(sec){
    let s=Number(sec)||0;
    if(s<=0) return '<1m';
    const mins=Math.floor(s/60);
    const hours=Math.floor(mins/60);
    const days=Math.floor(hours/24);
    if(days>0) return `${days}d ${hours%24}h`;
    if(hours>0) return `${hours}h ${mins%60}m`;
    if(mins>0) return `${mins}m`;
    return '<1m';
}

function formatMoneyShort(amount){
    const n=Number(amount)||0;
    if(!n) return '$0';
    return '$'+n.toLocaleString();
}

const DUTY_STREAK_THRESHOLD_SEC=2*3600;

function updateSelfDutyUi(){
    const card=selfOffdutyCard;
    const layout=document.querySelector('.self-layout');
    const stats=currentSelfStats||null;
    const known=!!myDutyKnown;
    const on=!!myDutyOn;

    const isOnDuty=known && on;
    if(selfPlayerStatsCard){
        selfPlayerStatsCard.classList.toggle('self-player-stats-card-on',isOnDuty);
        selfPlayerStatsCard.classList.toggle('self-player-stats-card-off',!isOnDuty);
    }

    if(selfPlayerLabel){
        selfPlayerLabel.textContent=isOnDuty?'Staff Powers':'Staff Stats';
    }

    if(selfPlayerName){
        let label='Player';
        if(stats && typeof stats.playerName==='string'){
            const trimmed=stats.playerName.trim();
            if(trimmed) label=trimmed;
        }
        selfPlayerName.textContent=label;
    }

    // Only show off-duty card when we have a known duty state, are truly off duty AND have stats.
    const isOffDuty=(known && !on && !!stats);

    if(card){
        if(isOffDuty) card.classList.remove('hidden');
        else card.classList.add('hidden');
    }
    if(layout){
        // Hide main self controls only when showing the off-duty card.
        showOrHide(layout,!isOffDuty);
    }

    // Hide the header 30-day graph when not off duty or lacking stats
    if(selfDutyGraph){
        if(!isOffDuty || !stats){
            selfDutyGraph.classList.add('hidden');
            selfDutyGraph.innerHTML='';
        }
    }

    if(!card || !stats || on) return;

    // Pre-compute main duty durations
    const totalSec=Number(stats.dutyTotalSeconds)||0;
    const weekSec=Number(stats.dutyWeekSeconds)||0;
    const todaySec=Number(stats.dutyTodaySeconds)||0;
    const totalHoursText=formatHoursShort(totalSec);
    const weekHoursText=formatHoursShort(weekSec);
    const todayHoursText=formatHoursShort(todaySec);

    // Hero pill for last 7 days with lifetime context
    if(selfOffdutyTotal){
        // Split layout: left shows last 7 days, right shows lifetime in its own pill
        selfOffdutyTotal.innerHTML=
            `<div class="self-offduty-metric-pill self-offduty-metric-main">`+
              `<div class="self-offduty-metric-main-row">`+
                `<div class="self-offduty-metric-main-left">`+
                  `<div class="self-offduty-metric-label">Last 7 days</div>`+
                  `<div class="self-offduty-metric-value">${weekHoursText}</div>`+
                `</div>`+
                `<div class="self-offduty-metric-main-divider"></div>`+
                `<div class="self-offduty-metric-main-right">`+
                  `<div class="self-offduty-metric-mini-pill">`+
                    `<div class="self-offduty-metric-caption">Lifetime: ${totalHoursText}</div>`+
                  `</div>`+
                `</div>`+
              `</div>`+
            `</div>`;
    }

    // Last shift block
    const shifts=Array.isArray(stats.dutyShifts)?stats.dutyShifts:[];
    let lastShiftValue='-';
    let lastShiftSub='';
    let lastShiftDateLabel='';
    let lastShiftStartTime='';
    let lastShiftStopTime='';
    if(shifts.length){
        const last=shifts[shifts.length-1]||{};
        const sec=Number(last.seconds)||0;
        lastShiftValue=formatDurationShort(sec);
        const startTs=typeof last.start==='number'?last.start:null;
        const stopTs=typeof last.stop==='number'?last.stop:null;
        if(startTs && stopTs){
            const startDate=new Date(startTs*1000);
            const stopDate=new Date(stopTs*1000);
            const monthNames=['January','February','March','April','May','June','July','August','September','October','November','December'];
            const day=startDate.getDate();
            const monthName=monthNames[startDate.getMonth()]||String(startDate.getMonth()+1);
            const year=startDate.getFullYear();
            lastShiftDateLabel=`${day} ${monthName} ${year}`;
            lastShiftStartTime=startDate.toLocaleTimeString();
            lastShiftStopTime=stopDate.toLocaleTimeString();
            // Combined string kept for potential fallback
            const startStr=startDate.toLocaleString();
            const stopStr=stopDate.toLocaleString();
            lastShiftSub=`${startStr} \u0013 ${stopStr}`;
        }
    }
    if(selfOffdutyLastshift){
        if(lastShiftDateLabel && lastShiftStartTime && lastShiftStopTime){
            // Timeline layout with date pill
            selfOffdutyLastshift.innerHTML=
                `<div class="self-offduty-meta-line">`+
                  `<div class="self-offduty-meta-icon"><i class="fa-solid fa-clock-rotate-left"></i></div>`+
                  `<div class="self-offduty-meta-content">`+
                    `<div class="self-offduty-meta-head-row">`+
                      `<div class="self-offduty-meta-label">Last shift timeline</div>`+
                      `<div class="self-offduty-meta-date-pill">${lastShiftDateLabel}</div>`+
                    `</div>`+
                    `<div class="self-offduty-lastshift-timeline">`+
                      `<span class="self-offduty-lastshift-time self-offduty-lastshift-time-start">${lastShiftStartTime}</span>`+
                      `<div class="self-offduty-lastshift-line">`+
                        `<span class="self-offduty-lastshift-marker"></span>`+
                      `</div>`+
                      `<span class="self-offduty-lastshift-time self-offduty-lastshift-time-stop">${lastShiftStopTime}</span>`+
                    `</div>`+
                    `<div class="self-offduty-lastshift-duration">${lastShiftValue}</div>`+
                  `</div>`+
                `</div>`;
        }else{
            // Fallback: simple text layout
            selfOffdutyLastshift.innerHTML=
                `<div class="self-offduty-meta-line">`+
                  `<div class="self-offduty-meta-icon"><i class="fa-solid fa-clock-rotate-left"></i></div>`+
                  `<div class="self-offduty-meta-content">`+
                    `<div class="self-offduty-meta-label">Last shift</div>`+
                    `<div class="self-offduty-meta-value">${lastShiftValue}</div>`+
                    (lastShiftSub?`<div class="self-offduty-meta-sub">${lastShiftSub}</div>`:'')+
                  `</div>`+
                `</div>`;
        }
    }

    // Last on duty timestamp (date pill + time)
    let lastOnValue='never';
    let lastOnDateLabel='';
    let lastOnTime='';
    if(typeof stats.dutyLastOn==='number' && stats.dutyLastOn>0){
        const d=new Date(stats.dutyLastOn*1000);
        const monthNames=['January','February','March','April','May','June','July','August','September','October','November','December'];
        const day=d.getDate();
        const monthName=monthNames[d.getMonth()]||String(d.getMonth()+1);
        const year=d.getFullYear();
        lastOnDateLabel=`${day} ${monthName} ${year}`;
        lastOnTime=d.toLocaleTimeString();
        lastOnValue=d.toLocaleString();
    }
    if(selfOffdutyLaston){
        if(lastOnDateLabel && lastOnTime){
            selfOffdutyLaston.innerHTML=
                `<div class="self-offduty-meta-line">`+
                  `<div class="self-offduty-meta-icon"><i class="fa-solid fa-user-clock"></i></div>`+
                  `<div class="self-offduty-meta-content">`+
                    `<div class="self-offduty-meta-head-row self-offduty-meta-head-row-laston">`+
                      `<div class="self-offduty-meta-label">Last on duty</div>`+
                      `<div class="self-offduty-meta-datetime">`+
                        `<div class="self-offduty-meta-date-pill">${lastOnDateLabel}</div>`+
                        `<div class="self-offduty-laston-time">${lastOnTime}</div>`+
                      `</div>`+
                    `</div>`+
                  `</div>`+
                `</div>`;
        }else{
            selfOffdutyLaston.innerHTML=
                `<div class="self-offduty-meta-line">`+
                  `<div class="self-offduty-meta-icon"><i class="fa-solid fa-user-clock"></i></div>`+
                  `<div class="self-offduty-meta-content">`+
                    `<div class="self-offduty-meta-label">Last on duty</div>`+
                    `<div class="self-offduty-meta-value">${lastOnValue}</div>`+
                  `</div>`+
                `</div>`;
        }
    }

    // Duty focus: show raw duty hours for Today / Last 7 days / Last 30 days, plus monthly target info
    if(selfOffdutyDutyextra){
        const last30Sec = Number(stats.dutyLast30Seconds)||0;
        const last30Text = formatHoursShort(last30Sec);
        const req30Sec = Number(stats.dutyLast30RequirementSeconds)||0;
        let last30Display = last30Text;
        let last30Extra = '';
        let last30ChartHtml = '';
        let last30AvgText = '';
        if(req30Sec>0){
            const targetText = formatHoursShort(req30Sec);
            const rawPct = req30Sec>0 ? Math.round((last30Sec/req30Sec)*100) : 0;
            const barPct = req30Sec>0 ? Math.max(0,Math.min(100,(last30Sec/req30Sec)*100)) : 0;
            const daysWindow = 30;
            const avgHoursPerDay = daysWindow>0 ? (last30Sec/3600)/daysWindow : 0;
            const isReached = rawPct>=100;
            last30Display = `${last30Text} / ${targetText}`;

            const parts = [];
            parts.push(`Monthly target: ${targetText}`);
            parts.push(`${rawPct}%`);
            let avgText='';
            if(avgHoursPerDay>0){
                avgText = `avg ${avgHoursPerDay.toFixed(2)} h/day`;
            }
            const deltaSec = last30Sec-req30Sec;
            if(deltaSec<0){
                const remainText = formatHoursShort(-deltaSec);
                const farBehind = rawPct<50; // emphasize when well below half the target
                const remainLabel = farBehind
                    ? `<span class="self-offduty-remaining-bad">${remainText} remaining</span>`
                    : `${remainText} remaining`;
                parts.push(remainLabel);
            }else if(deltaSec>0){
                const overText = formatHoursShort(deltaSec);
                parts.push(`${overText} over`);
            }
            const captionText = parts.join(' &bull; ');
            const captionHtml =
                `<div class="self-offduty-metric-caption self-offduty-30d-caption">`+
                  `<span class="self-offduty-30d-caption-main">${captionText}</span>`+
                `</div>`;

            const trackClass = isReached
                ? 'self-offduty-progress-track self-offduty-progress-track-reached'
                : 'self-offduty-progress-track';

            let graphHtml='';
            try{
                const dayTotals={};
                const monthStartSec=Math.floor(Date.now()/1000)-29*24*60*60;
                const shiftsArr=Array.isArray(shifts)?shifts:[];
                shiftsArr.forEach(shift=>{
                    if(!shift) return;
                    const sec=Number(shift.seconds)||0;
                    if(!sec) return;
                    let endTs=null;
                    if(typeof shift.stop==='number' && shift.stop>0){
                        endTs=shift.stop;
                    }else if(typeof shift.start==='number' && shift.start>0){
                        endTs=shift.start+sec;
                    }
                    if(!endTs || endTs<monthStartSec) return;
                    const d=new Date(endTs*1000);
                    const y=d.getFullYear();
                    const m=d.getMonth()+1;
                    const day=d.getDate();
                    const key=
                        String(y).padStart(4,'0')+'-'+
                        String(m).padStart(2,'0')+'-'+
                        String(day).padStart(2,'0');
                    dayTotals[key]=(dayTotals[key]||0)+sec;
                });
                const days=[];
                for(let i=29;i>=0;i--){
                    const t=(monthStartSec+i*24*60*60)*1000;
                    const d=new Date(t);
                    const y=d.getFullYear();
                    const m=d.getMonth()+1;
                    const day=d.getDate();
                    const key=
                        String(y).padStart(4,'0')+'-'+
                        String(m).padStart(2,'0')+'-'+
                        String(day).padStart(2,'0');
                    days.push(key);
                }
                let maxSec=0;
                let sumSec=0;
                days.forEach(k=>{
                    const v=dayTotals[k]||0;
                    if(v>maxSec) maxSec=v;
                    sumSec+=v;
                });
                if(maxSec>0){
                    const avgSec=sumSec/days.length;
                    const avgPct=avgSec>0?Math.max(4,Math.min(100,(avgSec/maxSec)*100)):0;
                    const avgHoursText=avgSec>0?formatHoursShort(avgSec):'0h';
                    let bars='';
                    days.forEach(k=>{
                        const v=dayTotals[k]||0;
                        const hoursText=formatHoursShort(v);
                        const labelDate=k.slice(5);
                        if(v<=0){
                            // Show a small baseline bar for zero-activity days so all 30 columns are visible
                            const hEmpty=4;
                            bars+=`<div class="self-offduty-30d-bar self-offduty-30d-bar-empty" style="height:${hEmpty}%;" title="${hoursText} on ${labelDate}"></div>`;
                        }else{
                            let h=(v/maxSec)*100;
                            if(h<8) h=8;
                            if(h>100) h=100;
                            bars+=`<div class="self-offduty-30d-bar" style="height:${h}%" title="${hoursText} on ${labelDate}"></div>`;
                        }
                    });
                    const avgLine=avgPct>0
                        ? `<div class="self-offduty-30d-avg-line" style="bottom:${avgPct}%">`+
                            `<span class="self-offduty-30d-avg-label">average<br><span class="self-offduty-30d-avg-value">${avgHoursText}</span></span>`+
                          `</div>`
                        : '';
                    const axesHtml=
                        `<div class="self-offduty-30d-axis-x">`+
                          `<span class="self-offduty-30d-axis-x-label">Days</span>`+
                        `</div>`+
                        `<div class="self-offduty-30d-axis-y">`+
                          `<span class="self-offduty-30d-axis-y-label">Hours</span>`+
                        `</div>`;
                    graphHtml=`<div class="self-offduty-30d-graph">${bars}${avgLine}${axesHtml}</div>`;
                }
            }catch(e){}

            last30Extra =
                `<div class="self-offduty-30d-inner">`+
                  captionHtml+
                  `<div class="${trackClass}">`+
                    `<div class="self-offduty-progress-fill" style="width:${barPct}%;"></div>`+
                  `</div>`+
                `</div>`;

            last30ChartHtml = graphHtml || '';
            last30AvgText = avgText;
        }

        const last30HeaderHtml =
            `<div class="self-offduty-30d-header-row">`+
              `<div class="self-offduty-30d-header-pill">`+
                `<div class="self-offduty-30d-header-label">LAST 30 DAYS</div>`+
                `<div class="self-offduty-30d-header-value">${last30Display}</div>`+
              `</div>`+
              ((last30AvgText && last30AvgText!=='') ? `<div class="self-offduty-30d-avg-pill">${last30AvgText}</div>` : '')+
            `</div>`;

        selfOffdutyDutyextra.classList.remove('hidden');
        selfOffdutyDutyextra.innerHTML=
            `<div class="self-offduty-subtitle">Duty focus</div>`+
            `<div class="self-offduty-pill-row self-offduty-pill-row-top">`+
              `<div class="self-offduty-pill self-offduty-pill-accent self-offduty-pill-top">`+
                `<div class="self-offduty-pill-label">Today</div>`+
                `<div class="self-offduty-pill-value">${todayHoursText}</div>`+
              `</div>`+
              `<div class="self-offduty-pill self-offduty-pill-top">`+
                `<div class="self-offduty-pill-label">Last 7 days</div>`+
                `<div class="self-offduty-pill-value">${weekHoursText}</div>`+
              `</div>`+
            `</div>`+
            `<div class="self-offduty-pill-row self-offduty-pill-row-bottom">`+
              `<div class="self-offduty-pill self-offduty-pill-30d">`+
                last30HeaderHtml+
                (last30Extra||'')+ // Changed from <br> to <div>
              `</div>`+
            `</div>`;

        if(selfDutyGraph){
            if(last30ChartHtml){
                selfDutyGraph.classList.remove('hidden');
                selfDutyGraph.innerHTML=last30ChartHtml;
            }else{
                selfDutyGraph.classList.add('hidden');
                selfDutyGraph.innerHTML='';
            }
        }

    }

    if(selfOffdutyMoneystats){
        const dayTotals={};
        shifts.forEach(shift=>{
            if(!shift) return;
            const sec=Number(shift.seconds)||0;
            if(!sec) return;
            let endTs=null;
            if(typeof shift.stop==='number' && shift.stop>0){
                endTs=shift.stop;
            }else if(typeof shift.start==='number' && shift.start>0){
                endTs=shift.start+sec;
            }
            if(!endTs) return;
            const d=new Date(endTs*1000);
            const y=d.getFullYear();
            const m=d.getMonth()+1;
            const day=d.getDate();
            const key=
                String(y).padStart(4,'0')+'-'+
                String(m).padStart(2,'0')+'-'+
                String(day).padStart(2,'0');
            dayTotals[key]=(dayTotals[key]||0)+sec;
        });
        const dayKeys=Object.keys(dayTotals);
        let streakDays=0;
        if(dayKeys.length){
            dayKeys.sort();
            const lastKey=dayKeys[dayKeys.length-1];
            const parts=lastKey.split('-').map(v=>parseInt(v,10)||0);
            let y=parts[0];
            let m=parts[1];
            let d=parts[2];
            if(y && m && d){
                for(;;){
                    const key=
                        String(y).padStart(4,'0')+'-'+
                        String(m).padStart(2,'0')+'-'+
                        String(d).padStart(2,'0');
                    const secDay=dayTotals[key]||0;
                    if(secDay>=DUTY_STREAK_THRESHOLD_SEC){
                        streakDays++;
                        const dt=new Date(y,m-1,d);
                        dt.setDate(dt.getDate()-1);
                        y=dt.getFullYear();
                        m=dt.getMonth()+1;
                        d=dt.getDate();
                    }else{
                        break;
                    }
                }
            }
        }
        if(streakDays>0){
            const thresholdHours=DUTY_STREAK_THRESHOLD_SEC/3600;
            selfOffdutyMoneystats.classList.remove('hidden');
            selfOffdutyMoneystats.innerHTML=
                `<div class="self-offduty-metric-pill">`+
                  `<div class="self-offduty-metric-label">Duty streak</div>`+
                  `<div class="self-offduty-metric-value">${streakDays} day${streakDays!==1?'s':''}</div>`+
                  `<div class="self-offduty-metric-caption">\u2265 ${thresholdHours}h per day</div>`+
                `</div>`;
        }else{
            selfOffdutyMoneystats.classList.add('hidden');
            selfOffdutyMoneystats.innerHTML='';
        }
    }

    const a=stats.actions||{};

    if(selfOffdutyModstats){
        const breakdown=[];
        const pushRow=(label,totalKey,weekKey)=>{
            const total=Number(a[totalKey])||0;
            const week=Number(a[weekKey])||0;
            breakdown.push({label,total,week});
        };
        pushRow('Kicks','kicks','weekKicks');
        pushRow('Bans','bans','weekBans');
        pushRow('Prison bans','prisonBans','weekPrisonBans');
        pushRow('Warns','warns','weekWarns');
        pushRow('Messages','messages','weekMessages');
        pushRow('Inv clears','clearInv','weekClearInv');
        pushRow('Kills','kills','weekKills');
        pushRow('Job changes','setJobs','weekSetJobs');

        if(a.total || breakdown.length){
            let html='';
            const iconMap={
                'Kicks':'fa-solid fa-hand-fist',
                'Bans':'fa-solid fa-ban',
                'Prison bans':'fa-solid fa-gavel',
                'Warns':'fa-solid fa-triangle-exclamation',
                'Messages':'fa-solid fa-envelope',
                'Inv clears':'fa-solid fa-broom',
                'Kills':'fa-solid fa-skull',
                'Job changes':'fa-solid fa-briefcase'
            };
            const maxVal=breakdown.reduce((m,entry)=>{
                if(entry.total>m) m=entry.total;
                if(entry.week>m) m=entry.week;
                return m;
            },0)||1;
            let bars='';
            breakdown.forEach(entry=>{
                let totalPct=(entry.total/maxVal)*100;
                let weekPct=(entry.week/maxVal)*100;
                if(totalPct<6 && entry.total>0) totalPct=6;
                if(weekPct<6 && entry.week>0) weekPct=6;
                if(totalPct>100) totalPct=100;
                if(weekPct>100) weekPct=100;
                const iconClass=iconMap[entry.label]||'fa-solid fa-chart-bar';
                bars+=
                    `<div class="self-offduty-bar-row">`+
                      `<div class="self-offduty-bar-label">`+
                        `<span class="self-offduty-bar-icon"><i class="${iconClass}"></i></span>`+
                        `<span class="self-offduty-bar-label-text">${entry.label}</span>`+
                      `</div>`+
                      `<div class="self-offduty-bar-track self-offduty-bar-track-dual">`+
                        (entry.total?`<div class="self-offduty-bar-fill self-offduty-bar-fill-total" style="width:${totalPct}%;"></div>`:'')+
                        (entry.week?`<div class="self-offduty-bar-fill self-offduty-bar-fill-week" style="width:${weekPct}%;"></div>`:'')+
                      `</div>`+
                      `<div class="self-offduty-bar-value">`+
                        `<span class="self-offduty-bar-num self-offduty-bar-num-week">${entry.week||0}</span>`+
                        `<span class="self-offduty-bar-num-sep">/</span>`+
                        `<span class="self-offduty-bar-num self-offduty-bar-num-total">${entry.total||0}</span>`+
                      `</div>`+
                    `</div>`;
            });
            html+=
                `<div class="self-offduty-stack self-offduty-stack-mod">`+
                  `<div class="self-offduty-stack-header">`+
                    `<span class="self-offduty-stack-title">Moderation footprint</span>`+
                    (a.total?`<span class="self-offduty-stack-kpi">${a.total} actions</span>`:'')+ // Changed from <br> to <span>
                  `</div>`+
                  (bars?`<div class="self-offduty-bar-grid">${bars}</div>`:'')+ // Changed from <br> to <div>
                `</div>`;
            selfOffdutyModstats.classList.remove('hidden');
            selfOffdutyModstats.innerHTML=html;
        }else{
            selfOffdutyModstats.classList.add('hidden');
            selfOffdutyModstats.innerHTML='';
        }
    }

    // Troll stats
    const trollLabelFromKey=(key)=>{
        if(!key) return '';
        if(key==='troll_slap') return 'Slap';
        if(key==='troll_launch') return 'Launch';
        if(key==='troll_screen') return 'Screen FX';
        if(key==='troll_fire') return 'Fire';
        if(key==='troll_ufo') return 'UFO Kidnap';
        if(key==='troll_npc_kidnap') return 'NPC Kidnap';
        if(key==='troll_animal') return 'Animal Attack';
        if(key==='troll_npcs') return 'NPC Attack';
        if(key==='troll_clone') return 'Clone Follow';
        if(key==='troll_flipveh') return 'Flip Vehicle';
        if(key==='troll_slowwalk') return 'Slow Walk';
        if(key==='troll_cam2d') return '2D Camera';
        if(key==='troll_camflip') return 'Flip Camera';
        if(key==='troll_mobhit') return 'Mob Hit';
        if(key.startsWith('troll_')){
            let s=key.replace(/^troll_/,'').replace(/_/g,' ');
            return s.charAt(0).toUpperCase()+s.slice(1);
        }
        return key;
    };

    if(selfOffdutyTrollstats){
        const total=a.trollTotal||0;
        const byType=a.trollByType||{};
        const entries=Object.entries(byType).sort(([,c1],[,c2])=>c2-c1).slice(0,5);

        if(total>0){
            let html=
                `<div class="self-offduty-metric-pill self-offduty-metric-pill-troll">`+
                  `<div class="self-offduty-metric-label">Troll actions</div>`+
                  `<div class="self-offduty-metric-value">${total}</div>`+
                `</div>`;
            if(entries.length){
                html+=`<div class="self-offduty-subtitle self-offduty-subtitle-trolltypes">Top types</div>`+
                       `<div class="self-offduty-tag-cloud">`+
                        entries.map(([k,v])=>{
                            const label=trollLabelFromKey(k);
                            return (
                                `<span class=\"self-offduty-tag\">`+
                                  `<span class=\"self-offduty-tag-label\">${label}</span>`+
                                  `<span class=\"self-offduty-tag-count\">${v}</span>`+
                                `</span>`
                            );
                        }).join('')+
                        `</div>`;
            }
            selfOffdutyTrollstats.classList.remove('hidden');
            selfOffdutyTrollstats.innerHTML=html;
        }else{
            selfOffdutyTrollstats.classList.add('hidden');
            selfOffdutyTrollstats.innerHTML='';
        }
    }

    // Player control stats (bring/goto/freeze/etc.)
    const controlStatsEl=document.getElementById('self-offduty-controlstats');
    const controlIconFromKey=(rawKey)=>{
        if(!rawKey) return 'fa-circle';
        const key=String(rawKey).toLowerCase().replace(/^player_/,'');
        if(key==='freeze') return 'fa-snowflake';
        if(key==='unfreeze') return 'fa-sun';
        if(key==='noclip') return 'fa-shoe-prints';
        if(key==='invincible') return 'fa-shield-halved';
        if(key==='invisible') return 'fa-user-ninja';
        if(key==='spectate') return 'fa-eye';
        if(key==='spectatestop') return 'fa-eye-slash';
        if(key==='bring') return 'fa-arrow-down';
        if(key==='goto') return 'fa-location-arrow';
        if(key==='tpto') return 'fa-location-crosshairs';
        return 'fa-circle';
    };

    if(controlStatsEl){
        const totalControl=a.controlTotal||0;
        const byType=a.controlByType||{};
        const entries=Object.entries(byType).sort(([,c1],[,c2])=>c2-c1);
        const topEntries=entries.slice(0,6);
        if(totalControl>0 && topEntries.length){
            let html='';
            const maxVal=topEntries.reduce((m,[,count])=>count>m?count:m,0)||1;
            let bars='';
            topEntries.forEach(([label,count])=>{
                let pct=(count/maxVal)*100;
                if(pct<6 && count>0) pct=6;
                if(pct>100) pct=100;
                const prettyBase=label.replace(/^player_/,'').replace(/_/g,' ');
                const prettyLabel=prettyBase.charAt(0).toUpperCase()+prettyBase.slice(1);
                const iconClass=controlIconFromKey(label);
                bars+=
                    `<div class="self-offduty-bar-row">`+
                      `<div class="self-offduty-bar-label">`+
                        `<span class="self-offduty-bar-icon"><i class="fa-solid ${iconClass}"></i></span>`+
                        `<span>${prettyLabel}</span>`+
                      `</div>`+
                      `<div class="self-offduty-bar-track">`+
                        `<div class="self-offduty-bar-fill" style="width:${pct}%;"></div>`+
                      `</div>`+
                      `<div class="self-offduty-bar-value">${count}</div>`+
                    `</div>`;
            });
            html+=
                `<div class="self-offduty-stack self-offduty-stack-control">`+
                  `<div class="self-offduty-stack-header">`+
                    `<span class="self-offduty-stack-title">Player control usage</span>`+
                    `<span class="self-offduty-stack-kpi">${totalControl} actions</span>`+
                  `</div>`+
                  `<div class="self-offduty-bar-grid">${bars}</div>`+
                `</div>`;
            controlStatsEl.classList.remove('hidden');
            controlStatsEl.innerHTML=html;
        }else{
            controlStatsEl.classList.add('hidden');
            controlStatsEl.innerHTML='';
        }
    }

    // Vehicle stats
    if(selfOffdutyVehstats){
        const total=a.vehiclesTotal||0;
        const byModel=a.vehiclesByModel||{};
        const entries=Object.entries(byModel).sort(([,c1],[,c2])=>c2-c1);
        const topEntries=entries.slice(0,3);
        if(total>0){
            let html=
                `<div class="self-offduty-metric-pill">`+
                  `<div class="self-offduty-metric-label">Vehicles spawned</div>`+
                  `<div class="self-offduty-metric-value">${total}</div>`+
                  (topEntries.length?`<div class="self-offduty-metric-caption">Top models</div>`:'')+ // Changed from <br> to <div>
                `</div>`;
            if(topEntries.length){
                html+=`<div class="self-offduty-tag-cloud">`+
                        topEntries.map(([k,v])=>
                            `<span class=\"self-offduty-tag\">`+
                              `<span class=\"self-offduty-tag-label\">${k}</span>`+
                              `<span class=\"self-offduty-tag-count\">${v}</span>`+
                            `</span>`
                        ).join('')+
                        `</div>`;
            }
            selfOffdutyVehstats.classList.remove('hidden');
            selfOffdutyVehstats.innerHTML=html;
        }else{
            selfOffdutyVehstats.classList.add('hidden');
            selfOffdutyVehstats.innerHTML='';
        }
    }

    // Prison-ban focused stats + top reasons
    if(selfOffdutyBanstats){
        const prisonCount=Number(a.prisonBans)||0;
        const weekPrisonCount=Number(a.weekPrisonBans)||0;
        const prisonMinutes=Number(a.prisonBanMinutesTotal)||0;
        const weekPrisonMinutes=Number(a.weekPrisonBanMinutes)||0;
        const avgMinutes=prisonCount>0?(prisonMinutes/prisonCount):0;

        const reasons=a.banReasons||{};
        const reasonEntries=Object.entries(reasons).sort(([,c1],[,c2])=>c2-c1).slice(0,6);

        if(prisonCount>0 || reasonEntries.length){
            let html=
                `<div class="self-offduty-stack self-offduty-stack-prison">`+
                  `<div class="self-offduty-stack-header">`+
                    `<span class="self-offduty-stack-title">Prison enforcement</span>`+
                    `<span class="self-offduty-stack-kpi">${prisonCount} prison ban${prisonCount===1?'':'s'}</span>`+
                  `</div>`+
                  `<div class="self-offduty-pill-row">`+
                    `<div class="self-offduty-pill self-offduty-pill-accent">`+
                      `<div class="self-offduty-pill-label">Lifetime</div>`+
                      `<div class="self-offduty-pill-value">${prisonCount} ban${prisonCount===1?'':'s'} • ${Math.round(prisonMinutes)||0} min</div>`+
                      `<div class="self-offduty-metric-caption">Avg ${avgMinutes.toFixed(1)} min per ban</div>`+
                    `</div>`+
                    `<div class="self-offduty-pill">`+
                      `<div class="self-offduty-pill-label">Last 7 days</div>`+
                      `<div class="self-offduty-pill-value">${weekPrisonCount} ban${weekPrisonCount===1?'':'s'} • ${Math.round(weekPrisonMinutes)||0} min</div>`+
                    `</div>`+
                  `</div>`;

            if(reasonEntries.length){
                html+=`<div class="self-offduty-subtitle self-offduty-subtitle-topbans">Top ban reasons</div>`+
                       `<div class="self-offduty-tag-cloud">`+
                       reasonEntries.map(([reason,count])=>
                           `<span class=\"self-offduty-tag\">`+
                             `<span class=\"self-offduty-tag-label\">${reason}</span>`+
                             `<span class=\"self-offduty-tag-count\">${count}</span>`+
                           `</span>`
                       ).join('')+
                       `</div>`;
            }

            selfOffdutyBanstats.classList.remove('hidden');
            selfOffdutyBanstats.innerHTML=html;
        }else{
            selfOffdutyBanstats.classList.add('hidden');
            selfOffdutyBanstats.innerHTML='';
        }
    }
}

function setMiniMode(mode){
    if(!miniBodyMod||!miniBodyDev||!miniModeMod||!miniModeDev) return;
    const target = (mode==='dev' && miniBodyDev) ? 'dev' : (mode==='key' && miniBodyKey) ? 'key' : 'mod';
    [miniBodyMod,miniBodyKey,miniBodyDev].forEach(body=>{
        if(body){
            body.classList.add('hidden');
        }
    });
    [miniModeMod,miniModeKey,miniModeDev].forEach(btn=>{
        if(btn){
            btn.classList.remove('active');
        }
    });
    if(target==='dev'){
        miniBodyDev.classList.remove('hidden');
        miniModeDev && miniModeDev.classList.add('active');
    }else if(target==='key'){
        miniBodyKey && miniBodyKey.classList.remove('hidden');
        miniModeKey && miniModeKey.classList.add('active');
    }else{
        miniBodyMod.classList.remove('hidden');
        miniModeMod && miniModeMod.classList.add('active');
    }
    cancelMiniKeyCapture();
    miniNavIndex=-1;
    document.querySelectorAll('#mini-panel .mini-focus').forEach(el=>el.classList.remove('mini-focus'));
}

document.getElementById('close').onclick=()=>{cb('close',{});};
function getMiniNavItems(){
    const selector='#mini-panel .mini-body:not(.hidden) #mini-player-id,#mini-panel .mini-body:not(.hidden) [data-mini-self],#mini-panel .mini-body:not(.hidden) [data-mini-player],#mini-panel .mini-body:not(.hidden) [data-mini-dev],#mini-panel .mini-body:not(.hidden) .mini-bind-edit';
    return [...document.querySelectorAll(selector)];
}

document.addEventListener('keydown',e=>{
    if(miniKeybindCapture){
        e.preventDefault();
        if(e.key==='Escape' || e.keyCode===27){
            cancelMiniKeyCapture();
            return;
        }
        const combo=normalizeMiniKeyEvent(e);
        if(combo){
            assignMiniKeybind(miniKeybindCapture.action,combo);
            cancelMiniKeyCapture();
        }
        return;
    }

    const tag=(e.target && e.target.tagName ? e.target.tagName.toUpperCase() : '');
    const comboCandidate = normalizeMiniKeyEvent(e);
    if(comboCandidate && !MINI_KEY_PROTECTED_TAGS.has(tag)){
        const actionKey=findMiniKeybindActionByCombo(comboCandidate);
        if(actionKey){
            e.preventDefault();
            triggerMiniKeyAction(actionKey);
            return;
        }
    }

    const miniVisible = miniPanel && !miniPanel.classList.contains('hidden');

    if(miniVisible && (e.key==='ArrowLeft'||e.key==='ArrowRight'||e.key==='ArrowUp'||e.key==='ArrowDown')){
        const items=getMiniNavItems();
        if(!items.length)return;
        e.preventDefault();
        const len=items.length;
        if(miniNavIndex<0) miniNavIndex=0;
        else if(e.key==='ArrowLeft'||e.key==='ArrowUp') miniNavIndex=(miniNavIndex-1+len)%len;
        else miniNavIndex=(miniNavIndex+1)%len;
        items.forEach(el=>el.classList.remove('mini-focus'));
        const el=items[miniNavIndex];
        if(el){
            el.classList.add('mini-focus');
            if(el.focus) el.focus();
        }
        return;
    }

    if(miniVisible && (e.key==='Enter'||e.keyCode===13)){
        const items=getMiniNavItems();
        if(items.length && miniNavIndex>=0 && miniNavIndex<items.length){
            e.preventDefault();
            items[miniNavIndex].click();
        }
        return;
    }

    if(e.key==='Escape'||e.keyCode===27){
        if(miniVisible){
            cb('miniClose',{});
        }else{
            cb('close',{});
        }
    }
});

tabs.forEach(b=>b.onclick=()=>{
    tabs.forEach(x=>x.classList.remove('active'));
    views.forEach(v=>v.classList.remove('active'));
    b.classList.add('active');
    const tab=b.dataset.tab;
    document.querySelector(`[data-tab-content="${tab}"]`).classList.add('active');
    if(tab==='players')refreshPlayers();
    if(tab==='zones')cb('zonesReq',{}); 
    if(tab==='bans'){
        cb('bansReq',{});
        cb('prisonBansReq',{}); 
    }
    if(tab==='roles' || tab==='staff')cb('rolesReq',{}); 
    if(tab==='console'){
        if(consoleMonitorBtn){
            sendExploitMonitorState(exploitMonitorWanted);
        }
    }
    if(tab==='monitor'){
        if(hasPermUi('Console')) ensureMonitorPolling();
    }else{
        stopMonitorPolling();
    }
    if(tab==='statistics'){
        ensureStatisticsRequested();
    }
});

// VEHICLES internal subtabs (Tools vs Admin Vehicles)
const vehSubtabButtons=[...document.querySelectorAll('.veh-subtab')];
if(vehSubtabButtons.length){
    const vehSubcontents=[...document.querySelectorAll('.veh-subcontent')];
    vehSubtabButtons.forEach(btn=>{
        btn.addEventListener('click',()=>{
            const target=btn.dataset.vehSubtab;
            vehSubtabButtons.forEach(b=>b.classList.remove('active'));
            vehSubcontents.forEach(sc=>sc.classList.remove('active'));
            btn.classList.add('active');
            const content=document.querySelector(`.veh-subcontent[data-veh-subcontent="${target}"]`);
            if(content) content.classList.add('active');
        });
    });
}

// SELF
document.querySelectorAll('[data-self]').forEach(b=>{
    b.onclick=()=>{
        const a=b.dataset.self;
        cb('self',{a:a});
        if(a==='skin'){
            cb('close',{});
        }
        if(a==='ammo'){
            const on=!b.classList.contains('state-on');
            b.classList.toggle('state-on',on);
        }
    };
});
if(selfLiveMapBtn){
    selfLiveMapBtn.onclick=()=>{
        const on=!selfLiveMapBtn.classList.contains('state-on');
        selfLiveMapBtn.classList.toggle('state-on',on);
        cb('liveMapToggle',{});
    };
}
const selfPedBtn=document.getElementById('self-ped-btn');
if(selfPedBtn){
    selfPedBtn.onclick=()=>{
        cb('self',{a:'ped',model:document.getElementById('self-ped').value||'mp_m_freemode_01'});
    };
}
const selfPedClearBtn=document.getElementById('self-ped-clear-btn');
if(selfPedClearBtn){
    selfPedClearBtn.onclick=()=>{
        cb('self',{a:'pedClear'});
    };
}
const staffNameInput=document.getElementById('staff-name');
const staffNameBtn=document.getElementById('staff-name-btn');
if(staffNameBtn&&staffNameInput){
    staffNameBtn.onclick=()=>{
        cb('self',{a:'name',name:staffNameInput.value||''});
    };
}

if(selfJobBtn&&selfJobNameInput&&selfJobGradeSelect){
    selfJobBtn.onclick=()=>{
        if(selfJobBtn.disabled) return;
        const job=(selfJobNameInput.value||'').trim();
        if(!job) return;
        let grade=parseInt(selfJobGradeSelect.value||'0',10);
        if(isNaN(grade)||grade<0) grade=0;
        if(grade>6) grade=6;
        cb('self',{a:'job',job:job,grade:grade});
    };
}

if(selfMoneyBtn && selfMoneyAccountSelect && selfMoneyAmountInput){
    selfMoneyBtn.onclick=()=>{
        if(selfMoneyBtn.disabled) return;
        const account=selfMoneyAccountSelect.value||'money';
        const amount=parseInt(selfMoneyAmountInput.value||'0',10);
        if(!amount || amount<=0) return;
        cb('self',{a:'money',account:account,amount:amount});
    };
}

const rpFirstInput=document.getElementById('rp-first-name');
const rpLastInput=document.getElementById('rp-last-name');
const rpNameBtn=document.getElementById('rp-name-btn');
const rpNameResetBtn=document.getElementById('rp-name-reset-btn');
if(rpNameBtn&&rpFirstInput&&rpLastInput){
    rpNameBtn.onclick=()=>{
        cb('self',{a:'rpName',first:rpFirstInput.value||'',last:rpLastInput.value||''});
    };
}
if(rpNameResetBtn&&rpFirstInput&&rpLastInput){
    rpNameResetBtn.onclick=()=>{
        rpFirstInput.value='';
        rpLastInput.value='';
        cb('self',{a:'rpName',first:'',last:''});
    };
}

if(noclipSpeedSlider){
    const updateNoclipSpeedUI=(v)=>{
        let val=parseFloat(v);
        if(!isFinite(val)) val=1;
        if(val<0.01) val=0.01;
        if(val>5) val=5;
        val=Math.round(val*100)/100;
        if(noclipSpeedSlider){
            noclipSpeedSlider.value=String(val);
        }
        if(noclipSpeedValue){
            noclipSpeedValue.textContent=val+'x';
        }
        return val;
    };
    // Initial sync when UI opens
    let currentNoclipSpeed=updateNoclipSpeedUI(noclipSpeedSlider.value||'3');
    cb('self',{a:'noclipSpeed',speed:currentNoclipSpeed});
    // Live UI feedback while dragging
    noclipSpeedSlider.addEventListener('input',e=>{
        currentNoclipSpeed=updateNoclipSpeedUI(e.target.value||'3');
    });
    // Send to backend when user releases the slider
    noclipSpeedSlider.addEventListener('change',e=>{
        const val=updateNoclipSpeedUI(e.target.value||'3');
        cb('self',{a:'noclipSpeed',speed:val});
    });
}

if(selfOnePunchBtn){
    selfOnePunchBtn.onclick=()=>{
        const on=!selfOnePunchBtn.classList.contains('state-on');
        selfOnePunchBtn.classList.toggle('state-on',on);
        if(miniOnePunchBtn) miniOnePunchBtn.classList.toggle('state-on',on);
        cb('dev',{a:'onepunch',on:on});
    };
}
if(miniOnePunchBtn){
    miniOnePunchBtn.onclick=()=>{
        const on=!miniOnePunchBtn.classList.contains('state-on');
        miniOnePunchBtn.classList.toggle('state-on',on);
        if(selfOnePunchBtn) selfOnePunchBtn.classList.toggle('state-on',on);
        cb('dev',{a:'onepunch',on:on});
    };
}

if(miniClose&&miniPanel){
    miniClose.onclick=()=>{
        cb('miniClose',{});
        miniPanel.classList.add('hidden');
        cancelMiniKeyCapture();
    };
}
if(miniModeMod){
    miniModeMod.onclick=()=>setMiniMode('mod');
}
if(miniModeKey){
    miniModeKey.onclick=()=>setMiniMode('key');
}
if(miniModeDev){
    miniModeDev.onclick=()=>setMiniMode('dev');
}
if(miniBindRows.length){
    miniBindRows.forEach(row=>{
        const action=row.dataset.bindAction;
        const btn=row.querySelector('.mini-bind-edit');
        if(action && btn){
            btn.addEventListener('click',()=>beginMiniKeyCapture(action,btn));
        }
    });
}
if(miniBindClearBtn){
    miniBindClearBtn.addEventListener('click',()=>{
        miniKeybinds={};
        saveMiniKeybinds();
        updateAllMiniBindLabels();
        cancelMiniKeyCapture();
    });
}
document.querySelectorAll('[data-mini-self]').forEach(b=>{
    b.onclick=()=>{
        const a=b.dataset.miniSelf;
        cb('self',{a:a});
        if(a==='ammo' || a==='runfast2x'){
            const on=!b.classList.contains('state-on');
            b.classList.toggle('state-on',on);
        }
    };
});
document.querySelectorAll('[data-mini-player]').forEach(b=>{
    b.onclick=()=>{
        if(!miniPlayerInput)return;
        const id=parseInt(miniPlayerInput.value||'0',10);
        if(!id)return;
        let a=b.dataset.miniPlayer;
        if(a==='spectate' && spectating){ a='spectateStop'; }
        cb('player',{a:a,id:id});
    };
});
document.querySelectorAll('[data-mini-dev]').forEach(b=>{
    b.onclick=()=>{
        const a=b.dataset.miniDev;
        if(a==='lightning' || a==='godshand'){
            const on=!b.classList.contains('state-on');
            b.classList.toggle('state-on',on);
            cb('dev',{a:a,on:on});
        }else{
            cb('dev',{a:a});
        }
    };
});

// PLAYERS
const playersDiv=document.getElementById('players');
const selSpan=document.getElementById('sel-player');
const vehOwnedPlayerLabel=document.getElementById('veh-owned-player');
const playerBansDiv=document.getElementById('player-bans');
const playerNamesDiv=document.getElementById('player-names');
const playerActionsDiv=document.getElementById('player-actions');
const prisonConfirm=document.getElementById('prison-confirm');
const prisonConfirmText=document.getElementById('prison-confirm-text');
const prisonConfirmYes=document.getElementById('prison-confirm-yes');
const prisonConfirmNo=document.getElementById('prison-confirm-no');
const pardonConfirm=document.getElementById('pardon-confirm');
const pardonConfirmText=document.getElementById('pardon-confirm-text');
const pardonConfirmYes=document.getElementById('pardon-confirm-yes');
const pardonConfirmNo=document.getElementById('pardon-confirm-no');
const clearInvConfirm=document.getElementById('clearinv-confirm');
const clearInvConfirmYes=document.getElementById('clearinv-confirm-yes');
const clearInvConfirmNo=document.getElementById('clearinv-confirm-no');
const openInvConfirm=document.getElementById('openinv-confirm');
const openInvConfirmText=document.getElementById('openinv-confirm-text');
const openInvConfirmButtons=document.getElementById('openinv-confirm-buttons');
const openInvConfirmYes=document.getElementById('openinv-confirm-yes');
const openInvConfirmNo=document.getElementById('openinv-confirm-no');
const plateChangeModal=document.getElementById('plate-change-modal');
const plateChangeInput=document.getElementById('plate-change-input');
const plateChangeConfirm=document.getElementById('plate-change-confirm');
const plateChangeCancel=document.getElementById('plate-change-cancel');
const vehAdminList=document.getElementById('veh-admin-list');
const vehOwnedListDiv=document.getElementById('veh-owned-list');
let selId=null;
let selFxName='',selRpName='';
let pendingPrison=null;
let pendingPardon=null;
let pendingClearInv=null;
let pendingPlate=null;
let pendingOpenInv=null;
let adminVehicles=[];
let adminVehicleCategories={};
let selectedAdminVehicleModel=null;
let adminVehicleFavorites=new Set(); // models (lowercase) favorited by this staff member
let vehOwnedData=[];

function renderSelHeader(){
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

function renderOwnedVehicles(){
    if(!vehOwnedListDiv) return;
    vehOwnedListDiv.innerHTML='';

    if(!Array.isArray(vehOwnedData) || !vehOwnedData.length){
        const empty=document.createElement('div');
        empty.className='list-row';
        empty.innerHTML='<span class="muted">No vehicles found for this player.</span>';
        vehOwnedListDiv.appendChild(empty);
        return;
    }

    vehOwnedData.forEach(v=>{
        if(!v) return;
        const row=document.createElement('div');
        row.className='list-row veh-owned-row';

        const name=v.name||v.model||v.plate||'';
        const model=v.model||'';
        const category=v.category||'';
        const plate=v.plate||'';
        const garage=(v.garage||'')+'';
        const state=(v.state||'')+'';
        let garageState='';
        if(garage && state){
            garageState=`${garage} / ${state}`;
        }else{
            garageState=state||garage||'';
        }

        row.innerHTML=
            `<span class="veh-owned-name">${name}</span>`+
            `<span class="veh-owned-model">${model}</span>`+
            `<span class="veh-owned-category">${category}</span>`+
            `<span class="veh-owned-plate">${plate}</span>`+
            `<span>${garageState}</span>`+
            `<span></span>`;

        const plateSpan=row.querySelector('.veh-owned-plate');
        if(plateSpan && plate){
            plateSpan.onclick=()=>{
                showPlateChangeModal(plate);
            };
        }

        vehOwnedListDiv.appendChild(row);
    });
}

function refreshPlayers(){cb('playersReq',{});} 
document.getElementById('players-refresh').onclick=refreshPlayers;

const vehOwnedLoadBtn=document.getElementById('veh-owned-load');
if(vehOwnedLoadBtn){
    vehOwnedLoadBtn.onclick=()=>{
        if(!selId) return;
        cb('ownedVehiclesReq',{id:selId});
    };
}

function setSel(id,name,el){
    selId=id;
    selFxName=name||'';
    selRpName='';
    renderSelHeader();
    renderVehOwnedHeader();
    document.querySelectorAll('.player-row').forEach(r=>r.classList.remove('active'));
    if(el)el.classList.add('active');
    document.querySelectorAll('[data-player]').forEach(btn=>btn.classList.remove('state-on'));
    // Request ban / prison-ban history for this player
    if(id){
        cb('playerBansReq',{id:id});
        cb('playerNamesReq',{id:id});
        cb('playerActionsReq',{id:id});
        if(playersMoneyStats){
            if(anyPerm(['Player','PlayerMoney','PlayerMoneyView'])){
                playersMoneyStats.innerHTML='<span class="muted">Loading balances...</span>';
                cb('playerMoneyReq',{id:id});
            }else{
                playersMoneyStats.innerHTML='<span class="muted">No permission to view balances.</span>';
            }
        }
    }else{
        if(playersMoneyStats){
            playersMoneyStats.innerHTML='<span class="muted">Select a player to view balances.</span>';
        }
    }
}

// Toggle prison-ban offences without needing Ctrl (click to select/unselect)
document.querySelectorAll('.offence-pill').forEach(btn=>{
    btn.addEventListener('click',()=>{
        btn.classList.toggle('selected');
    });
});

function formatMinutesText(mins){
    if(mins===60) return '1 hour';
    if(mins>60 && mins%60===0){
        const h=mins/60;
        return h===1?'1 hour':`${h} hours`;
    }
    return `${mins} minutes`;
}

function showPrisonConfirm(info){
    if(!prisonConfirm||!prisonConfirmText||!pendingPrison)return;
    const data=info||{};
    const labels=Array.isArray(data.labels)?data.labels:[];
    const minutes=typeof data.minutes==='number'?data.minutes:0;
    const prev=typeof data.prev==='number'?data.prev:0;
    const offencesText=labels.length?labels.join(', '):'Generic rule violation';
    const timeText=formatMinutesText(minutes>0?minutes:60);
    const prevText=prev>0?`Previous prison bans: ${prev}`:'No previous prison bans.';
    prisonConfirmText.innerHTML=
        `<span class="label">Offences:</span> <span class="value">${offencesText}</span><br>`+
        `<span class="label">Sentence:</span> <span class="value">${timeText}</span><br>`+
        `<span class="label">${prevText}</span>`;
    prisonConfirm.classList.remove('hidden');
}

if(prisonConfirmYes&&prisonConfirmNo){
    prisonConfirmYes.onclick=()=>{
        if(!pendingPrison) return;
        cb('player',{
            a:'prisonBan',
            id:pendingPrison.id,
            offences:pendingPrison.offences||[],
            notes:pendingPrison.notes||''
        });
        pendingPrison=null;
        prisonConfirm.classList.add('hidden');
    };
    prisonConfirmNo.onclick=()=>{
        pendingPrison=null;
        prisonConfirm.classList.add('hidden');
    };
}

function showPardonConfirm(info){
    if(!pardonConfirm||!pardonConfirmText||!pendingPardon)return;
    const data=info||{};
    const id=data.id||'';
    const name=data.name||'Unknown';
    const reason=data.reason||'';
    const typeLabel=data.type==='prison'?'Prison ban':'Ban';
    let createdText='';
    if(typeof data.created==='number' && data.created>0){
        createdText=new Date(data.created*1000).toLocaleString();
    }
    let html=`<span class="label">Player:</span> <span class="value">${name}${id?` (${id})`:''}</span><br>`+
             `<span class="label">Type:</span> <span class="value">${typeLabel}</span>`;
    if(reason){
        html+=`<br><span class="label">Reason:</span> <span class="value">${reason}</span>`;
    }
    if(createdText){
        html+=`<br><span class="label">Created:</span> <span class="value">${createdText}</span>`;
    }
    pardonConfirmText.innerHTML=html;
    pardonConfirm.classList.remove('hidden');
}

if(pardonConfirmYes&&pardonConfirmNo){
    pardonConfirmYes.onclick=()=>{
        if(!pendingPardon)return;
        cb('pardonBan',{
            id:pendingPardon.id,
            type:pendingPardon.type,
            created:pendingPardon.created
        });
        pendingPardon=null;
        pardonConfirm.classList.add('hidden');
    };
    pardonConfirmNo.onclick=()=>{
        pendingPardon=null;
        pardonConfirm.classList.add('hidden');
    };
}

if(clearInvConfirm&&clearInvConfirmYes&&clearInvConfirmNo){
    clearInvConfirmYes.onclick=()=>{
        if(pendingClearInv){
            cb('player',{a:'clearinv',id:pendingClearInv.id});
        }
        pendingClearInv=null;
        clearInvConfirm.classList.add('hidden');
    };
    clearInvConfirmNo.onclick=()=>{
        pendingClearInv=null;
        clearInvConfirm.classList.add('hidden');
    };
}

if(openInvConfirm && openInvConfirmYes && openInvConfirmNo){
    openInvConfirmYes.onclick=()=>{
        if(pendingOpenInv){
            cb('player',{a:'confiscateillegal',id:pendingOpenInv.id});
        }
        pendingOpenInv=null;
        openInvConfirm.classList.add('hidden');
        if(openInvConfirmYes) openInvConfirmYes.style.display='';
        if(openInvConfirmNo) openInvConfirmNo.textContent='No';
    };
    openInvConfirmNo.onclick=()=>{
        pendingOpenInv=null;
        openInvConfirm.classList.add('hidden');
        if(openInvConfirmYes) openInvConfirmYes.style.display='';
        if(openInvConfirmNo) openInvConfirmNo.textContent='No';
    };
}

function showPlateChangeModal(currentPlate){
    if(!plateChangeModal||!plateChangeInput)return;
    pendingPlate=currentPlate||'';
    plateChangeInput.value=pendingPlate;
    plateChangeModal.classList.remove('hidden');
    plateChangeInput.focus();
}

if(plateChangeConfirm&&plateChangeCancel){
    plateChangeConfirm.onclick=()=>{
        if(!pendingPlate){
            plateChangeModal.classList.add('hidden');
            return;
        }
        const np=(plateChangeInput.value||'').trim();
        if(!np){
            plateChangeModal.classList.add('hidden');
            pendingPlate=null;
            return;
        }
        cb('vehicleOwnedPlate',{plate:pendingPlate,newPlate:np});
        if(selId){
            cb('ownedVehiclesReq',{id:selId});
        }
        pendingPlate=null;
        plateChangeModal.classList.add('hidden');
    };
    plateChangeCancel.onclick=()=>{
        pendingPlate=null;
        plateChangeModal.classList.add('hidden');
    };
}

document.querySelectorAll('[data-player]').forEach(b=>{
    b.onclick=()=>{
        if(!selId)return;
        let a=b.dataset.player;
        if(a==='spectate' && spectating){ a='spectateStop'; }
        const d={a:a,id:selId};
        if(a==='kick')d.reason=document.getElementById('kick-reason').value;
        if(a==='ban'){
            d.dur=parseInt(document.getElementById('ban-min').value||'0',10);
            d.reason=document.getElementById('ban-reason').value;
        }
        if(a==='prisonBan'){
            const pills=document.querySelectorAll('.offence-pill.selected');
            const extra=document.getElementById('prisonban-notes');
            const offences=[];
            pills.forEach(p=>{
                const key=p.dataset.offence;
                if(key) offences.push(key);
            });
            pendingPrison={
                id:selId,
                offences:offences,
                notes:extra?extra.value:''
            };
            showPrisonConfirm({});
            cb('prisonPreview',pendingPrison);
            return;
        }
        if(a==='giveMoney'||a==='removeMoney'){
            d.account=document.getElementById('money-acc').value;
            d.amount=parseInt(document.getElementById('money-amt').value||'0',10);
        }
        if(a==='giveItem'){
            d.item=document.getElementById('item-name').value;
            d.count=parseInt(document.getElementById('item-count').value||'1',10);
        }
        if(a==='message'){
            const el=document.getElementById('pm-text');
            d.msg=el?el.value:'';
        }
        if(a==='warn'){
            const el=document.getElementById('warn-text');
            d.msg=el?el.value:'';
        }
        if(a==='setJob'){
            const j=document.getElementById('job-name');
            const g=document.getElementById('job-grade');
            d.job=j?j.value:'';
            d.grade=parseInt((g&&g.value)||'0',10);
        }
        if(a==='clearinv'){
            pendingClearInv={id:selId};
            if(clearInvConfirm){
                clearInvConfirm.classList.remove('hidden');
            }
            return;
        }
        if(a==='checkinv' || a==='openinv-view' || a==='openinv_view'){
            cb('player',{a:'checkinv',id:selId});
            return;
        }
        if(a==='openinv'){
            cb('player',{a:'openinv',id:selId});
            return;
        }
        if(a==='confiscateillegal'){
            pendingOpenInv={id:selId};
            if(openInvConfirm && openInvConfirmText){
                openInvConfirmText.textContent='Checking player inventory for illegal items...';
                if(openInvConfirmButtons) openInvConfirmButtons.classList.add('hidden');
                openInvConfirm.classList.remove('hidden');
            }
            cb('openinvCheck',{id:selId});
            return;
        }
        const toggleActions=['freeze','unfreeze','noclip','invincible','invisible','troll_clone','troll_slowwalk','troll_cam2d'];
        if(toggleActions.includes(a)){
            if(a==='freeze'){
                const f=document.querySelector('[data-player="freeze"]');
                const u=document.querySelector('[data-player="unfreeze"]');
                if(f){
                    const on=!f.classList.contains('state-on');
                    f.classList.toggle('state-on',on);
                }
                if(u){
                    u.classList.remove('state-on');
                }
            }else if(a==='unfreeze'){
                const f=document.querySelector('[data-player="freeze"]');
                const u=document.querySelector('[data-player="unfreeze"]');
                if(u){
                    const on=!u.classList.contains('state-on');
                    u.classList.toggle('state-on',on);
                }
                if(f){
                    f.classList.remove('state-on');
                }
            }else{
                b.classList.toggle('state-on');
            }
        }
        cb('player',d);
    };
});

// SERVER
document.querySelectorAll('[data-server-clean]').forEach(b=>{
    b.onclick=()=>cb('server',{a:'cleanup',mode:b.dataset.serverClean});
});
const cleanupAutoMinutesInput=document.getElementById('cleanup-auto-minutes');
const cleanupAutoToggle=document.getElementById('cleanup-auto-toggle');
let cleanupAutoOn=false;
if(cleanupAutoToggle){
    cleanupAutoToggle.onclick=()=>{
        let mins=parseInt((cleanupAutoMinutesInput && cleanupAutoMinutesInput.value)||'0',10);
        if(isNaN(mins) || mins<1) mins=15;
        if(mins>180) mins=180;
        cleanupAutoOn=!cleanupAutoOn;
        cleanupAutoToggle.classList.toggle('state-on',cleanupAutoOn);
        cb('server',{a:'cleanupAuto',on:cleanupAutoOn,minutes:mins});
    };
}
document.getElementById('weather-btn').onclick=()=>{
    cb('server',{a:'weather',w:document.getElementById('weather').value});
};
const timeBtn=document.getElementById('time-btn');
if(timeBtn){
    timeBtn.onclick=()=>{
        const hourInput=document.getElementById('time-hour');
        const minuteInput=document.getElementById('time-minute');
        const h=parseInt((hourInput && hourInput.value)||'0',10);
        const m=parseInt((minuteInput && minuteInput.value)||'0',10);
        cb('server',{a:'time',hour:h,minute:m});
    };
}
const worldDensityVehInput=document.getElementById('world-density-veh');
const worldDensityPedsInput=document.getElementById('world-density-peds');
const worldDensityVehBtn=document.getElementById('world-density-veh-btn');
const worldDensityBtn=document.getElementById('world-density-btn');
const worldDensityStatus=document.getElementById('world-density-status');
const worldDensityVehStatus=document.getElementById('world-density-veh-status');
const worldDensityPedsStatus=document.getElementById('world-density-peds-status');
const worldDensityVehCurrent=document.getElementById('world-density-veh-current');
const worldDensityPedsCurrent=document.getElementById('world-density-peds-current');
let worldDensityState=null;

function renderWorldDensityStatus(){
    if(!worldDensityState) return;
    const by = worldDensityState.by;
    const at = worldDensityState.at;
    const atStr = at ? new Date(at*1000).toLocaleString() : null;
    const byStr = by ? String(by) : 'Unknown';
    if(worldDensityVehStatus){
        worldDensityVehStatus.textContent = `Vehicles set by ${byStr}: ${worldDensityState.veh}%${atStr ? ' ('+atStr+')' : ''}`;
    }
    if(worldDensityPedsStatus){
        worldDensityPedsStatus.textContent = `Peds set by ${byStr}: ${worldDensityState.peds}%${atStr ? ' ('+atStr+')' : ''}`;
    }
    if(worldDensityStatus){
        worldDensityStatus.style.display = '';
    }
}
if(worldDensityVehBtn){
    worldDensityVehBtn.onclick=()=>{
        if(!worldDensityVehInput) return;
        let veh=parseInt(worldDensityVehInput.value||'100',10);
        if(isNaN(veh)) veh=100;
        if(veh<0) veh=0;
        if(veh>200) veh=200;
        cb('server',{a:'density',percentVeh:veh});
    };
}

if(worldDensityBtn){
    worldDensityBtn.onclick=()=>{
        if(!worldDensityPedsInput) return;
        let peds=parseInt(worldDensityPedsInput.value||'100',10);
        if(isNaN(peds)) peds=100;
        if(peds<0) peds=0;
        if(peds>200) peds=200;
        cb('server',{a:'density',percentPeds:peds});
    };
}

const notifyBtn=document.getElementById('notify-btn');
if(notifyBtn){
    notifyBtn.onclick=()=>{
        const input=document.getElementById('notify-text');
        const msg=((input && input.value) || '').trim();
        if(!msg)return;
        cb('server',{a:'notify',msg:msg});
    };
}

const announceBtn=document.getElementById('announce-btn');
if(announceBtn){
    announceBtn.onclick=()=>{
        const textarea=document.getElementById('announce');
        const msg=((textarea && textarea.value) || '').trim();
        if(!msg)return;
        cb('server',{a:'announce',msg:msg});
    };
}

const chaosMode=document.getElementById('chaos-mode');
const chaosIntensity=document.getElementById('chaos-intensity');
const chaosRunBtn=document.getElementById('chaos-run');
if(chaosRunBtn){
    chaosRunBtn.onclick=()=>{
        const mode=(chaosMode && chaosMode.value) ? String(chaosMode.value) : '';
        if(!mode) return;
        let intensity=parseInt((chaosIntensity && chaosIntensity.value) || '1',10);
        if(isNaN(intensity) || intensity<1) intensity=1;
        if(intensity>5) intensity=5;
        cb('server',{a:'chaos',mode:mode,intensity:intensity});
    };
}

const screenFilterSelect=document.getElementById('screen-filter-select');
const screenFilterApplyBtn=document.getElementById('screen-filter-apply');
const screenFilterClearBtn=document.getElementById('screen-filter-clear');

function setScreenFilterOptions(filters){
    if(!screenFilterSelect) return;
    if(!Array.isArray(filters) || filters.length===0) return;
    const currentVal = String(screenFilterSelect.value||'');
    screenFilterSelect.innerHTML='';
    filters.forEach(f=>{
        if(!f) return;
        const keyRaw = (f.key!=null) ? String(f.key) : '';
        const key = keyRaw.trim().toLowerCase();
        if(!key) return;
        const label = (f.label!=null) ? String(f.label) : keyRaw;
        const opt=document.createElement('option');
        opt.value=key;
        opt.textContent=label;
        screenFilterSelect.appendChild(opt);
    });
    if(currentVal){
        const has = Array.from(screenFilterSelect.options).some(o=>o.value===currentVal);
        if(has) screenFilterSelect.value=currentVal;
    }
}

if(screenFilterApplyBtn){
    screenFilterApplyBtn.onclick=()=>{
        const f=(screenFilterSelect && screenFilterSelect.value) ? String(screenFilterSelect.value) : '';
        if(!f) return;
        cb('server',{a:'screenFilter',mode:'apply',filter:f});
    };
}
if(screenFilterClearBtn){
    screenFilterClearBtn.onclick=()=>{
        cb('server',{a:'screenFilter',mode:'clear'});
    };
}

const staffListDiv=document.getElementById('staff-list');
const staffRefreshBtn=document.getElementById('staff-refresh');
const staffInfoDiv=document.getElementById('staff-info');
const staffCountryInput=document.getElementById('staff-country');
const staffDobInput=document.getElementById('staff-dob');
const staffNoteInput=document.getElementById('staff-note');
const staffNoteAddBtn=document.getElementById('staff-note-add');
const staffNotesListDiv=document.getElementById('staff-notes-list');
const staffMetaSaveBtn=document.getElementById('staff-meta-save');
let currentStaff=null;

const staffNotesByLic={};

function escHtml(s){
    return String(s==null?'':s)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;')
        .replace(/'/g,'&#39;');
}

function renderStaffNotes(){
    if(!staffNotesListDiv){
        return;
    }
    if(!currentStaff || !currentStaff.license){
        staffNotesListDiv.innerHTML='';
        return;
    }
    const lic=currentStaff.license;
    const notes=staffNotesByLic[lic] || [];
    const canDelete=anyPerm(['StaffNotesAdd']);
    if(!Array.isArray(notes) || notes.length===0){
        staffNotesListDiv.innerHTML='<span class="muted">No notes yet.</span>';
        return;
    }
    let html='';
    notes.forEach(n=>{
        const noteIdRaw=(n && n.id!=null)?n.id:null;
        const noteId=(noteIdRaw!=null && noteIdRaw!=='' && isFinite(Number(noteIdRaw))) ? Number(noteIdRaw) : null;
        const by=(n && n.by)?n.by:'Unknown';
        const createdTs=(n && n.created!=null && isFinite(Number(n.created))) ? Number(n.created) : 0;
        const created=(createdTs>0)
            ? new Date(createdTs*1000).toLocaleString()
            : '';
        const body=escHtml((n && n.note) ? n.note : '').replace(/\n/g,'<br>');
        html+=`<div class="staff-ban-row"><strong>${escHtml(by)}</strong>`+
              `${created?`<br><span class=\"time\">${escHtml(created)}</span>`:''}`+
              `${canDelete && noteId?`<br><button class=\"staff-note-del\" data-note-id=\"${noteId}\">Delete</button>`:''}`+
              `<br>${body}</div>`;
    });
    staffNotesListDiv.innerHTML=html;

    if(canDelete){
        staffNotesListDiv.querySelectorAll('.staff-note-del').forEach(btn=>{
            btn.onclick=(ev)=>{
                ev.stopPropagation();
                if(!currentStaff || !currentStaff.license) return;
                if(btn.dataset && btn.dataset.busy==='1') return;
                const id=parseInt(btn.dataset.noteId||'0',10);
                if(!id || id<=0) return;

                // Avoid blocking confirm() dialogs in NUI (they can freeze the menu).
                // Use a quick 2-click confirmation instead.
                const now=Date.now();
                const lastTs=parseInt(btn.dataset.confirmTs||'0',10);
                const armed = btn.dataset.confirm==='1' && lastTs && (now-lastTs) < 2500;
                if(!armed){
                    btn.dataset.confirm='1';
                    btn.dataset.confirmTs=String(now);
                    const oldText=btn.textContent;
                    btn.dataset.oldText=oldText;
                    btn.textContent='Confirm';
                    setTimeout(()=>{
                        if(!btn || !btn.dataset) return;
                        if(btn.dataset.busy==='1') return;
                        btn.dataset.confirm='0';
                        btn.dataset.confirmTs='0';
                        btn.textContent=btn.dataset.oldText || 'Delete';
                    },2500);
                    return;
                }

                btn.dataset.busy='1';
                btn.textContent='Deleting...';
                cb('staffNoteDelete',{license:currentStaff.license,id:id});
            };
        });
    }
}

const rolesListDiv=document.getElementById('roles-list');
const rolePermsDiv=document.getElementById('role-perms');
const rolesStaffDiv=document.getElementById('roles-staff');
const rolesRefreshBtn=document.getElementById('roles-refresh');
const rolesHeadName=document.getElementById('roles-head-name');
const rolesHeadPerms=document.getElementById('roles-head-perms');
const roleNameInput=document.getElementById('role-name');
const roleDutyPayInput=document.getElementById('role-duty-pay');
const roleCreateBtn=document.getElementById('role-create');
const roleSaveBtn=document.getElementById('role-save');
const roleDeleteBtn=document.getElementById('role-delete');
let rolesSortMode='name';
let rolesSortDir='asc';
let currentRole=null;

const allPerms=[
    // Core / Admin Tools / Self
    {group:'Core',k:'MenuOpen',label:'Open Menu'},
    {group:'Admin Tools',k:'Console',label:'Live Console',alignRight:true},
    {group:'Admin Tools',k:'Code',label:'Code Runner',alignRight:true},
    {group:'Admin Tools',k:'Roles',label:'Role Editor',alignRight:true},
    {group:'Admin Tools',k:'Statistics',label:'Statistics (manage)',alignRight:true},
    {group:'Admin Tools',k:'StatisticsView',label:'Statistics (view only)',alignRight:true},
    {group:'Staff',k:'StaffNotesView',label:'Staff - Notes (View)',alignRight:true},
    {group:'Staff',k:'StaffNotesAdd',label:'Staff - Notes (Add)',alignRight:true},
    {group:'Admin Tools',k:'LiveMap',label:'Live Map Blips',alignRight:true},
    {group:'Self',k:'Self',label:'Self - All'},
    {group:'Self',k:'SelfHeal',label:'Self - Heal'},
    {group:'Self',k:'SelfRevive',label:'Self - Revive'},
    {group:'Self',k:'SelfNoclip',label:'Self - Noclip'},
    {group:'Self',k:'SelfInvincible',label:'Self - Invincible'},
    {group:'Self',k:'SelfInvisible',label:'Self - Invisible'},
    {group:'Self',k:'SelfAmmo',label:'Self - Unlimited Ammo'},
    {group:'Self',k:'SelfArmor',label:'Self - Refill Armor'},
    {group:'Self',k:'SelfStress',label:'Self - Clear Stress'},
    {group:'Self',k:'SelfWanted',label:'Self - Reduce Wanted Level'},
    {group:'Self',k:'SelfSuperjump',label:'Self - Super Jump'},
    {group:'Self',k:'SelfRunFast2x',label:'Self - Run Fast 2x'},
    {group:'Self',k:'SelfTeleportMarked',label:'Self - Teleport to Marker'},
    {group:'Self',k:'SelfTeleportMarkedNoVehicle',label:'Self - Teleport to Marker (No Vehicle)'},
    {group:'Self',k:'SelfSkinMenu',label:'Self - Open Skin Menu'},
    {group:'Self',k:'SelfSkin',label:'Self - Skin (all)'},
    {group:'Self',k:'SelfPedSet',label:'Self - Set Ped'},
    {group:'Self',k:'SelfPedClear',label:'Self - Clear Ped'},
    {group:'Self',k:'SelfPedMenu',label:'Self - Ped Menu'},
    {group:'Self',k:'SelfPed',label:'Self - Ped (all)'},
    {group:'Self',k:'SelfDuty',label:'Self - Toggle Duty'},
    {group:'Self',k:'SelfStaffName',label:'Self - Set Staff Name'},
    {group:'Self',k:'SelfRpName',label:'Self - Set RP Name'},
    {group:'Self',k:'SelfSetJob0',label:'Self - Set Job (grade 0)'},
    {group:'Self',k:'SelfSetJob1',label:'Self - Set Job (grade 1)'},
    {group:'Self',k:'SelfSetJob2',label:'Self - Set Job (grade 2)'},
    {group:'Self',k:'SelfSetJob3',label:'Self - Set Job (grade 3)'},
    {group:'Self',k:'SelfSetJob4',label:'Self - Set Job (grade 4)'},
    {group:'Self',k:'SelfSetJob5',label:'Self - Set Job (grade 5)'},
    {group:'Self',k:'SelfSetJob6',label:'Self - Set Job (grade 6)'},
    {group:'Self',k:'SelfGiveMoney',label:'Self - Adjust Funds'},

    // Player
    {group:'Player',k:'Player',label:'Player - All'},
    {group:'Player',k:'PlayerList',label:'Player - View list only'},
    {group:'Player',k:'PlayerKick',label:'Player - Kick'},
    {group:'Player',k:'PlayerBan',label:'Player - Ban'},
    {group:'Player',k:'PlayerPrisonBan',label:'Player - Prison Ban'},
    {group:'Player',k:'PlayerIsolation',label:'Player - Send to Isolation'},
    {group:'Player',k:'PlayerIsolationPardon',label:'Player - Pardon Isolation'},
    {group:'Player',k:'PlayerHeal',label:'Player - Heal'},
    {group:'Player',k:'PlayerRevive',label:'Player - Revive'},
    {group:'Player',k:'PlayerStress',label:'Player - Clear Stress'},
    {group:'Player',k:'PlayerWanted',label:'Player - Reduce Wanted Level'},
    {group:'Player',k:'PlayerKill',label:'Player - Kill'},
    {group:'Player',k:'PlayerWarn',label:'Player - Warn'},
    {group:'Player',k:'PlayerMessage',label:'Player - Private Message'},
    {group:'Player',k:'PlayerSetJob',label:'Player - Set Job'},
    {group:'Player',k:'PlayerBring',label:'Player - Bring'},
    {group:'Player',k:'PlayerGoto',label:'Player - Go To'},
    {group:'Player',k:'PlayerSpectate',label:'Player - Spectate'},
    {group:'Player',k:'PlayerFreeze',label:'Player - Freeze'},
    {group:'Player',k:'PlayerUnfreeze',label:'Player - Unfreeze'},
    {group:'Player',k:'PlayerNoclip',label:'Player - Noclip'},
    {group:'Player',k:'PlayerInvincible',label:'Player - Invincible'},
    {group:'Player',k:'PlayerInvisible',label:'Player - Invisible'},
    {group:'Player',k:'PlayerClearInv',label:'Player - Clear Inventory'},
    {group:'Player',k:'PlayerMoney',label:'Player - Money (give/remove)'},
    {group:'Player',k:'PlayerMoneyView',label:'Player - Money (view balances)'},
    {group:'Player',k:'PlayerGiveItem',label:'Player - Give Item'},
    {group:'Player',k:'PlayerSkin',label:'Player - Open Skin Menu'},
    {group:'Player',k:'PlayerCheckInv',label:'Player - Check Inventory (view only)'},
    {group:'Player',k:'PlayerOpenInvEdit',label:'Player - Open Inventory (move items)'},
    {group:'Player',k:'PlayerConfiscateIllegal',label:'Player - Confiscate Illegal Items'},
    {group:'Player Troll',k:'PlayerTroll',label:'Player - Troll (all)'},
    {group:'Player Troll',k:'PlayerTrollSlap',label:'Player - Troll: Slap'},
    {group:'Player Troll',k:'PlayerTrollLaunch',label:'Player - Troll: Launch'},
    {group:'Player Troll',k:'PlayerTrollScreen',label:'Player - Troll: Screen FX'},
    {group:'Player Troll',k:'PlayerTrollFire',label:'Player - Troll: Fire'},
    {group:'Player Troll',k:'PlayerTrollUfo',label:'Player - Troll: UFO Kidnap'},
    {group:'Player Troll',k:'PlayerTrollNpcKidnap',label:'Player - Troll: NPC Kidnap'},
    {group:'Player Troll',k:'PlayerTrollAnimal',label:'Player - Troll: Animal Attack'},
    {group:'Player Troll',k:'PlayerTrollNpcs',label:'Player - Troll: NPC Attack'},
    {group:'Player Troll',k:'PlayerTrollClone',label:'Player - Troll: Clone Follow'},
    {group:'Player Troll',k:'PlayerTrollFlipveh',label:'Player - Troll: Flip Vehicle'},
    {group:'Player Troll',k:'PlayerTrollSlowwalk',label:'Player - Troll: Slow Walk'},
    {group:'Player Troll',k:'PlayerTrollCam2d',label:'Player - Troll: 2D Camera'},
    {group:'Player Troll',k:'PlayerTrollCamflip',label:'Player - Troll: Flip Camera'},
    {group:'Player Troll',k:'PlayerTrollMobhit',label:'Player - Troll: Mob Hit'},

    // Server
    {group:'Server',k:'Server',label:'Server - All'},
    {group:'Server',k:'ServerCleanup',label:'Server - Cleanup World'},
    {group:'Server',k:'ServerWeather',label:'Server - Set Weather'},
    {group:'Server',k:'ServerAnnounce',label:'Server - Announcement'},
    {group:'Server',k:'ServerChaos',label:'Server - Chaos Events'},
    {group:'Server',k:'ServerFilters',label:'Server - Screen Filters'},
    {group:'Server',k:'ServerDensity',label:'Server - World Density'},

    // Vehicle
    {group:'Vehicle',k:'Vehicle',label:'Vehicle - All'},
    {group:'Vehicle',k:'VehicleSpawn',label:'Vehicle - Spawn'},
    {group:'Vehicle',k:'VehicleRepair',label:'Vehicle - Repair'},
    {group:'Vehicle',k:'VehicleDeleteClosest',label:'Vehicle - Delete Closest'},
    {group:'Vehicle',k:'VehicleMaxMods',label:'Vehicle - Max Mods'},
    {group:'Vehicle',k:'VehicleMaxFuel',label:'Vehicle - Max Fuel'},
    {group:'Vehicle',k:'VehiclePlate',label:'Vehicle - Set Plate'},
    {group:'Vehicle',k:'VehicleColor',label:'Vehicle - Set Colors'},
    {group:'Vehicle',k:'VehicleLock',label:'Vehicle - Lock'},
    {group:'Vehicle',k:'VehicleUnlock',label:'Vehicle - Unlock'},
    {group:'Vehicle',k:'VehicleTorque',label:'Vehicle - Set Torque'},

    // Dev / Bans / Tools
    {group:'Developer',k:'Dev',label:'Developer tools'},
    {group:'Developer',k:'DevLightning',label:'Dev - Lightning Strike'},
    {group:'Developer',k:'DevGodshand',label:"Dev - God's Hand"},
    {group:'Zones',k:'Zones',label:'Zones'},
    {group:'Bans',k:'Bans',label:'Bans'},
    {group:'Bans',k:'BansPardon',label:'Bans - Pardon'},

    // Command perms
    {group:'Commands',k:'CmdBan',label:'/ban command'},
    {group:'Commands',k:'CmdKick',label:'/kick command'},
    {group:'Commands',k:'CmdNoclip',label:'/noclip command'},
    {group:'Commands',k:'CmdClearInv',label:'/clearinv command'},
    {group:'Commands',k:'CmdSkin',label:'/skin command'},
    {group:'Commands',k:'CmdMobhit',label:'/mobhit command'}
];

function renderRoles(){
    if(!rolesListDiv||!rolePermsDiv||!rolesStaffDiv)return;
    const roles=rolesState.roles||{};
    const online=rolesState.online||[];

    rolesListDiv.innerHTML='';
    const entries=Object.keys(roles).map(name=>{
        const rd = roles[name] || [];
        let p = [];
        if(Array.isArray(rd)){
            p = rd;
        } else if(typeof rd === 'object'){
            p = rd.perms || [];
        }
        return {
            name,
            perms: p
        };
    });

    entries.sort((a,b)=>{
        if(rolesSortMode==='perms'){
            const ac=a.perms.length;
            const bc=b.perms.length;
            if(ac===bc){
                const an=a.name.toLowerCase();
                const bn=b.name.toLowerCase();
                if(an<bn)return rolesSortDir==='asc'?-1:1;
                if(an>bn)return rolesSortDir==='asc'?1:-1;
                return 0;
            }
            return rolesSortDir==='asc'?ac-bc:bc-ac;
        }else{
            const an=a.name.toLowerCase();
            const bn=b.name.toLowerCase();
            if(an<bn)return rolesSortDir==='asc'?-1:1;
            if(an>bn)return rolesSortDir==='asc'?1:-1;
            return 0;
        }
    });

    entries.forEach(entry=>{
        const name=entry.name;
        const row=document.createElement('div');
        row.className='player-row';
        const perms=entry.perms;
        row.innerHTML=`<span>${name}</span><span>${perms.length} perms</span><span></span>`;
        row.onclick=()=>selectRole(name);
        if(name===currentRole)row.classList.add('active');
        rolesListDiv.appendChild(row);
    });

    renderRoleDetails();

    rolesStaffDiv.innerHTML='';
    online.forEach(p=>{
        const row=document.createElement('div');
        row.className='roles-staff-row';
        const sel=document.createElement('select');
        sel.innerHTML='<option value="">None</option>'+Object.keys(roles).map(r=>`<option value="${r}">${r}</option>`).join('');
        // Preselect current role if this player is already staff
        let currentRole='';
        (rolesState.staff||[]).forEach(s=>{
            if(s.id===p.id && s.role) currentRole=s.role;
        });
        sel.value=currentRole;
        sel.onchange=()=>{
            cb('roleAssign',{id:p.id,role:sel.value});
        };
        row.innerHTML=`<span>${p.id}</span><span>${p.name}</span>`;
        row.appendChild(sel);
        rolesStaffDiv.appendChild(row);
    });
}

function renderStaff(){
    if(!staffListDiv)return;
    const roles=rolesState.roles||{};
    const staff=rolesState.staff||[];

    staffListDiv.innerHTML='';
    staff.forEach(s=>{
        const row=document.createElement('div');
        row.className='staff-row';
        const sel=document.createElement('select');
        sel.innerHTML='<option value="">None</option>'+Object.keys(roles).map(r=>`<option value="${r}">${r}</option>`).join('');
        sel.value=s.role||'';
        sel.onchange=()=>{
            cb('roleAssign',{id:s.id,role:sel.value});
        };
        const idText   = s.id!=null ? s.id : '';
        const displayName = s.rp || s.name || s.license || '';
        row.innerHTML=`<span>${idText}</span><span>${displayName}</span>`;
        row.appendChild(sel);

        row.onclick=(ev)=>{
            // Ignore clicks on the role dropdown itself
            if(ev.target && ev.target.tagName==='SELECT') return;
            document.querySelectorAll('#staff-list .staff-row').forEach(r=>r.classList.remove('active'));
            row.classList.add('active');
            if(staffInfoDiv){
                const onlineText = s.online ? 'Online' : 'Offline';
                const roleText   = s.role || 'None';
                const licText    = s.license || '';
                const fxName     = s.fx || s.name || '';
                const staffName  = displayName || fxName || 'Unknown';
                const pingText   = (s.online && typeof s.ping==='number') ? `${s.ping} ms` : 'N/A';
                const country    = s.country || 'Unknown';
                const age        = (s.age!=null && s.age!=='') ? s.age : 'Unknown';
                staffInfoDiv.innerHTML=
                    `<strong>${staffName}</strong><br>`+
                    `Ingame name: ${fxName||'Unknown'}<br>`+
                    `ID: ${idText||'N/A'}<br>`+
                    `Role: ${roleText}<br>`+
                    `Status: ${onlineText}<br>`+
                    `Ping: ${pingText}<br>`+
                    `Country: ${country}<br>`+
                    `Age: ${age}`+
                    (licText?`<br>License: ${licText}`:'');

                currentStaff={
                    id: s.id,
                    license: s.license||'',
                    name: staffName
                };
                if(staffCountryInput){
                    staffCountryInput.value = country!=='Unknown'?country:'';
                }
                if(staffDobInput){
                    let rawDob = s.dob;
                    let dobVal = '';

                    const toInputDate = (num)=>{
                        if(!num || !isFinite(num)) return '';
                        // Heuristic: values between ~1e11 and 1e12 treated as ms since epoch,
                        // otherwise assume seconds and convert to ms.
                        let ms = num;
                        if(num <= 1e11) ms = num * 1000;
                        const d = new Date(ms);
                        if(isNaN(d.getTime())) return '';
                        return d.toISOString().slice(0,10); // yyyy-MM-dd
                    };

                    if(typeof rawDob === 'string'){
                        const t = rawDob.trim();
                        if(/^\d{4}-\d{2}-\d{2}$/.test(t)){
                            dobVal = t;
                        }else if(/^\d+$/.test(t)){
                            const n = parseInt(t,10);
                            dobVal = toInputDate(n);
                        }
                    }else if(typeof rawDob === 'number'){
                        dobVal = toInputDate(rawDob);
                    }

                    staffDobInput.value = dobVal;
                }
                if(staffNoteInput){
                    staffNoteInput.value = '';
                }
                if(staffNotesListDiv){
                    staffNotesListDiv.innerHTML='<span class="muted">Loading...</span>';
                }
                if(currentStaff && currentStaff.license){
                    if(anyPerm(['StaffNotesView','StaffNotesAdd'])){
                        cb('staffNotesReq',{license:currentStaff.license});
                    }else if(staffNotesListDiv){
                        staffNotesListDiv.innerHTML='<span class="muted">No permission.</span>';
                    }
                }
                cb('staffBansReq',{
                    id:s.id,
                    name:staffName,
                    license:s.license||'',
                    role:s.role||'',
                    online:!!s.online,
                    fx:fxName||'',
                    rp:s.rp||'',
                    ping:typeof s.ping==='number'?s.ping:null,
                    country:country,
                    age:age,
                    dob:s.dob||''
                });
            }
        };
        staffListDiv.appendChild(row);
    });
}

function selectRole(name){
    currentRole=name;
    renderRoles();
}

function renderRoleDetails(){
    if(!rolePermsDiv)return;
    const roles=rolesState.roles||{};
    const roleData=currentRole && roles[currentRole] || [];
    
    // In our new state format, roles[currentRole] might be an object {perms:[], dutyPay:X} or just an array of perms
    let perms = [];
    let dutyPay = '';
    if(Array.isArray(roleData)){
        perms = roleData;
    } else if(typeof roleData === 'object') {
        perms = roleData.perms || [];
        dutyPay = roleData.DutyPay || '';
    }

    roleNameInput.value=currentRole||'';
    if(roleDutyPayInput) roleDutyPayInput.value = dutyPay;

    const set=new Set(perms);
    if(set.has('PlayerOpenInvView')){
        set.add('PlayerCheckInv');
        set.add('PlayerOpenInvEdit');
    }
    if(set.has('PlayerOpenInv')){
        set.add('PlayerConfiscateIllegal');
    }
    rolePermsDiv.innerHTML='';
    let currentGroup=null;
    let coreAdminHeaderInserted=false;
    let coreRow=null;
    let adminRow=null;
    let devZonesBansHeaderInserted=false;
    let devRow=null;
    let zonesRow=null;
    let bansRow=null;

    allPerms.forEach(p=>{
        const groupName=p.group||'Other';

        // Combined header block: Core on the left, Admin Tools (with its row) on the right
        if((groupName==='Core' || groupName==='Admin Tools') && !coreAdminHeaderInserted){
            coreAdminHeaderInserted=true;
            currentGroup='__core_admin__';

            const header=document.createElement('div');
            header.className='roles-perms-group roles-perms-group-dual';

            const coreBlock=document.createElement('div');
            coreBlock.className='roles-perms-core-block';
            const coreTitle=document.createElement('div');
            coreTitle.className='roles-perms-group-left';
            coreTitle.textContent='Core';
            coreRow=document.createElement('div');
            coreRow.className='roles-perms-core-row';
            coreBlock.appendChild(coreTitle);
            coreBlock.appendChild(coreRow);

            const adminBlock=document.createElement('div');
            adminBlock.className='roles-perms-admin-block';
            const adminTitle=document.createElement('div');
            adminTitle.className='roles-perms-group-right';
            adminTitle.textContent='Admin Tools';
            adminRow=document.createElement('div');
            adminRow.className='roles-perms-admin-row';
            adminBlock.appendChild(adminTitle);
            adminBlock.appendChild(adminRow);

            header.appendChild(coreBlock);
            header.appendChild(adminBlock);

            rolePermsDiv.appendChild(header);
        }else if((groupName==='Developer' || groupName==='Zones' || groupName==='Bans') && !devZonesBansHeaderInserted){
            devZonesBansHeaderInserted=true;
            currentGroup='__dev_zones_bans__';

            const header=document.createElement('div');
            header.className='roles-perms-group roles-perms-triple';

            const devBlock=document.createElement('div');
            devBlock.className='roles-perms-dev-block';
            const devTitle=document.createElement('div');
            devTitle.className='roles-perms-group-left';
            devTitle.textContent='Developer';
            devRow=document.createElement('div');
            devRow.className='roles-perms-dev-row';
            devBlock.appendChild(devTitle);
            devBlock.appendChild(devRow);

            const zonesBlock=document.createElement('div');
            zonesBlock.className='roles-perms-zones-block';
            const zonesTitle=document.createElement('div');
            zonesTitle.className='roles-perms-group-center';
            zonesTitle.textContent='Zones';
            zonesRow=document.createElement('div');
            zonesRow.className='roles-perms-zones-row';
            zonesBlock.appendChild(zonesTitle);
            zonesBlock.appendChild(zonesRow);

            const bansBlock=document.createElement('div');
            bansBlock.className='roles-perms-bans-block';
            const bansTitle=document.createElement('div');
            bansTitle.className='roles-perms-group-right';
            bansTitle.textContent='Bans';
            bansRow=document.createElement('div');
            bansRow.className='roles-perms-bans-row';
            bansBlock.appendChild(bansTitle);
            bansBlock.appendChild(bansRow);

            header.appendChild(devBlock);
            header.appendChild(zonesBlock);
            header.appendChild(bansBlock);

            rolePermsDiv.appendChild(header);
        }else if(groupName!=='Core' && groupName!=='Admin Tools' && groupName!=='Developer' && groupName!=='Zones' && groupName!=='Bans' && groupName!==currentGroup){
            currentGroup=groupName;
            const header=document.createElement('div');
            header.className='roles-perms-group';
            header.textContent=groupName;
            rolePermsDiv.appendChild(header);
        }

        const id='perm-'+p.k;
        const label=document.createElement('label');
        label.innerHTML=`<input type="checkbox" id="${id}"> <span>${p.label}</span>`;
        const cbx=label.querySelector('input');
        cbx.checked=set.has(p.k);
        cbx.onchange=()=>{}; // collect on save

        if(groupName==='Core' && coreRow){
            coreRow.appendChild(label);
        }else if(groupName==='Admin Tools' && adminRow){
            // Place Admin Tools perms directly under its heading on the right
            adminRow.appendChild(label);
        }else if(groupName==='Developer' && devRow){
            devRow.appendChild(label);
        }else if(groupName==='Zones' && zonesRow){
            zonesRow.appendChild(label);
        }else if(groupName==='Bans' && bansRow){
            bansRow.appendChild(label);
        }else{
            rolePermsDiv.appendChild(label);
        }
    });
}

if(rolesRefreshBtn){
    rolesRefreshBtn.onclick=()=>cb('rolesReq',{});
}
if(staffRefreshBtn){
    staffRefreshBtn.onclick=()=>cb('rolesReq',{});
}
if(rolesHeadName){
    rolesHeadName.onclick=()=>{
        if(rolesSortMode==='name'){
            rolesSortDir=rolesSortDir==='asc'?'desc':'asc';
        }else{
            rolesSortMode='name';
            rolesSortDir='asc';
        }
        renderRoles();
    };
}
if(rolesHeadPerms){
    rolesHeadPerms.onclick=()=>{
        if(rolesSortMode==='perms'){
            rolesSortDir=rolesSortDir==='asc'?'desc':'asc';
        }else{
            rolesSortMode='perms';
            rolesSortDir='desc';
        }
        renderRoles();
    };
}
if(staffMetaSaveBtn){
    staffMetaSaveBtn.onclick=()=>{
        if(!currentStaff || !currentStaff.license)return;
        const country=staffCountryInput?staffCountryInput.value||'':'';
        const dob=staffDobInput?staffDobInput.value||'':'';
        cb('staffMetaSave',{
            license:currentStaff.license,
            country:country,
            dob:dob
        });
    };
}
if(staffNoteAddBtn){
    staffNoteAddBtn.onclick=()=>{
        if(!currentStaff || !currentStaff.license)return;
        if(!hasPermUi('StaffNotesAdd')) return;
        const note=staffNoteInput?String(staffNoteInput.value||''):'';
        if(!note || note.trim()==='')return;
        cb('staffNoteAdd',{
            license:currentStaff.license,
            note:note
        });
        if(staffNoteInput) staffNoteInput.value='';
    };
}
if(roleCreateBtn){
    roleCreateBtn.onclick=()=>{
        const name=(roleNameInput.value||'').trim();
        if(!name)return;
        const perms=[];
        allPerms.forEach(p=>{
            const el=document.getElementById('perm-'+p.k);
            if(el&&el.checked)perms.push(p.k);
        });
        let dutyPay = '';
        if(roleDutyPayInput) dutyPay = roleDutyPayInput.value;
        cb('roleSave',{name:name,perms:perms,dutyPay:dutyPay});
        currentRole=name;
    };
}
if(roleSaveBtn){
    roleSaveBtn.onclick=()=>{
        if(!currentRole)return;
        const name=(roleNameInput.value||'').trim();
        if(!name)return;
        const perms=[];
        allPerms.forEach(p=>{
            const el=document.getElementById('perm-'+p.k);
            if(el&&el.checked)perms.push(p.k);
        });
        let dutyPay = '';
        if(roleDutyPayInput) dutyPay = roleDutyPayInput.value;
        cb('roleSave',{name:name,oldName:currentRole,perms:perms,dutyPay:dutyPay});
        currentRole=name;
    };
}
if(roleDeleteBtn){
    roleDeleteBtn.onclick=()=>{
        if(!currentRole)return;
        cb('roleDelete',{name:currentRole});
        currentRole=null;
    };
}

// BANS
const bansDiv=document.getElementById('bans');
const prisonBansDiv=document.getElementById('prison-bans');
const bansRefreshBtn=document.getElementById('bans-refresh');
if(bansRefreshBtn){
    bansRefreshBtn.onclick=()=>{
        cb('bansReq',{});
        cb('prisonBansReq',{});
    };
}

// VEHICLES - spawn & actions
const vehModelInput=document.getElementById('veh-model');
const vehPlateInput=document.getElementById('veh-plate');
const vehSpawnBtn=document.getElementById('veh-spawn');
if(vehSpawnBtn){
    vehSpawnBtn.onclick=()=>{
        if(!vehModelInput)return;
        const model=(vehModelInput.value||'').trim();
        const plate=vehPlateInput?(vehPlateInput.value||'').trim():'';
        if(!model)return;
        cb('vehicle',{a:'spawn',model:model,plate:plate});
    };
}
document.querySelectorAll('[data-veh]').forEach(btn=>{
    btn.onclick=()=>{
        const a=btn.dataset.veh;
        if(!a)return;
        const d={a:a};
        if(a==='plate'){
            const plateInputNew=document.getElementById('veh-plate-new');
            d.plate=plateInputNew?(plateInputNew.value||'').trim():'';
        }else if(a==='color'){
            const colPri=document.getElementById('veh-col-pri');
            const colSec=document.getElementById('veh-col-sec');
            d.col1=parseInt((colPri && colPri.value)||'0',10);
            d.col2=parseInt((colSec && colSec.value)||'0',10);
        }else if(a==='torque'){
            const torqueInput=document.getElementById('veh-torque');
            d.mult=parseFloat((torqueInput && torqueInput.value)||'0')||0;
        }
        cb('vehicle',d);
    };
});

// DEV
document.getElementById('dev-toggle').onclick=()=>cb('dev',{a:'toggle'});
document.getElementById('dev-del').onclick=()=>cb('dev',{a:'del'});
document.getElementById('dev-v3').onclick=()=>cb('dev',{a:'copy3'});
document.getElementById('dev-v4').onclick=()=>cb('dev',{a:'copy4'});
const devLightningBtn=document.getElementById('dev-lightning');
const devGodsHandBtn=document.getElementById('dev-godshand');
if(devLightningBtn) devLightningBtn.onclick=()=>{
    const on=!devLightningBtn.classList.contains('state-on');
    devLightningBtn.classList.toggle('state-on',on);
    cb('dev',{a:'lightning',on:on});
};
if(devGodsHandBtn) devGodsHandBtn.onclick=()=>{
    const on=!devGodsHandBtn.classList.contains('state-on');
    devGodsHandBtn.classList.toggle('state-on',on);
    cb('dev',{a:'godshand',on:on});
};

// CONSOLE
const consoleOut=document.getElementById('console-out');
let exploitMonitorChecks={net:true,health:true,coords:true,weapons:true};
const consoleMonitorSettingsBtn=document.getElementById('console-monitor-settings-btn');
const consoleMonitorSettingsPanel=document.getElementById('console-monitor-settings-panel');
const consoleMonitorInterval=document.getElementById('console-monitor-interval');
const monitorHeavyInput=document.getElementById('monitor-heavy');
const monitorAddInput=document.getElementById('monitor-add-id');
const monitorAddBtn=document.getElementById('monitor-add-btn');
const monitorClearBtn=document.getElementById('monitor-clear-btn');
const monitorListDiv=document.getElementById('monitor-list');
let monitorTargets=[]; // array of numeric IDs
let monitorIntervalMs=60000;

let exploitMonitorWanted=true;
try{
    const raw=localStorage.getItem('oxoExploitMonitorOn');
    if(raw==='0') exploitMonitorWanted=false;
}catch(e){}
if(consoleMonitorSettingsBtn&&consoleMonitorSettingsPanel){
    consoleMonitorSettingsBtn.onclick=()=>{
        consoleMonitorSettingsPanel.classList.toggle('hidden');
    };
}

if(consoleMonitorInterval){
    const applyIntervalFromSelect=()=>{
        const v=parseInt(consoleMonitorInterval.value,10);
        if(!isNaN(v) && v>0){
            monitorIntervalMs=v;
        }
    };
    applyIntervalFromSelect();
    consoleMonitorInterval.addEventListener('change',applyIntervalFromSelect);
}

function renderMonitorTargets(){
    if(!monitorListDiv) return;
    monitorListDiv.innerHTML='';
    if(!monitorTargets.length){
        const span=document.createElement('span');
        span.className='monitor-empty';
        span.textContent='No specific players monitored. Global exploit monitor is active when enabled.';
        monitorListDiv.appendChild(span);
        return;
    }
    monitorTargets.forEach(id=>{
        const pill=document.createElement('span');
        pill.className='monitor-pill';

        const label=document.createElement('span');
        label.textContent='ID '+id;
        pill.appendChild(label);

        const remove=document.createElement('button');
        remove.type='button';
        remove.className='monitor-remove';
        remove.textContent='×';
        remove.title='Remove from monitor list';
        remove.onclick=(e)=>{
            e.stopPropagation();
            monitorTargets=monitorTargets.filter(v=>v!==id);
            renderMonitorTargets();
        };
        pill.appendChild(remove);

        monitorListDiv.appendChild(pill);
    });
}

if(monitorAddBtn && monitorAddInput){
    monitorAddBtn.onclick=()=>{
        const val=parseInt((monitorAddInput.value||'0'),10);
        if(!val || val<=0) return;
        if(!monitorTargets.includes(val)){
            monitorTargets.push(val);
            renderMonitorTargets();
        }
        monitorAddInput.value='';
    };
}
if(monitorClearBtn){
    monitorClearBtn.onclick=()=>{
        monitorTargets=[];
        renderMonitorTargets();
    };
}
renderMonitorTargets();

document.querySelectorAll('[data-monitor-check]').forEach(input=>{
    const key=input.dataset.monitorCheck;
    if(exploitMonitorChecks[key]===undefined){
        exploitMonitorChecks[key]=true;
    }
    input.checked=!!exploitMonitorChecks[key];
    input.addEventListener('change',()=>{
        const k=input.dataset.monitorCheck;
        exploitMonitorChecks[k]=!!input.checked;
    });
});
document.getElementById('console-run').onclick=()=>{
    cb('console',{cmd:document.getElementById('console-cmd').value});
    document.getElementById('console-cmd').value='';
};
const consoleScanBtn=document.getElementById('console-scan');
if(consoleScanBtn){
    consoleScanBtn.onclick=()=>{
        cb('exploitScan',{});
    };
}
const consoleScanOneBtn=document.getElementById('console-scan-one');
if(consoleScanOneBtn){
    consoleScanOneBtn.onclick=()=>{
        const input=document.getElementById('console-scan-id');
        const id=parseInt((input && input.value)||'0',10);
        if(!id) return;
        cb('exploitScanOne',{id:id});
    };
}
const consoleMonitorBtn=document.getElementById('console-monitor');
function sendExploitMonitorState(on){
    if(!consoleMonitorBtn) return;
    const enable=!!on;
    consoleMonitorBtn.classList.toggle('state-on',enable);
    const checks={
        net: exploitMonitorChecks.net!==false,
        health: exploitMonitorChecks.health!==false,
        coords: exploitMonitorChecks.coords!==false,
        weapons: exploitMonitorChecks.weapons!==false,
        targets: monitorTargets.slice(),
        intervalMs: monitorIntervalMs,
        heavy: !!(monitorHeavyInput && monitorHeavyInput.checked)
    };
    cb('exploitMonitor',{on:enable,checks:checks});
}
if(consoleMonitorBtn){
    consoleMonitorBtn.onclick=()=>{
        const on=!consoleMonitorBtn.classList.contains('state-on');
        exploitMonitorWanted=!!on;
        try{ localStorage.setItem('oxoExploitMonitorOn',exploitMonitorWanted?'1':'0'); }catch(e){}
        sendExploitMonitorState(on);
    };
}

// MESSAGE HANDLER
window.addEventListener('message',e=>{
    const d=e.data;
    if(d.a==='densitySync'){
        worldDensityState={
            veh: typeof d.veh==='number' ? d.veh : parseInt(d.veh||'100',10),
            peds: typeof d.peds==='number' ? d.peds : parseInt(d.peds||'100',10),
            by: d.by || null,
            at: d.at || null
        };
        if(worldDensityVehCurrent){
            worldDensityVehCurrent.textContent = `Current: ${worldDensityState.veh}%`;
        }
        if(worldDensityPedsCurrent){
            worldDensityPedsCurrent.textContent = `Current: ${worldDensityState.peds}%`;
        }
        if(worldDensityVehInput && typeof worldDensityState.veh==='number' && !isNaN(worldDensityState.veh)){
            worldDensityVehInput.value=String(worldDensityState.veh);
        }
        if(worldDensityPedsInput && typeof worldDensityState.peds==='number' && !isNaN(worldDensityState.peds)){
            worldDensityPedsInput.value=String(worldDensityState.peds);
        }
        renderWorldDensityStatus();
    }
    if(d.a==='open'){
        app.classList.remove('hidden');
        if(d.payload && d.payload.theme){
            const t=d.payload.theme;
            OxoThemes=t.themes||null;
            OxoActiveThemeKey=t.active||null;
            if(OxoThemes){
                try{
                    const storedKey=localStorage.getItem('oxoThemeKey');
                    if(storedKey && OxoThemes[storedKey]){
                        OxoActiveThemeKey=storedKey;
                    }
                }catch(e){}
            }
            if(OxoThemes && OxoActiveThemeKey && OxoThemes[OxoActiveThemeKey]){
                applyThemeFromDefinition(OxoThemes[OxoActiveThemeKey]);
            }else if(t.colors){
                applyThemeFromDefinition({colors:t.colors});
            }
            initThemeSelectorOnce();
        }
        if(d.payload && d.payload.perms){
            myPerms=d.payload.perms||{};
            myPermsReady=true;
        }else{
            myPerms={};
            myPermsReady=false;
        }

        if(d.payload && Array.isArray(d.payload.screenFilters)){
            setScreenFilterOptions(d.payload.screenFilters);
        }

        // Capture self duty stats snapshot for off-duty card
        if(d.payload && d.payload.selfStats){
            currentSelfStats=d.payload.selfStats;
            // Use the snapshot to seed duty state only if we do not already
            // have a known live duty flag from a prior myDuty event.
            if(!myDutyKnown && typeof currentSelfStats.dutyOnNow==='boolean'){
                myDutyOn=!!currentSelfStats.dutyOnNow;
                myDutyKnown=true;
            }
        }else{
            currentSelfStats=null;
        }
        if(d.payload && typeof d.payload.dutyTotalSeconds!=='undefined'){
            updateDutyHoursBadge(d.payload.dutyTotalSeconds);
        }else{
            updateDutyHoursBadge(0);
        }
        if(d.payload && Array.isArray(d.payload.vehFavorites)){
            adminVehicleFavorites = new Set(
                d.payload.vehFavorites.map(m=>String(m).toLowerCase())
            );
        }else{
            adminVehicleFavorites = new Set();
        }
        if(d.payload && typeof d.payload.roleLabel!=='undefined'){
            updateRoleBadge(d.payload.roleLabel);
        }else{
            updateRoleBadge('');
        }
        if(d.payload && d.payload.monitorChecks){
            const mc=d.payload.monitorChecks||{};
            exploitMonitorChecks={
                net: mc.net!==false,
                health: mc.health!==false,
                coords: mc.coords!==false,
                weapons: mc.weapons!==false
            };
            document.querySelectorAll('[data-monitor-check]').forEach(input=>{
                const key=input.dataset.monitorCheck;
                if(!key) return;
                input.checked=exploitMonitorChecks[key]!==false;
            });

            if(typeof mc.intervalMs==='number' && mc.intervalMs>0){
                monitorIntervalMs=mc.intervalMs;
            }else{
                monitorIntervalMs=60000;
            }
            if(consoleMonitorInterval){
                consoleMonitorInterval.value=String(monitorIntervalMs);
            }
            if(monitorHeavyInput){
                monitorHeavyInput.checked = !!mc.heavy;
            }
        }

        if(cleanupAutoToggle){
            let enabled=false;
            let minutes='';
            if(d.payload && d.payload.cleanupAuto){
                const ac=d.payload.cleanupAuto||{};
                enabled=!!ac.enabled;
                if(typeof ac.minutes==='number' && ac.minutes>0){
                    minutes=String(ac.minutes);
                }
            }
            cleanupAutoOn=enabled;
            cleanupAutoToggle.classList.toggle('state-on',cleanupAutoOn);
            if(cleanupAutoMinutesInput){
                cleanupAutoMinutesInput.value=minutes;
            }
        }

        if(d.payload && Array.isArray(d.payload.adminVehicles)){
            adminVehicles=d.payload.adminVehicles.slice();
            const cats={};
            adminVehicles.forEach(v=>{
                if(!v || !v.model) return;
                const rawCat=(v.category||'other').toString();
                const key=rawCat.toLowerCase();
                const label=(v.categoryLabel||'').toString().trim() || rawCat.toUpperCase();
                if(!cats[key]) cats[key]={key,label,vehicles:[]};
                cats[key].vehicles.push(v);
            });
            adminVehicleCategories=cats;
            renderAdminVehicleCategories();
            const rolesTab=document.querySelector('[data-tab="roles"]');
            const rolesSection=document.querySelector('[data-tab-content="roles"]');
            if(rolesTab)rolesTab.style.display='none';
            if(rolesSection)rolesSection.classList.remove('active');
            const staffTab=document.querySelector('[data-tab="staff"]');
            const staffSection=document.querySelector('[data-tab-content="staff"]');
            if(staffTab)staffTab.style.display='none';
            if(staffSection)staffSection.classList.remove('active');
        }else{
            const rolesTab=document.querySelector('[data-tab="roles"]');
            if(rolesTab)rolesTab.style.display='';
            const staffTab=document.querySelector('[data-tab="staff"]');
            if(staffTab)staffTab.style.display='';
        }

        applyPermissionVisibility();
        updateSelfDutyUi();

        if(consoleMonitorBtn){
            sendExploitMonitorState(exploitMonitorWanted);
        }

        if(statsRefreshBtn){
            statsRefreshBtn.onclick=()=>{
                statsAutoRequested=false;
                requestStatistics();
            };
        }

        // If Monitor tab is currently open, start polling after perms are loaded
        const activeTabBtn=document.querySelector('.tabs button.active');
        const activeTabKey=activeTabBtn && activeTabBtn.dataset ? activeTabBtn.dataset.tab : '';
        if(activeTabKey==='monitor' && hasPermUi('Console')){
            ensureMonitorPolling();
        }else{
            stopMonitorPolling();
        }

        if(activeTabKey==='statistics'){
            ensureStatisticsRequested();
        }

        if(worldDensityState){
            if(worldDensityVehCurrent){
                worldDensityVehCurrent.textContent = `Current: ${worldDensityState.veh}%`;
            }
            if(worldDensityPedsCurrent){
                worldDensityPedsCurrent.textContent = `Current: ${worldDensityState.peds}%`;
            }
            if(worldDensityVehInput && typeof worldDensityState.veh==='number' && !isNaN(worldDensityState.veh)){
                worldDensityVehInput.value=String(worldDensityState.veh);
            }
            if(worldDensityPedsInput && typeof worldDensityState.peds==='number' && !isNaN(worldDensityState.peds)){
                worldDensityPedsInput.value=String(worldDensityState.peds);
            }
            renderWorldDensityStatus();
        }

        cb('playersReq',{});cb('zonesReq',{});        
    }
    if(d.a==='statsData'){
        statsRequestPending=false;
        if(statsRequestTimer){
            clearTimeout(statsRequestTimer);
            statsRequestTimer=null;
        }
        renderStatistics(d.data||null);
        return;
    }
    if(d.a==='statsPlayerInfo'){
        postToStatsPlayer({kind:'profile',data:d.data||null});
        return;
    }
    if(d.a==='statsPlayerAction'){
        postToStatsPlayer({kind:'action',data:d.data||{}});
        return;
    }
    if(d.a==='miniOpen' && miniPanel){
        miniPanel.classList.remove('hidden');
        setMiniMode('mod');
        applyPermissionVisibility();
        updateSelfDutyUi && updateSelfDutyUi();
    }
    if(d.a==='miniClose' && miniPanel){
        miniPanel.classList.add('hidden');
    }
    if(d.a==='close'){
        app.classList.add('hidden');
        stopMonitorPolling();
    }

    if(d.a==='monitorData'){
        renderMonitor(d.data||{});
    }
    if(d.a==='players'){
        playersDiv.innerHTML='';
        (d.list||[]).forEach(p=>{
            const row=document.createElement('div');
            row.className='player-row';
            const fxName=p.name||'';
            const rpName=p.rpName||'';
            const rpSpan=rpName?`<div class="subname">RP: ${escapeHtml(rpName)}</div>`:'';
            row.innerHTML=`
                <span>${p.id}</span>
                <span>
                    <strong>${escapeHtml(fxName)}</strong>
                    ${rpSpan}
                </span>
                <span>${p.ping}</span>`;
            row.onclick=()=>setSel(p.id,fxName,row);
            playersDiv.appendChild(row);
        });
    }
    if(d.a==='bans'){
        bansDiv.innerHTML='';
        (d.list||[]).forEach(b=>{
            const row=document.createElement('div');
            row.className='ban-row';
            const exp=b.expires==0?'Permanent':new Date(b.expires*1000).toLocaleString();
            row.innerHTML=`<span>${b.name} (${b.id})<br>Reason: ${b.reason}<br>By: ${b.by}<br>Expires: ${exp}</span><div class="ban-actions"><button class="btn-unban">Unban</button><button class="btn-pardon">Pardon</button></div>`;
            const unb=row.querySelector('.btn-unban');
            const pard=row.querySelector('.btn-pardon');
            if(unb) unb.onclick=()=>cb('unban',{id:b.id});
            if(pard) pard.onclick=()=>{
                pendingPardon={id:b.id,type:'ban',created:b.created,name:b.name,reason:b.reason};
                showPardonConfirm(pendingPardon);
            };
            bansDiv.appendChild(row);
        });
    }
    if(d.a==='prisonPreview'){
        showPrisonConfirm(d.data||{});
    }
    if(d.a==='prisonBans'){
        if(!prisonBansDiv)return;
        prisonBansDiv.innerHTML='';
        (d.list||[]).forEach(b=>{
            const row=document.createElement('div');
            row.className='ban-row';
            const expText = b.expires==0
                ? 'Permanent'
                : new Date(b.expires*1000).toLocaleString();
            let leftText = '';
            if(b.expires && b.expires>0){
                const nowSec = Math.floor(Date.now()/1000);
                const rem = b.expires - nowSec;
                if(rem>0){
                    const mins = Math.floor(rem/60);
                    const hrs = Math.floor(mins/60);
                    const days = Math.floor(hrs/24);
                    if(days>0)      leftText = `${days}d ${hrs%24}h left`;
                    else if(hrs>0)  leftText = `${hrs}h ${mins%60}m left`;
                    else            leftText = `${mins}m left`;
                }else{
                    leftText = 'Expired';
                }
            }
            const rpLine = b.rpName ? `<br>RP: ${b.rpName}` : '';
            row.innerHTML=`<span>${b.name} (${b.id})${rpLine}<br>Reason: ${b.reason}<br>By: ${b.by}<br>Until: ${expText}${leftText?`<br>${leftText}`:''}</span><button class="btn-pardon">Pardon</button>`;
            const pard=row.querySelector('.btn-pardon');
            if(pard) pard.onclick=()=>{
                pendingPardon={id:b.id,type:'prison',created:b.created,name:b.name,reason:b.reason};
                showPardonConfirm(pendingPardon);
            };
            prisonBansDiv.appendChild(row);
        });
    }
    if(d.a==='playerBans'){
        if(!playerBansDiv)return;
        playerBansDiv.innerHTML='';
        const list=d.list||[];
        if(!list.length){
            playerBansDiv.innerHTML='<span class="muted">No bans for this player.</span>';
            return;
        }
        list.forEach(b=>{
            const row=document.createElement('div');
            row.className='player-ban-row';
            const typeLabel=b.type==='prison'?'Prison Ban':'Ban';
            const isActive=b.type==='ban'?(b.active?true:false):null;
            const statusText = isActive==null?'':(isActive?'Active':'Inactive');

            let duration='';
            if(b.expires===0){
                duration='Permanent';
            }else if(typeof b.expires==='number' && typeof b.created==='number' && b.expires>0 && b.created>0){
                const mins=Math.max(0,Math.round((b.expires-b.created)/60));
                if(mins>0) duration=`${mins} min`;
            }

            const createdStr = (typeof b.created==='number' && b.created>0)
                ? new Date(b.created*1000).toLocaleString()
                : '';

            row.innerHTML = `<div><strong>${typeLabel}</strong>${statusText?` (${statusText})`:''}<br>
                ${createdStr}${duration?` - ${duration}`:''}<br>
                Reason: ${b.reason||''}<br>
                By: ${b.by||''}</div>`;
            playerBansDiv.appendChild(row);

            const pard=document.createElement('button');
            pard.className='btn-pardon';
            pard.textContent='Pardon';
            pard.onclick=()=>{
                pendingPardon={id:b.id,type:b.type,created:b.created,name:b.name,reason:b.reason};
                showPardonConfirm(pendingPardon);
            };
            row.appendChild(pard);
        });
    }
    if(d.a==='playerMoney'){
        if(!playersMoneyStats) return;
        const info=d.data||{};
        if(selId && info.id && Number(info.id)!==Number(selId)) return;
        const cash=Number(info.cash||0)||0;
        const bank=Number(info.bank||0)||0;
        const black=Number(info.black||0)||0;
        playersMoneyStats.innerHTML=
            `<span>Cash: <strong>${formatMoneyShort(cash)}</strong></span>`+
            `<span style="margin-left:10px">Bank: <strong>${formatMoneyShort(bank)}</strong></span>`+
            `<span style="margin-left:10px">Black: <strong>${formatMoneyShort(black)}</strong></span>`;
    }
    if(d.a==='openinvCheckResult'){
        const info=d.data||{};
        if(!openInvConfirm || !openInvConfirmText){
            if(info.hasIllegal && pendingOpenInv){
                cb('player',{a:'confiscateillegal',id:pendingOpenInv.id});
            }
            pendingOpenInv=null;
            if(openInvConfirm) openInvConfirm.classList.add('hidden');
            return;
        }

        const hasIllegal=!!info.hasIllegal;
        if(hasIllegal){
            openInvConfirmText.textContent='Are you sure you want to confiscate all illegal items from this player?';
            if(openInvConfirmButtons) openInvConfirmButtons.classList.remove('hidden');
            if(openInvConfirmYes) openInvConfirmYes.style.display='';
            if(openInvConfirmNo) openInvConfirmNo.textContent='No';
        }else{
            openInvConfirmText.textContent='No illegal items were found in this player\'s inventory.';
            pendingOpenInv=null;
            if(openInvConfirmButtons) openInvConfirmButtons.classList.remove('hidden');
            if(openInvConfirmYes) openInvConfirmYes.style.display='none';
            if(openInvConfirmNo) openInvConfirmNo.textContent='Close';
        }
    }
    if(d.a==='staffBans'){
        if(!staffInfoDiv)return;
        const data=d.data||{};
        const list=data.list||[];
        const actions=data.actions||[];

        // Rebuild the header with richer info (staff vs ingame name, ping, etc.)
        const idText=data.id!=null?data.id:'N/A';
        const licText=data.license||'';
        const onlineText=data.online?'Online':'Offline';
        const fxName=data.fx||'';
        const staffName=data.name||fxName||'Unknown';
        const pingText=(data.online && typeof data.ping==='number')?`${data.ping} ms`:'N/A';
        const country=data.country||'Unknown';
        const age=(data.age!=null && data.age!=='')?data.age:'Unknown';
        const roleText=data.role||'None';

        const totalDutySeconds=(typeof data.totalDutySeconds==='number' && data.totalDutySeconds>0)?data.totalDutySeconds:0;
        const totalDutyLast30Seconds=(typeof data.totalDutyLast30Seconds==='number' && data.totalDutyLast30Seconds>0)?data.totalDutyLast30Seconds:0;
        const dutyOnNow=!!data.dutyOnNow;
        const dutyStatusText=dutyOnNow?'On Duty':'Off Duty';

        let dutyDurationText='No duty time recorded.';
        if(totalDutySeconds>0){
            const mins=Math.floor(totalDutySeconds/60);
            const hours=Math.floor(mins/60);
            const days=Math.floor(hours/24);
            if(days>0){
                dutyDurationText=`${days}d ${hours%24}h`;
            }else if(hours>0){
                dutyDurationText=`${hours}h ${mins%60}m`;
            }else if(mins>0){
                dutyDurationText=`${mins}m`;
            }else{
                dutyDurationText=`<1m`;
            }
        }

        let dutyLast30Text='No duty in last 30 days.';
        if(totalDutyLast30Seconds>0){
            const mins30=Math.floor(totalDutyLast30Seconds/60);
            const hours30=Math.floor(mins30/60);
            const days30=Math.floor(hours30/24);
            if(days30>0){
                dutyLast30Text=`${days30}d ${hours30%24}h`;
            }else if(hours30>0){
                dutyLast30Text=`${hours30}h ${mins30%60}m`;
            }else if(mins30>0){
                dutyLast30Text=`${mins30}m`;
            }else{
                dutyLast30Text=`<1m`;
            }
        }

        let lastActiveTs=null;
        if(typeof data.dutyLastOff==='number' && data.dutyLastOff>0){
            lastActiveTs=data.dutyLastOff;
        }else if(typeof data.dutyLastOn==='number' && data.dutyLastOn>0){
            lastActiveTs=data.dutyLastOn;
        }
        let lastActiveText='Never';
        if(lastActiveTs){
            lastActiveText=new Date(lastActiveTs*1000).toLocaleString();
        }

        const nowSec=Math.floor(Date.now()/1000);
        const THIRTY_DAYS_SEC=30*24*60*60;
        let kicks=0,bansMade=0,prisonBansMade=0,warns=0,messages=0,clears=0,otherActs=0;
        let totalActionsLast30=0;
        actions.forEach(a=>{
            const act=a.action||'';
            const createdNum=typeof a.created==='number'?a.created:0;
            if(createdNum>0 && (nowSec-createdNum)<=THIRTY_DAYS_SEC){
                totalActionsLast30++;
            }
            if(act==='kick')kicks++;
            else if(act==='ban')bansMade++;
            else if(act==='prisonBan')prisonBansMade++;
            else if(act==='warn')warns++;
            else if(act==='message')messages++;
            else if(act==='clearinv')clears++;
            else otherActs++;
        });
        const totalActions=actions.length;

        const totalActionsText = `${totalActions}`;
        const totalActionsLast30Text=`${totalActionsLast30}`;
        const activityParts=[];
        if(kicks)activityParts.push(`Kicks: ${kicks}`);
        if(bansMade)activityParts.push(`Bans: ${bansMade}`);
        if(prisonBansMade)activityParts.push(`Prison bans: ${prisonBansMade}`);
        if(warns)activityParts.push(`Warns: ${warns}`);
        if(messages)activityParts.push(`Messages: ${messages}`);
        if(clears)activityParts.push(`Clear inv: ${clears}`);
        if(otherActs)activityParts.push(`Other: ${otherActs}`);

        const activitySummary = activityParts.length
            ? `Total actions: ${totalActions} (${activityParts.join(' | ')})`
            : `Total actions: ${totalActions}`;

        const totalDutyBadge = dutyDurationText==='No duty time recorded.'
            ? '0m'
            : dutyDurationText;

        const last30Badge = dutyLast30Text==='No duty in last 30 days.'
            ? '0m'
            : dutyLast30Text;

        let bansHtml='';
        if(!list.length){
            bansHtml='<span class="muted">No bans recorded for this staff member.</span>';
        }else{
            list.forEach(b=>{
                const typeLabel=b.type==='prison'?'Prison Ban':'Ban';
                const createdStr=(typeof b.created==='number' && b.created>0)
                    ? new Date(b.created*1000).toLocaleString()
                    : '';
                const target=`${b.name||'Unknown'}${b.id?` (${b.id})`:''}`;
                bansHtml+=`<div class=\"staff-ban-row\"><strong>${typeLabel}</strong> - ${target}`+
                          `${createdStr?`<br><span class=\"time\">${createdStr}</span>`:''}`+
                          `<br>Reason: ${b.reason||''}</div>`;
            });
        }

        let actionsHtml='';
        if(!actions.length){
            actionsHtml='<span class="muted">No actions recorded for this staff member.</span>';
        }else{
            const actionsShown=actions.slice(0,25);
            actionsShown.forEach(a=>{
                const createdStr=(typeof a.created==='number' && a.created>0)
                    ? new Date(a.created*1000).toLocaleString()
                    : '';

                const act=a.action||'';
                let label='Action';
                const extraLines=[];

                if(act==='kick'){
                    label='Kick';
                }else if(act==='ban'){
                    label='Ban';
                }else if(act==='prisonBan'){
                    label='Prison ban';
                }else if(act==='warn'){
                    label='Warn';
                }else if(act==='message'){
                    label='Private message';
                }else if(act==='kill'){
                    label='Kill';
                }else if(act==='setjob'){
                    label='Set job';
                }else if(act==='vehspawn'){
                    label='Spawn vehicle';
                    if(a.model){
                        extraLines.push(`Vehicle: ${a.model}`);
                    }
                }else if(act==='clearinv'){
                    label='Cleared inventory';
                }else if(act==='troll'){
                    const ttype=a.trollType || a.kind || '';
                    label= ttype ? `Troll: ${ttype}` : 'Troll action';
                }else if(act==='control'){
                    const ctype=a.trollType || a.kind || '';
                    label= ctype ? `Control: ${ctype}` : 'Control action';
                }else if(act==='money'){
                    label='Money';
                    const kind=(a.moneyKind || a.kind || 'give').toLowerCase();
                    const rawAcc=(a.account || 'money').toString();
                    let accLabel='cash';
                    if(rawAcc==='bank') accLabel='bank';
                    else if(rawAcc==='black_money' || rawAcc==='black' || rawAcc==='dirty') accLabel='black money';
                    const amtNum=Number(a.amount||0) || 0;
                    if(amtNum>0){
                        const verb=(kind==='remove' || kind==='take' || kind==='fine') ? 'Removed' : 'Given';
                        extraLines.push(`${verb} ${amtNum.toLocaleString()} ${accLabel}`);
                    }
                    if(a.dutyPay){
                        extraLines.push('Duty pay');
                    }
                }else if(act){
                    // Fallback: capitalize raw action key
                    label=act.charAt(0).toUpperCase()+act.slice(1);
                }

                const targetName=a.name||'Unknown';
                const targetId=a.id ? ` (ID ${a.id})` : '';
                actionsHtml+=`<div class=\"staff-ban-row\"><strong>${label}</strong> - ${targetName}${targetId}`;

                if(extraLines.length){
                    actionsHtml+=`<br>${extraLines.join(' • ')}`;
                }
                if(a.reason){
                    actionsHtml+=`<br>Reason: ${a.reason}`;
                }
                if(typeof a.duration==='number' && a.duration>0){
                    actionsHtml+=`<br>Duration: ${a.duration} min`;
                }
                if(Array.isArray(a.items) && a.items.length){
                    const itemsText=a.items.map(it=>{
                        const itemLabel=it.label||it.name||'item';
                        const cnt=it.count||0;
                        return `${itemLabel} x${cnt}`;
                    }).join(', ');
                    actionsHtml+=`<br>Items: ${itemsText}`;
                }
                if(createdStr){
                    actionsHtml+=`<br><span class=\"time\">${createdStr}</span>`;
                }
                actionsHtml+='</div>';
            });
        }

        const dutyChipClass = dutyOnNow ? 'staff-chip chip-online' : 'staff-chip chip-offline';

        const html=
            `<div class="staff-card">`+
              `<div class="staff-card-header">`+
                `<div class="staff-card-main">`+
                  `<div class="staff-card-title-row">`+
                    `<span class="staff-name">${staffName}</span>`+
                    `<span class="staff-role-badge">${roleText}</span>`+
                  `</div>`+
                  `<div class="staff-card-subtitle">`+
                    `<span class="muted">ID ${idText}</span>`+
                    `<span class="${dutyChipClass}">${onlineText}</span>`+
                    `<span class="staff-chip">Ping: ${pingText}</span>`+
                  `</div>`+
                  `<div class="staff-meta-line">${fxName||'Unknown'} • ${country} • Age: ${age}</div>`+
                  (licText?`<div class="staff-meta-line muted">License: ${licText}</div>`:'')+
                  `<div class="staff-meta-line">Last active: <strong>${lastActiveText}</strong></div>`+
                `</div>`+
                `<div class="staff-card-badges">`+
                  `<div class="staff-badge staff-badge-duty ${dutyOnNow?'on':'off'}">`+
                    `<span class="staff-badge-label">Duty</span>`+
                    `<span class="staff-badge-value">${dutyStatusText}</span>`+
                  `</div>`+
                  `<div class="staff-badge staff-badge-time">`+
                    `<div class="staff-badge-row">`+
                      `<span class="staff-badge-label">Total duty</span>`+
                      `<span class="staff-badge-value">${totalDutyBadge}</span>`+
                    `</div>`+
                    `<div class="staff-badge-row staff-badge-row-sub">`+
                      `<span class="staff-badge-label">Last 30 days</span>`+
                      `<span class="staff-badge-value">${last30Badge}</span>`+
                    `</div>`+
                  `</div>`+
                `</div>`+
              `</div>`+
              `<div class="staff-stat-grid">`+
                `<div class="staff-stat-row">`+
                  `<div class="staff-stat">`+
                    `<div class="staff-stat-label">Total actions</div>`+
                    `<div class="staff-stat-value">${totalActionsText}</div>`+
                    `<div class="staff-stat-sub">Last 30 days: ${totalActionsLast30Text}</div>`+
                  `</div>`+
                  `<div class="staff-stat-chips">`+
                    (kicks?`<span class="staff-chip">Kicks: ${kicks}</span>`:'')+
                    (bansMade?`<span class="staff-chip">Bans: ${bansMade}</span>`:'')+
                    (prisonBansMade?`<span class="staff-chip">Prison: ${prisonBansMade}</span>`:'')+
                    (warns?`<span class="staff-chip">Warns: ${warns}</span>`:'')+
                    (messages?`<span class="staff-chip">Messages: ${messages}</span>`:'')+
                    (clears?`<span class="staff-chip">Clear inv: ${clears}</span>`:'')+
                    (otherActs?`<span class="staff-chip">Other: ${otherActs}</span>`:'')+
                  `</div>`+
                `</div>`+
              `</div>`+
              `<div class="staff-sections">`+
                `<details open>`+
                  `<summary>Activity summary</summary>`+
                  `<div class="staff-section-body">${activitySummary}</div>`+
                `</details>`+
                `<details open>`+
                  `<summary>Bans made</summary>`+
                  `<div class="staff-section-body">${bansHtml}</div>`+
                `</details>`+
                `<details>`+
                  `<summary>Actions taken</summary>`+
                  `<div class="staff-section-body staff-section-body-actions">${actionsHtml}</div>`+
                `</details>`+
              `</div>`+
            `</div>`;
        staffInfoDiv.innerHTML=html;
    }
    if(d.a==='staffNotes'){
        const data=d.data||{};
        const license=(data.license!=null)?String(data.license):'';
        if(license){
            staffNotesByLic[license]=Array.isArray(data.notes)?data.notes:[];
        }
        renderStaffNotes();
    }
    if(d.a==='zones'){
        if(window.OxoZones && typeof window.OxoZones.renderZonesFromMessage==='function'){
            window.OxoZones.renderZonesFromMessage(d);
        }else{
            zonesDiv.innerHTML='';
            const list=d.list||[];
            if(!list.length){
                zonesDiv.innerHTML='<span class="muted">No zones created yet. Use the panel on the right to create a zone at your position.</span>';
                return;
            }
            list.forEach(z=>{
                const row=document.createElement('div');
                row.className='zone-row';
                let jobsText='';
                if(Array.isArray(z.jobs) && z.jobs.length){
                    jobsText = ' jobs: '+z.jobs.join(',');
                }else if(z.job && z.job!==''){
                    jobsText = ` job:${z.job}`;
                }
                const blipText = z.blip ? ' [blip]' : '';
                const typeText = z.type && z.type!=='custom' ? ` [${z.type}]` : '';
                let timeText='';
                if(typeof z.start==='number' && typeof z.stop==='number'){
                    timeText = ` [${z.start}-${z.stop}h]`;
                }
                row.innerHTML=`<span>${z.name} (r=${z.r})${typeText}${jobsText}${blipText}${timeText}</span><button>x</button>`;
                const delBtn=row.querySelector('button');
                if(delBtn) delBtn.onclick=(ev)=>{
                    ev.stopPropagation();
                    cb('zone',{a:'delete',id:z.id});
                };

                row.onclick=()=>{
                    currentZoneId=z.id||null;
                    document.querySelectorAll('#zones .zone-row').forEach(r=>r.classList.remove('active'));
                    row.classList.add('active');
                    const typeSel=document.getElementById('zone-type');
                    if(typeSel && z.type) typeSel.value=z.type;
                    const nameInput=document.getElementById('zone-name');
                    if(nameInput) nameInput.value=z.name||'';
                    const rInput=document.getElementById('zone-radius');
                    if(rInput) rInput.value=z.r||'';
                    const spdInput=document.getElementById('zone-maxspd');
                    if(spdInput) spdInput.value=z.maxspd||'';
                    const invCb=document.getElementById('zone-inv');
                    if(invCb) invCb.checked=!!z.inv;
                    const disCb=document.getElementById('zone-disarm');
                    if(disCb) disCb.checked=!!z.disarm;
                    const blipCb=document.getElementById('zone-blip');
                    if(blipCb) blipCb.checked=!!z.blip;
                    const jobInput=document.getElementById('zone-job');
                    if(jobInput){
                        if(Array.isArray(z.jobs) && z.jobs.length){
                            jobInput.value=z.jobs.join(',');
                        }else if(z.job){
                            jobInput.value=z.job;
                        }else{
                            jobInput.value='';
                        }
                    }
                    const startInput=document.getElementById('zone-start');
                    if(startInput) startInput.value=(typeof z.start==='number'?z.start:'');
                    const endInput=document.getElementById('zone-end');
                    if(endInput) endInput.value=(typeof z.stop==='number'?z.stop:'');
                    if(zoneBlipSpriteSel){
                        if(typeof z.blipSprite==='number' && z.blipSprite>0){
                            zoneBlipSpriteSel.value=String(z.blipSprite);
                        }else{
                            zoneBlipSpriteSel.value='';
                        }
                        setZoneBlipSpriteUi(zoneBlipSpriteSel.value);
                    }
                    if(zoneBlipColorSel){
                        if(typeof z.blipColor==='number' && z.blipColor>=0){
                            zoneBlipColorSel.value=String(z.blipColor);
                        }else{
                            zoneBlipColorSel.value='';
                        }
                        setZoneBlipColorUi(zoneBlipColorSel.value);
                    }
                    const btn=document.getElementById('zone-create');
                    if(btn) btn.textContent='Save';
                };
                if(z.id && currentZoneId && z.id===currentZoneId){
                    row.classList.add('active');
                }
                zonesDiv.appendChild(row);
            });
        }
    }
    if(d.a==='ownedVehicles'){
        if(!vehOwnedListDiv)return;
        const data=d.data||{};
        const list=data.vehicles||data.list||[];
        vehOwnedData = Array.isArray(list) ? list.slice() : [];
        renderOwnedVehicles();
    }
    if(d.a==='selfState'){
        const s=d.state||{};
        const apply=(btn,on)=>{
            if(!btn)return;
            if(on)btn.classList.add('state-on');
            else btn.classList.remove('state-on');
        };
        apply(selfNoclipBtn,s.noclip);
        apply(miniNoclipBtn,s.noclip);
        apply(selfInvBtn,s.inv);
        apply(miniInvBtn,s.inv);
        // Invisible: mark when you ARE invisible
        apply(selfInvisBtn,s.invis);
        apply(miniInvisBtn,s.invis);
        // Unlimited ammo
        apply(selfAmmoBtn,s.ammo);
        apply(miniAmmoBtn,s.ammo);
        // Super jump
        apply(selfSuperjumpBtn,s.superjump);
        apply(miniSuperjumpBtn,s.superjump);
        // Run fast 2x
        apply(selfRunfast2xBtn,s.runfast2x);
        apply(miniRunfast2xBtn,s.runfast2x);
        // One punch
        apply(selfOnePunchBtn,s.onepunch);
        apply(miniOnePunchBtn,s.onepunch);
    }
    if(d.a==='selfNameTag'){
        const btn=document.getElementById('self-nametag-btn');
        if(btn){
            if(d.hide)btn.classList.add('state-on');
            else btn.classList.remove('state-on');
        }
    }
    if(d.a==='selfStaffTag'){
        const btn=document.getElementById('self-stafftag-btn');
        if(btn){
            if(d.hide)btn.classList.add('state-on');
            else btn.classList.remove('state-on');
        }
    }
    if(d.a==='spectateState'){
        spectating=!!d.on;
        [spectateBtn,miniSpectateBtn].forEach(btn=>{
            if(!btn)return;
            if(spectating)btn.classList.add('spectate-on');
            else btn.classList.remove('spectate-on');
        });
    }
    if(d.a==='myDuty'){
        const on=!!d.on;
        myDutyOn=on;
        myDutyKnown=true;
        [selfDutyBtn,miniDutyBtn].forEach(btn=>{
            if(!btn)return;
            if(on){
                btn.classList.add('duty-on','state-on');
            }else{
                btn.classList.remove('duty-on','state-on');
            }
        });
        if(headerWatermark){
            if(on) headerWatermark.classList.add('duty-glow');
            else headerWatermark.classList.remove('duty-glow');
        }
        if(roleBadge){
            if(on) roleBadge.classList.add('role-on');
            else roleBadge.classList.remove('role-on');
        }
        if(selfTabBtn){
            if(on) selfTabBtn.classList.remove('self-off');
            else selfTabBtn.classList.add('self-off');
        }
        applyPermissionVisibility();
        updateSelfDutyUi();
    }
    if(d.a==='liveMapState'){
        const on=!!d.on;
        if(selfLiveMapBtn){
            selfLiveMapBtn.classList.toggle('state-on',on);
        }
    }
    if(d.a==='permSync'){
        myPerms=d.perms||{};
        myPermsReady=true;
        applyPermissionVisibility();
    }
    if(d.a==='rolesData'){
        rolesState=d.data||{roles:{},staff:[],online:[]};
        renderRoles();
        renderStaff();
    }
    if(d.a==='console'){
        consoleOut.textContent+=d.line+'\n';
        consoleOut.scrollTop=consoleOut.scrollHeight;
    }
    if(d.a==='clipboard'){
        copyToClipboard(d.text||'');
        cb('clipboardAck',{});
    }
});

function applyPermissionVisibility(){
    // PLAYERS tab visibility (list access)
    const playersTabBtn=document.querySelector('[data-tab="players"]');
    const playersSection=document.querySelector('[data-tab-content="players"]');
    const canPlayersTab=anyPerm(['Player','PlayerList']);
    showOrHide(playersTabBtn,canPlayersTab);
    if(playersSection && !canPlayersTab && playersSection.classList.contains('active')){
        const selfTab=document.querySelector('[data-tab="self"]');
        if(selfTab) selfTab.click();
    }

    // SELF main tab
    const selfHealBtn=document.querySelector('button[data-self="heal"]');
    const selfReviveBtn=document.querySelector('button[data-self="revive"]');
    const selfSkinBtn=document.querySelector('button[data-self="skin"]');
    const selfArmorBtn=document.getElementById('self-armor-btn');
    const selfStressBtn=document.querySelector('button[data-self="stress"]');
    const selfWantedBtn=document.querySelector('button[data-self="wanted"]');
    showOrHide(selfHealBtn,anyPerm(['Self','SelfHeal']));
    showOrHide(selfReviveBtn,anyPerm(['Self','SelfRevive']));
    showOrHide(selfNoclipBtn,anyPerm(['Self','SelfNoclip']));
    showOrHide(selfInvBtn,anyPerm(['Self','SelfInvincible']));
    showOrHide(selfAmmoBtn,anyPerm(['Self','SelfAmmo']));
    showOrHide(selfArmorBtn,anyPerm(['Self','SelfArmor']));
    showOrHide(selfStressBtn,anyPerm(['Self','SelfStress']));
    showOrHide(selfWantedBtn,anyPerm(['Self','SelfWanted']));
    showOrHide(selfSuperjumpBtn,anyPerm(['Self','SelfSuperjump']));
    showOrHide(selfRunfast2xBtn,anyPerm(['Self','SelfRunFast2x']));
    if(selfTpMarkedBtn){
        showOrHide(selfTpMarkedBtn,anyPerm(['Self','SelfTeleportMarked']));
    }
    if(selfTpMarkedNoVehBtn){
        showOrHide(selfTpMarkedNoVehBtn,anyPerm(['Self','SelfTeleportMarkedNoVehicle']));
    }
    showOrHide(selfInvisBtn,anyPerm(['Self','SelfInvisible']));
    const selfNametagBtn=document.getElementById('self-nametag-btn');
    showOrHide(selfNametagBtn,anyPerm(['Self','SelfInvisible']));
    const selfStaffTagBtn=document.getElementById('self-stafftag-btn');
    showOrHide(selfStaffTagBtn,anyPerm(['Self','SelfStaffName']));
    if(selfJobRow){
        const gradePerms=SELF_JOB_GRADE_KEYS.map(key=>myDutyOn && hasPermUi(key));
        const canSelfJob=gradePerms.some(Boolean);
        showOrHide(selfJobRow,canSelfJob);
        if(selfJobBtn) selfJobBtn.disabled=!canSelfJob;
        if(selfJobGradeSelect){
            const opts=[...selfJobGradeSelect.options];
            let fallback='';
            opts.forEach(opt=>{
                const grade=parseInt(opt.value||'-1',10);
                const allowed=grade>=0 && gradePerms[grade]===true;
                opt.disabled=!allowed;
                if(allowed && !fallback) fallback=opt.value;
            });
            if(!fallback){
                selfJobGradeSelect.value='';
            }else if(!selfJobGradeSelect.value || selfJobGradeSelect.options[selfJobGradeSelect.selectedIndex]?.disabled){
                selfJobGradeSelect.value=fallback;
            }
        }
    }
    if(selfMoneyRow){
        const canSelfMoney=myDutyOn && anyPerm(['SelfGiveMoney']);
        showOrHide(selfMoneyRow,canSelfMoney);
        if(selfMoneyBtn) selfMoneyBtn.disabled=!canSelfMoney;
    }
    if(selfLiveMapBtn){
        const row=selfLiveMapBtn.closest('.row')||selfLiveMapBtn;
        showOrHide(row,myDutyOn && hasPermUi('LiveMap'));
    }
    showOrHide(selfSkinBtn,anyPerm(['Self','SelfSkin','SelfSkinMenu']));

    const selfPedMenuBtn=document.getElementById('self-pedmenu-btn');
    const selfPedInput=document.getElementById('self-ped');
    const selfPedRow=selfPedInput && (selfPedInput.closest('.row')||selfPedInput);
    const selfPedClearBtn=document.getElementById('self-ped-clear-btn');
    const selfPedBtn2=document.getElementById('self-ped-btn');
    const canSelfPedSet=anyPerm(['Self','SelfPed','SelfPedSet']);
    const canSelfPedClear=anyPerm(['Self','SelfPed','SelfPedClear']);
    const canSelfPedMenu=anyPerm(['Self','SelfPed','SelfPedMenu']);
    const canAnyPed=canSelfPedSet||canSelfPedClear||canSelfPedMenu;
    showOrHide(selfPedMenuBtn,canSelfPedMenu);
    showOrHide(selfPedClearBtn,canSelfPedClear);
    showOrHide(selfPedBtn2,canSelfPedSet);
    if(selfPedRow) showOrHide(selfPedRow,canAnyPed);
    const selfOnePunchBtn=document.getElementById('self-onepunch-btn');
    showOrHide(selfOnePunchBtn,anyPerm(['Player','PlayerTroll']));

    const selfLayout=document.querySelector('.self-layout');
    if(selfLayout) showOrHide(selfLayout,myDutyOn);

    // DEV tab visibility (Lightning / God's Hand)
    const devLightningBtnVis=document.getElementById('dev-lightning');
    const devGodsHandBtnVis=document.getElementById('dev-godshand');
    const miniLightningBtn=document.querySelector('[data-mini-dev="lightning"]');
    const miniGodsHandBtn=document.querySelector('[data-mini-dev="godshand"]');
    const canDevLightning=anyPerm(['Dev','DevLightning']);
    const canDevGodsHand=anyPerm(['Dev','DevGodshand']);
    showOrHide(devLightningBtnVis,canDevLightning);
    showOrHide(devGodsHandBtnVis,canDevGodsHand);
    showOrHide(miniLightningBtn,canDevLightning);
    showOrHide(miniGodsHandBtn,canDevGodsHand);

    if(selfDutyBtn){
        const dutyContainer=selfDutyBtn.closest('.self-duty-top')||selfDutyBtn.closest('.row')||selfDutyBtn;
        const canDuty=anyPerm(['Self','SelfDuty']);
        showOrHide(dutyContainer,canDuty);
        selfDutyBtn.classList.toggle('self-duty-big',canDuty);
        selfDutyBtn.classList.toggle('self-duty-off',!myDutyOn && canDuty);
    }

    if(staffNameInput){
        const staffRow=staffNameInput.closest('.row')||staffNameInput;
        const canStaffName=myDutyOn && anyPerm(['Self','SelfStaffName']);
        showOrHide(staffRow,canStaffName);
    }

    if(rpFirstInput){
        const rpRow=rpFirstInput.closest('.row')||rpFirstInput;
        const canRp=myDutyOn && anyPerm(['Self','SelfRpName']);
        showOrHide(rpRow,canRp);
    }

    const canStaffNotes=anyPerm(['StaffNotesView','StaffNotesAdd']);
    const canStaffNotesAdd=anyPerm(['StaffNotesAdd']);
    const staffNoteRow=staffNoteInput && (staffNoteInput.closest('.row')||staffNoteInput);
    const staffNotesListRow=staffNotesListDiv && (staffNotesListDiv.closest('.row')||staffNotesListDiv);
    const staffNoteAddRow=staffNoteAddBtn && (staffNoteAddBtn.closest('.row')||staffNoteAddBtn);
    showOrHide(staffNotesListRow,canStaffNotes);
    showOrHide(staffNoteRow,canStaffNotesAdd);
    showOrHide(staffNoteAddRow,canStaffNotesAdd);

    // SELF mini menu
    document.querySelectorAll('[data-mini-self]').forEach(btn=>{
        const a=btn.dataset.miniSelf;
        let keys=null;
        if(a==='heal') keys=['Self','SelfHeal'];
        else if(a==='revive') keys=['Self','SelfRevive'];
        else if(a==='noclip') keys=['Self','SelfNoclip'];
        else if(a==='invincible') keys=['Self','SelfInvincible'];
        else if(a==='ammo') keys=['Self','SelfAmmo'];
        else if(a==='superjump') keys=['Self','SelfSuperjump'];
        else if(a==='invisible') keys=['Self','SelfInvisible'];
        else if(a==='armor') keys=['Self','SelfArmor'];
        else if(a==='stress') keys=['Self','SelfStress'];
        else if(a==='duty') keys=['Self','SelfDuty'];
        if(!keys) return;
        const hasPerm=anyPerm(keys);
        let allowed=false;
        if(a==='duty'){
            // Duty toggle visible whenever the user has SelfDuty, regardless of duty state
            allowed=hasPerm || !myPermsReady;
        }else{
            // All other mini self actions require both duty ON and the right permission
            allowed=myDutyOn && hasPerm;
        }
        showOrHide(btn,allowed);
    });

    // PLAYER section headers / blocks
    const canModeration=anyPerm(['Player','PlayerKick','PlayerBan','PlayerPrisonBan','PlayerIsolation','PlayerIsolationPardon']);
    const modHeader=document.getElementById('players-moderation-header');
    const modGrid=document.getElementById('players-moderation-grid');
    showOrHide(modHeader,canModeration);
    showOrHide(modGrid,canModeration);

    const isolationSection=document.getElementById('players-isolation-section');
    const canIsolation=anyPerm(['Player','PlayerIsolation','PlayerIsolationPardon']);
    showOrHide(isolationSection,canIsolation);

    const canHealth=anyPerm(['Player','PlayerHeal','PlayerRevive','PlayerKill']);
    const healthCol=document.getElementById('players-health-col');
    showOrHide(healthCol,canHealth);

    const canControl=anyPerm(['Player','PlayerFreeze','PlayerUnfreeze','PlayerNoclip','PlayerInvincible','PlayerInvisible']);
    const controlHeader=document.getElementById('players-control-header');
    const controlGrid=document.getElementById('players-control-grid');
    showOrHide(controlHeader,canControl);
    showOrHide(controlGrid,canControl);

    const canMoneyView=anyPerm(['Player','PlayerMoney','PlayerMoneyView']);
    const canMoneyEdit=anyPerm(['Player','PlayerMoney']);
    const moneyHeader=document.getElementById('players-money-header');
    const moneyStats=document.getElementById('players-money-stats');
    const moneyRow1=document.getElementById('players-money-row1');
    const moneyRow2=document.getElementById('players-money-row2');
    showOrHide(moneyHeader,canMoneyView);
    showOrHide(moneyStats,canMoneyView);
    showOrHide(moneyRow1,canMoneyEdit);
    showOrHide(moneyRow2,canMoneyEdit);

    const canInv=anyPerm(['Player','PlayerClearInv','PlayerCheckInv','PlayerOpenInvEdit','PlayerConfiscateIllegal','PlayerGiveItem','PlayerOpenInv','PlayerOpenInvView']);
    const invHeader=document.getElementById('players-inventory-header');
    const invGiveRow=document.getElementById('players-inventory-give-row');
    const invClearBtn=document.querySelector('button[data-player="clearinv"]');
    const invCheckBtn=document.querySelector('button[data-player="checkinv"]');
    const invOpenBtn=document.querySelector('button[data-player="openinv"]');
    const invConfiscateBtn=document.querySelector('button[data-player="confiscateillegal"]');
    showOrHide(invHeader,canInv);
    showOrHide(invGiveRow,canInv);
    showOrHide(invClearBtn,anyPerm(['Player','PlayerClearInv']));
    showOrHide(invCheckBtn,anyPerm(['Player','PlayerCheckInv','PlayerOpenInvView']));
    showOrHide(invOpenBtn,anyPerm(['Player','PlayerOpenInvEdit','PlayerOpenInvView']));
    showOrHide(invConfiscateBtn,anyPerm(['Player','PlayerConfiscateIllegal','PlayerOpenInv']));

    const canSkin=anyPerm(['Player','PlayerSkin']);
    const skinHeader=document.getElementById('players-skin-header');
    const skinBtn=document.querySelector('button[data-player="skin"]');
    showOrHide(skinHeader,canSkin);
    showOrHide(skinBtn,canSkin);

    const canTroll=anyPerm([
        'Player','PlayerTroll',
        'PlayerTrollSlap','PlayerTrollLaunch','PlayerTrollScreen','PlayerTrollFire',
        'PlayerTrollUfo','PlayerTrollNpcKidnap','PlayerTrollAnimal','PlayerTrollNpcs',
        'PlayerTrollClone','PlayerTrollFlipveh','PlayerTrollSlowwalk',
        'PlayerTrollCam2d','PlayerTrollCamflip'
    ]);
    const trollHeader=document.getElementById('players-troll-header');
    const trollGrid=document.getElementById('players-troll-grid');
    showOrHide(trollHeader,canTroll);
    showOrHide(trollGrid,canTroll);

    const canComm=anyPerm(['Player','PlayerMessage','PlayerWarn']);
    const commHeader=document.getElementById('players-communication-header');
    const commRow1=document.getElementById('players-communication-row1');
    const commRow2=document.getElementById('players-communication-row2');
    showOrHide(commHeader,canComm);
    showOrHide(commRow1,canComm);
    showOrHide(commRow2,canComm);

    const canJob=anyPerm(['Player','PlayerSetJob']);
    const jobHeader=document.getElementById('players-job-header');
    const jobRow=document.getElementById('players-job-row');
    showOrHide(jobHeader,canJob);
    showOrHide(jobRow,canJob);

    const canHistory=hasPermUi('Bans');
    const historyHeader=document.getElementById('players-history-header');
    const historyBlock=document.getElementById('player-history');
    showOrHide(historyHeader,canHistory);
    showOrHide(historyBlock,canHistory);
    const miniOnePunchBtn=document.getElementById('mini-onepunch-btn');
    showOrHide(miniOnePunchBtn,anyPerm(['Player','PlayerTroll']));
    const miniRunfast2xBtn=document.getElementById('mini-runfast2x-btn');
    showOrHide(miniRunfast2xBtn,anyPerm(['Self','SelfRunFast2x']));
    if(miniTpMarkedBtn){
        showOrHide(miniTpMarkedBtn,anyPerm(['Self','SelfTeleportMarked']));
    }
    if(miniTpMarkedNoVehBtn){
        showOrHide(miniTpMarkedNoVehBtn,anyPerm(['Self','SelfTeleportMarkedNoVehicle']));
    }

    // PLAYER main panel
    const PLAYER_ACTION_PERMS={
        kick:['Player','PlayerKick'],
        ban:['Player','PlayerBan'],
        prisonBan:['Player','PlayerPrisonBan'],
        isolation:['Player','PlayerIsolation'],
        isolationPardon:['Player','PlayerIsolationPardon'],
        heal:['Player','PlayerHeal'],
        revive:['Player','PlayerRevive'],
        stress:['Player','PlayerStress'],
        wanted:['Player','PlayerWanted'],
        kill:['Player','PlayerKill'],
        warn:['Player','PlayerWarn'],
        message:['Player','PlayerMessage'],
        setJob:['Player','PlayerSetJob'],
        bring:['Player','PlayerBring'],
        goto:['Player','PlayerGoto'],
        spectate:['Player','PlayerSpectate'],
        spectateStop:['Player','PlayerSpectate'],
        freeze:['Player','PlayerFreeze'],
        unfreeze:['Player','PlayerUnfreeze'],
        noclip:['Player','PlayerNoclip'],
        invincible:['Player','PlayerInvincible'],
        invisible:['Player','PlayerInvisible'],
        clearinv:['Player','PlayerClearInv'],
        checkinv:['Player','PlayerCheckInv','PlayerOpenInvView'],
        openinv:['Player','PlayerOpenInvEdit','PlayerOpenInvView'],
        confiscateillegal:['Player','PlayerConfiscateIllegal','PlayerOpenInv'],
        giveItem:['Player','PlayerGiveItem'],
        giveMoney:['Player','PlayerMoney'],
        removeMoney:['Player','PlayerMoney'],
        skin:['Player','PlayerSkin'],
        troll_slap:['Player','PlayerTroll','PlayerTrollSlap'],
        troll_launch:['Player','PlayerTroll','PlayerTrollLaunch'],
        troll_screen:['Player','PlayerTroll','PlayerTrollScreen'],
        troll_fire:['Player','PlayerTroll','PlayerTrollFire'],
        troll_ufo:['Player','PlayerTroll','PlayerTrollUfo'],
        troll_npc_kidnap:['Player','PlayerTroll','PlayerTrollNpcKidnap'],
        troll_animal:['Player','PlayerTroll','PlayerTrollAnimal'],
        troll_npcs:['Player','PlayerTroll','PlayerTrollNpcs'],
        troll_clone:['Player','PlayerTroll','PlayerTrollClone'],
        troll_flipveh:['Player','PlayerTroll','PlayerTrollFlipveh'],
        troll_slowwalk:['Player','PlayerTroll','PlayerTrollSlowwalk'],
        troll_cam2d:['Player','PlayerTroll','PlayerTrollCam2d'],
        troll_camflip:['Player','PlayerTroll','PlayerTrollCamflip'],
        troll_mobhit:['Player','PlayerTroll','PlayerTrollMobhit']
    };
    document.querySelectorAll('[data-player]').forEach(btn=>{
        const a=btn.dataset.player;
        const keys=PLAYER_ACTION_PERMS[a];
        if(!keys) return;
        const allowed=anyPerm(keys);
        const row=btn.closest('.row') || btn;
        showOrHide(row,allowed);
    });

    // PLAYER mini menu
    document.querySelectorAll('[data-mini-player]').forEach(btn=>{
        const a=btn.dataset.miniPlayer;
        const keys=PLAYER_ACTION_PERMS[a];
        if(!keys) return;
        const hasPerm=anyPerm(keys);
        // Player actions in mini menu only when on duty and permitted
        showOrHide(btn,myDutyOn && hasPerm);
    });

    // DEV mini menu
    document.querySelectorAll('[data-mini-dev]').forEach(btn=>{
        // Dev actions only when on duty and with Dev permission
        showOrHide(btn,myDutyOn && hasPermUi('Dev'));
    });

    // SERVER tab buttons
    const canCleanup=anyPerm(['Server','ServerCleanup']);
    document.querySelectorAll('[data-server-clean]').forEach(btn=>{
        showOrHide(btn,canCleanup);
    });
    // Auto cleanup row (minutes + toggle) should only be visible for cleanup perms
    if(typeof cleanupAutoMinutesInput!=='undefined' && cleanupAutoMinutesInput){
        const autoRow=cleanupAutoMinutesInput.closest('.row') || cleanupAutoMinutesInput;
        showOrHide(autoRow,canCleanup);
    }
    // Chaos events row only for ServerChaos
    const canChaos=anyPerm(['Server','ServerChaos']);
    const chaosRow=document.getElementById('chaos-row');
    showOrHide(chaosRow,canChaos);

    const canFilters=anyPerm(['Server','ServerFilters']);
    const screenFiltersRow=document.getElementById('screen-filters-row');
    showOrHide(screenFiltersRow,canFilters);

    const canWeather=anyPerm(['Server','ServerWeather']);
    const weatherBtn=document.getElementById('weather-btn');
    if(weatherBtn){
        const row=weatherBtn.closest('.row') || weatherBtn;
        showOrHide(row,canWeather);
    }
    const timeBtnEl=document.getElementById('time-btn');
    if(timeBtnEl){
        const row=timeBtnEl.closest('.row') || timeBtnEl;
        showOrHide(row,canWeather);
    }
    const canAnnounce=anyPerm(['Server','ServerAnnounce']);
    const announceBtn=document.getElementById('announce-btn');
    const announceText=document.getElementById('announce');
    showOrHide(announceBtn,canAnnounce);
    showOrHide(announceText,canAnnounce);

    // VEHICLE tab contents
    const vehSpawnBtn=document.getElementById('veh-spawn');
    if(vehSpawnBtn){
        const row=vehSpawnBtn.closest('.row') || vehSpawnBtn;
        showOrHide(row,anyPerm(['Vehicle','VehicleSpawn']));
    }
    const VEH_ACTION_PERMS={
        repair:['Vehicle','VehicleRepair'],
        deleteClosest:['Vehicle','VehicleDeleteClosest'],
        maxmods:['Vehicle','VehicleMaxMods'],
        maxfuel:['Vehicle','VehicleMaxFuel'],
        plate:['Vehicle','VehiclePlate'],
        color:['Vehicle','VehicleColor'],
        lock:['Vehicle','VehicleLock'],
        unlock:['Vehicle','VehicleUnlock'],
        torque:['Vehicle','VehicleTorque']
    };
    document.querySelectorAll('[data-veh]').forEach(btn=>{
        const a=btn.dataset.veh;
        const keys=VEH_ACTION_PERMS[a];
        if(!keys) return;
        const allowed=anyPerm(keys);
        // For rows with inputs (plate/color/torque), hide the whole row
        let target=btn;
        if(a==='plate' || a==='color' || a==='torque'){
            target=btn.closest('.row') || btn;
        }
        showOrHide(target,allowed);
    });

    // Admin vehicles section (list + search + top preview)
    if(vehAdminList){
        const canSpawnAdmin=anyPerm(['Vehicle','VehicleSpawn']);
        const layout=vehAdminList.closest('.veh-admin-layout') || vehAdminList;
        const adminSection=vehAdminList.closest('.veh-subcontent[data-veh-subcontent="admin"]');
        const adminHeader=adminSection && adminSection.querySelector('h3');
        const adminPreview=document.getElementById('veh-admin-preview');
        showOrHide(layout,canSpawnAdmin);
        showOrHide(adminHeader,canSpawnAdmin);
        showOrHide(adminPreview,canSpawnAdmin);
    }

    // Player owned vehicles section
    const canOwned=hasPermUi('Vehicle');
    const ownedHeader=document.querySelector('.veh-owned-header');
    const ownedLoad=document.getElementById('veh-owned-load');
    const ownedList=document.getElementById('veh-owned-list');
    const giftModel=document.getElementById('veh-gift-model');
    const giftRow=giftModel && giftModel.closest('.row');
    showOrHide(ownedHeader,canOwned);
    showOrHide(ownedLoad && ownedLoad.closest('.row'),canOwned);
    showOrHide(ownedList,canOwned);
    showOrHide(giftRow,canOwned);

    // TABS basic gating: SERVER / VEHICLE / ZONES / BANS / ROLES / STAFF / CONSOLE / DEV
    const serverTab=document.querySelector('[data-tab="server"]');
    const serverSection=document.querySelector('[data-tab-content="server"]');
    const canServerTab=anyPerm(['Server','ServerCleanup','ServerWeather','ServerAnnounce','ServerChaos','ServerFilters']);
    showOrHide(serverTab,canServerTab);
    if(serverSection && !canServerTab) serverSection.classList.remove('active');

    const vehicleTab=document.querySelector('[data-tab="vehicle"]');
    const vehicleSection=document.querySelector('[data-tab-content="vehicle"]');
    const canVehicleTab=anyPerm([
        'Vehicle','VehicleSpawn','VehicleRepair','VehicleDeleteClosest',
        'VehicleMaxMods','VehicleMaxFuel','VehiclePlate','VehicleColor',
        'VehicleLock','VehicleUnlock','VehicleTorque'
    ]);
    showOrHide(vehicleTab,canVehicleTab);
    if(vehicleSection && !canVehicleTab) vehicleSection.classList.remove('active');

    const zonesTab=document.querySelector('[data-tab="zones"]');
    const zonesSection=document.querySelector('[data-tab-content="zones"]');
    const canZones=hasPermUi('Zones');
    showOrHide(zonesTab,canZones);
    if(zonesSection && !canZones) zonesSection.classList.remove('active');

    const bansTab=document.querySelector('[data-tab="bans"]');
    const bansSection=document.querySelector('[data-tab-content="bans"]');
    const canBans=hasPermUi('Bans');
    showOrHide(bansTab,canBans);
    if(bansSection && !canBans) bansSection.classList.remove('active');

    const rolesTab=document.querySelector('[data-tab="roles"]');
    const rolesSection=document.querySelector('[data-tab-content="roles"]');
    const staffTab=document.querySelector('[data-tab="staff"]');
    const staffSection=document.querySelector('[data-tab-content="staff"]');
    const canRoles=hasPermUi('Roles');
    showOrHide(rolesTab,canRoles);
    if(rolesSection && !canRoles) rolesSection.classList.remove('active');
    showOrHide(staffTab,canRoles);
    if(staffSection && !canRoles) staffSection.classList.remove('active');

    const devTab=document.querySelector('[data-tab="dev"]');
    const devSection=document.querySelector('[data-tab-content="dev"]');
    const canDev=hasPermUi('Dev');
    showOrHide(devTab,canDev);
    if(devSection && !canDev) devSection.classList.remove('active');

    const consoleTab=document.querySelector('[data-tab="console"]');
    const consoleSection=document.querySelector('[data-tab-content="console"]');
    const canConsole=hasPermUi('Console');
    showOrHide(consoleTab,canConsole);
    if(consoleSection && !canConsole) consoleSection.classList.remove('active');

    const monitorTab=document.querySelector('[data-tab="monitor"]');
    const monitorSection=document.querySelector('[data-tab-content="monitor"]');
    showOrHide(monitorTab,canConsole);
    if(monitorSection && !canConsole) monitorSection.classList.remove('active');

    const statisticsTab=document.querySelector('[data-tab="statistics"]');
    const statisticsSection=document.querySelector('[data-tab-content="statistics"]');
    statsCanView=anyPerm(['Statistics','StatisticsView']);
    showOrHide(statisticsTab,statsCanView);
    showOrHide(statisticsSection,statsCanView);
    if(!statsCanView && statisticsSection && statisticsSection.classList.contains('active')){
        const selfTab=document.querySelector('[data-tab="self"]');
        if(selfTab) selfTab.click();
    }
    if(statsCanView){
        ensureStatisticsRequested();
    }
}
