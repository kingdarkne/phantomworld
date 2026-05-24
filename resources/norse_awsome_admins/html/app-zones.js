// Zones module extracted from app.js
// Depends on global cb(), document structure in index.html, and is loaded before app.js.

(function(){
    const zonesDiv=document.getElementById('zones');
    let currentZoneId=null;
    const zoneBlipSpriteSel=document.getElementById('zone-blip-sprite');
    const zoneBlipColorSel=document.getElementById('zone-blip-color');
    const zoneBlipSpriteList=document.getElementById('zone-blip-sprite-list');
    const zoneBlipColorList=document.getElementById('zone-blip-color-list');
    
    // Blip names from GTA radar list (common / useful for zones)
    const ZONE_BLIP_NAMES={
        0:'Higher',1:'Level',2:'Lower',3:'Police Ped',4:'Wanted Radius',
        5:'Area Blip',6:'Centre',7:'North',8:'Waypoint',
        9:'Radius Blip',10:'Radius Outline',11:'Weapon Higher',12:'Weapon Lower',
        13:'Higher AI',14:'Lower AI',15:'Police Heli Spin',16:'Police Plane Move',
        27:'MP Crew',28:'MP Friendlies',36:'Cable Car',37:'Activities',
        38:'Race Flag',40:'Safehouse',41:'Police',42:'Police Chase',
        43:'Police Heli',44:'Bomb A',47:'Snitch',48:'Planning Locations',
        50:'Crim Carsteal',51:'Crim Drugs',52:'Crim Holdups',54:'Crim Player',
        56:'Cop Patrol',57:'Cop Player',58:'Crim Wanted',59:'Heist',
        60:'Police Station',61:'Hospital',62:'Assassins Mark',63:'Elevator',
        64:'Helicopter',66:'Random Character',67:'Security Van',68:'Tow Truck',
        70:'Illegal Parking',71:'Barber',72:'Car Mod Shop',73:'Clothes Store',
        75:'Tattoo',76:'Armenian Family',77:'Lester Family',78:'Michael Family',
        79:'Trevor Family',80:'Jewelry Heist',82:'Drag Race Finish',84:'Rampage',
        85:'Vinewood Tours',86:'Lamar Family',88:'Franklin Family',89:'Chinese Strand',
        90:'Flight School',91:'Eye Sky',92:'Air Hockey',93:'Bar',94:'Base Jump',
        95:'Basketball',96:'Biolab Heist',99:'Cabaret Club',100:'Car Wash',
        102:'Comedy Club',103:'Darts',104:'Docks Heist',105:'FBI Heist',
        106:'FBI Officers Strand',107:'Finale Bank Heist',108:'Financier Strand',
        109:'Golf',110:'Gun Shop',111:'Internet Cafe',112:'Michael Family Exile',
        113:'Nice House Heist',114:'Random Female',115:'Random Male',
        118:'Rural Bank Heist',119:'Shooting Range',120:'Solomon Strand',
        121:'Strip Club',122:'Tennis',123:'Trevor Family Exile',124:'Michael Trevor Family',
        126:'Triathlon',127:'Off Road Racing',128:'Gang Cops',129:'Gang Mexicans',
        130:'Gang Bikers',133:'Snitch Red',134:'Crim Cuff Keys',135:'Cinema',
        136:'Music Venue',137:'Police Station Blue',138:'Airport',
        139:'Crim Saved Vehicle',140:'Weed Stash',141:'Hunting',142:'Pool',
        143:'Objective Blue',144:'Objective Green',145:'Objective Red',146:'Objective Yellow',
        147:'Arms Dealing',148:'MP Friend',149:'Celebrity Theft',
        150:'Weapon Assault Rifle',151:'Weapon Bat',152:'Weapon Grenade',
        153:'Weapon Health',154:'Weapon Knife',155:'Weapon Molotov',
        156:'Weapon Pistol',157:'Weapon Rocket',158:'Weapon Shotgun',159:'Weapon SMG',
        160:'Weapon Sniper',161:'MP Noise',162:'POI',163:'Passive',164:'Using Menu',
        171:'Gang Cops Partner',173:'Weapon Minigun',175:'Weapon Armour',
        176:'Property Takeover',177:'Gang Mexicans Highlight',178:'Gang Bikers Highlight',
        179:'Triathlon Cycling',180:'Triathlon Swimming',181:'Property Takeover Bikers',
        182:'Property Takeover Cops',183:'Property Takeover Vagos',184:'Camera',
        185:'Centre Red',186:'Handcuff Keys Bikers',187:'Handcuff Keys Vagos',
        188:'Handcuffs Closed Bikers',189:'Handcuffs Closed Vagos',
        192:'Camera Badger',193:'Camera Facade',194:'Camera iFruit',197:'Yoga',
        198:'Taxi',205:'Shrink',206:'Epsilon',207:'Financier Strand Grey',
        208:'Trevor Family Grey',209:'Trevor Family Red',210:'Franklin Family Grey',
        211:'Franklin Family Blue',212:'Franklin A',213:'Franklin B',214:'Franklin C',
        225:'Gang Vehicle',226:'Gang Vehicle Bikers',227:'Gang Vehicle Cops',
        228:'Gang Vehicle Vagos',229:'Guncar',230:'Driving Bikers',231:'Driving Cops',
        232:'Driving Vagos',233:'Gang Cops Highlight',234:'Shield Bikers',
        235:'Shield Cops',236:'Shield Vagos',237:'Custody Bikers',238:'Custody Vagos',
        251:'Arms Dealing Air',252:'Playerstate Arrested',253:'Playerstate Custody',
        254:'Playerstate Driving',255:'Playerstate Keyholder',256:'Playerstate Partner',
        262:'Ztype',263:'Stinger',264:'Packer',265:'Monroe',266:'Fairground',
        267:'Property',268:'Gang Highlight',269:'Altruist',270:'AI',271:'On Mission',
        272:'Cash Pickup',273:'Chop',274:'Dead',275:'Territory Locked',
        276:'Cash Lost',277:'Cash Vagos',278:'Cash Cops',279:'Hooker',280:'Friend',
        281:'Mission 2to4',282:'Mission 2to8',283:'Mission 2to12',284:'Mission 2to16',
        285:'Custody Dropoff',286:'Onmission Cops',287:'Onmission Lost',
        288:'Onmission Vagos',289:'Crim Carsteal Cops',290:'Crim Carsteal Bikers',
        291:'Crim Carsteal Vagos',292:'Band Strand',293:'Simeon Family',
        294:'Mission 1',295:'Mission 2',296:'Friend Darts',297:'Friend Comedyclub',
        298:'Friend Cinema',299:'Friend Tennis',300:'Friend Stripclub',
        301:'Friend Livemusic',302:'Friend Golf',303:'Bounty Hit',304:'UGC Mission',
        305:'Horde',306:'Crate Drop',307:'Plane Drop',308:'Sub',309:'Race',
        310:'Deathmatch',311:'Arm Wrestling',312:'Mission 1to2',
        313:'Shootingrange Gunshop',314:'Race Air',315:'Race Land',316:'Race Sea',
        317:'Tow',318:'Garbage',319:'Drill',320:'Spikes',321:'Firetruck',
        322:'Minigun 2',323:'Bugstar',324:'Submarine',325:'Chinook',
        326:'Getaway Car',327:'Mission Bikers 1',328:'Mission Bikers 1to2',
        329:'Mission Bikers 2',330:'Mission Bikers 2to4',331:'Mission Bikers 2to8',
        332:'Mission Bikers 2to12',333:'Mission Bikers 2to16',334:'Mission Cops 1',
        335:'Mission Cops 1to2',336:'Mission Cops 2',337:'Mission Cops 2to4',
        338:'Mission Cops 2to8',339:'Mission Cops 2to12',340:'Mission Cops 2to16',
        341:'Mission Vagos 1',342:'Mission Vagos 1to2',343:'Mission Vagos 2',
        344:'Mission Vagos 2to4',345:'Mission Vagos 2to8',346:'Mission Vagos 2to12',
        347:'Mission Vagos 2to16',348:'Gang Bike',349:'Gas Grenade',
        350:'Property For Sale',351:'Gang Attack Package',352:'Martin Madrazzo',
        353:'Enemy Heli Spin',354:'Boost',355:'Devin',356:'Dock',357:'Garage',
        358:'Golf Flag',359:'Hangar',360:'Helipad',361:'Jerry Can',362:'Mask',
        363:'Heist Prep',364:'Incapacitated',365:'Spawn Point Pickup',366:'Boilersuit',
        367:'Completed',368:'Rockets',369:'Garage For Sale',370:'Helipad For Sale',
        371:'Dock For Sale',372:'Hangar For Sale',373:'Placeholder 6',
        374:'Business',375:'Business For Sale',376:'Race Bike',377:'Parachute',
        378:'Team Deathmatch',379:'Race Foot',380:'Vehicle Deathmatch',381:'Barry',
        382:'Dom',383:'Maryann',384:'Cletus',385:'Josh',386:'Minute',387:'Omega',
        388:'Tonya',389:'Paparazzo',390:'Aim',391:'Cratedrop Background',
        392:'Green And Net Player1',393:'Green And Net Player2',
        394:'Green And Net Player3',395:'Green And Friendly',
        396:'Net Player1 And Net Player2',397:'Net Player1 And Net Player3',
        398:'Creator',399:'Creator Direction',400:'Abigail',401:'Blimp',
        402:'Repair',403:'Testosterone',404:'Dinghy',405:'Fanatic',406:'Info Icon',
        407:'Capture The Flag',408:'Last Team Standing',409:'Boat',
        410:'Capture The Flag Base',412:'Capture The Flag Outline',
        413:'Capture The Flag Base Nobag',414:'Weapon Jerrycan',415:'RP',
        416:'Level Inside',417:'Bounty Hit Inside',418:'Capture The USAFlag',
        419:'Capture The USAFlag Outline',420:'Tank',421:'Player Heli',
        422:'Player Plane',423:'Player Jet',424:'Centre Stroke',425:'Player Guncar',
        426:'Player Boat',427:'MP Heist',428:'Temp 1',429:'Temp 2',430:'Temp 3',
        431:'Temp 4',432:'Temp 5',433:'Temp 6',434:'Race Stunt',435:'Hot Property',
        436:'Urbanwarfare Versus',437:'King Of The Castle',438:'Player King',
        439:'Dead Drop',440:'Penned In',441:'Beast',442:'Edge Pointer',
        443:'Edge Crosstheline',444:'MP Lamar',445:'Bennys',446:'Corner Number 1',
        447:'Corner Number 2',448:'Corner Number 3',449:'Corner Number 4',
        450:'Corner Number 5',451:'Corner Number 6',452:'Corner Number 7',
        453:'Corner Number 8',454:'Yacht',455:'Finders Keepers',
        456:'Assault Package',457:'Hunt The Boss',458:'Sightseer',
        459:'Turreted Limo',460:'Belly Of The Beast',461:'Yacht Location',
        462:'Pickup Beast',463:'Pickup Zoned',464:'Pickup Random',
        465:'Pickup Slow Time',466:'Pickup Swap',467:'Pickup Thermal',
        468:'Pickup Weed',469:'Weapon Railgun',470:'Seashark',471:'Pickup Hidden',
        472:'Warehouse',473:'Warehouse For Sale',474:'Office',475:'Office For Sale',
        476:'Truck',477:'Contraband',478:'Trailer',479:'VIP',480:'Cargobob',
        481:'Area Outline Blip',482:'Pickup Accelerator',483:'Pickup Ghost',
        484:'Pickup Detonator',485:'Pickup Bomb',486:'Pickup Armoured',487:'Stunt',
        488:'Weapon Lives',489:'Stunt Premium',490:'Adversary',491:'Biker Clubhouse',
        492:'Biker Caged In',493:'Biker Turf War',494:'Biker Joust',
        495:'Production Weed',496:'Production Crack',497:'Production Fake ID',
        498:'Production Meth',499:'Production Money',500:'Package',
        501:'Capture 1',502:'Capture 2',503:'Capture 3',504:'Capture 4',
        505:'Capture 5',506:'Capture 6',507:'Capture 7',508:'Capture 8',
        509:'Capture 9',510:'Capture 10',511:'Quad',512:'Bus',513:'Drugs Package',
        514:'Pickup Jump',515:'Adversary 4',516:'Adversary 8',517:'Adversary 10',
        518:'Adversary 12',519:'Adversary 16',520:'Laptop',521:'Pickup Deadline',
        522:'Sports Car',523:'Warehouse Vehicle',524:'Reg Papers',
        525:'Police Station Dropoff',526:'Junkyard',527:'Ex Vech 1',528:'Ex Vech 2',
        529:'Ex Vech 3',530:'Ex Vech 4',531:'Ex Vech 5',532:'Ex Vech 6',
        533:'Ex Vech 7',534:'Target A',535:'Target B',536:'Target C',537:'Target D',
        538:'Target E',539:'Target F',540:'Target G',541:'Target H',542:'Jugg',
        543:'Pickup Repair',544:'Steeringwheel',545:'Trophy',
        546:'Pickup Rocket Boost',547:'Pickup Homing Rocket',
        548:'Pickup Machinegun',549:'Pickup Parachute',550:'Pickup Time 5',
        551:'Pickup Time 10',552:'Pickup Time 15',553:'Pickup Time 20',
        554:'Pickup Time 30',555:'Supplies',556:'Property Bunker',
        557:'GR WVM 1',558:'GR WVM 2',559:'GR WVM 3',560:'GR WVM 4',
        561:'GR WVM 5',562:'GR WVM 6',563:'GR Covert Ops',564:'Adversary Bunker',
        565:'GR MOC Upgrade',566:'GR W Upgrade',567:'SM Cargo',568:'SM Hangar',
        569:'TF Checkpoint',570:'Race TF',571:'SM WP1',572:'SM WP2',573:'SM WP3',
        574:'SM WP4',575:'SM WP5',576:'SM WP6',577:'SM WP7',578:'SM WP8',
        579:'SM WP9',580:'SM WP10',581:'SM WP11',582:'SM WP12',583:'SM WP13',
        584:'SM WP14',585:'NHP Bag',586:'NHP Chest',587:'NHP Orbit',
        588:'NHP Veh1',589:'NHP Base',590:'NHP Overlay',591:'NHP Turret',
        592:'NHP MG Firewall',593:'NHP MG Node',594:'NHP WP1',595:'NHP WP2',
        596:'NHP WP3',597:'NHP WP4',598:'NHP WP5',599:'NHP WP6',600:'NHP WP7',
        601:'NHP WP8',602:'NHP WP9',603:'NHP CCTV',604:'NHP Starterpack',
        605:'NHP Turret Console',606:'NHP MG Mir Rotate',607:'NHP MG Mir Static',
        608:'NHP MG Proxy',609:'ACSR Race Target',610:'ACSR Race Hotring',
        611:'ACSR WP1',612:'ACSR WP2',613:'BAT Club Property',614:'BAT Cargo',
        615:'BAT Truck',616:'BAT Hack Jewel',617:'BAT Hack Gold',
        618:'BAT Keypad',619:'BAT Hack Target',620:'Pickup DTB Health',
        621:'Pickup DTB Blast Increase',622:'Pickup DTB Blast Decrease',
        623:'Pickup DTB Bomb Increase',624:'Pickup DTB Bomb Decrease',
        625:'BAT Rival Club',626:'BAT Drone',627:'BAT Cash Reg',628:'CCTV',
        629:'BAT Assassinate',630:'BAT PBus',631:'BAT WP1',632:'BAT WP2',
        633:'BAT WP3',634:'BAT WP4',635:'BAT WP5',636:'BAT WP6',637:'BAT WP7',
        638:'Blimp 2',639:'Oppressor 2',640:'BAT WP7',641:'Arena Series',
        642:'Arena Premium',643:'Arena Workshop',644:'Race Wars',645:'Arena Turret',
        646:'Arena RC Car',647:'Arena RC Workshop',648:'Arena Trap Fire',
        649:'Arena Trap Flip',650:'Arena Trap Sea',651:'Arena Trap Turn',
        652:'Arena Trap Pit',653:'Arena Trap Mine',654:'Arena Trap Bomb',
        655:'Arena Trap Wall',656:'Arena Trap Brd',657:'Arena Trap SBrd',
        658:'Arena Bruiser',659:'Arena Brutus',660:'Arena Cerberus',
        661:'Arena Deathbike',662:'Arena Dominator',663:'Arena Impaler',
        664:'Arena Imperator',665:'Arena Issi',666:'Arena Sasquatch',
        667:'Arena Scarab',668:'Arena Slamvan',669:'Arena ZR380',670:'AP',
        671:'Comic Store',672:'Cop Car',673:'RC Time Trials',
        674:'King Of The Hill',675:'King Of The Hill Teams',676:'Rucksack',
        677:'Shipping Container',678:'Agatha',679:'Casino',
        680:'Casino Table Games',681:'Casino Wheel',682:'Casino Concierge',
        683:'Casino Chips',684:'Casino Horse Racing',685:'Adversary Featured',
        686:'Roulette 1',687:'Roulette 2',688:'Roulette 3',689:'Roulette 4',
        690:'Roulette 5',691:'Roulette 6',692:'Roulette 7',693:'Roulette 8',
        694:'Roulette 9',695:'Roulette 10',696:'Roulette 11',697:'Roulette 12',
        698:'Roulette 13',699:'Roulette 14',700:'Roulette 15',701:'Roulette 16',
        702:'Roulette 17',703:'Roulette 18',704:'Roulette 19',705:'Roulette 20',
        706:'Roulette 21',707:'Roulette 22',708:'Roulette 23',709:'Roulette 24',
        710:'Roulette 25',711:'Roulette 26',712:'Roulette 27',713:'Roulette 28',
        714:'Roulette 29',715:'Roulette 30',716:'Roulette 31',717:'Roulette 32',
        718:'Roulette 33',719:'Roulette 34',720:'Roulette 35',721:'Roulette 36',
        722:'Roulette 0',723:'Roulette 00',724:'Limo',725:'Weapon Alien',
        726:'Race Open Wheel',727:'Rappel',728:'Swap Car',729:'Scuba Gear',
        730:'CPanel 1',731:'CPanel 2',732:'CPanel 3',733:'CPanel 4',
        734:'Snow Truck',735:'Buggy 1',736:'Buggy 2',737:'Zhaba',738:'Gerald',
        739:'Ron',740:'Arcade',741:'Drone Controls',742:'RC Tank',743:'Stairs',
        744:'Camera 2',745:'Winky',746:'Mini Sub',747:'Kart Retro',
        748:'Kart Modern',749:'Military Quad',750:'Military Truck',
        751:'Ship Wheel',752:'UFO',753:'Seasparrow 2',754:'Dinghy 2',
        755:'Patrol Boat',756:'Retro Sports Car',757:'Squadee',
        758:'Folding Wing Jet',759:'Valkyrie 2',760:'Sub 2',
        761:'Bolt Cutters',762:'Rappel Gear',763:'Keycard',764:'Password',
        765:'Island Heist Prep',766:'Island Party',767:'Control Tower',
        768:'Underwater Gate',769:'Power Switch',770:'Compound Gate',
        771:'Rappel Point',772:'Keypad',773:'Sub Controls',774:'Sub Periscope',
        775:'Sub Missile',776:'Painting',777:'Car Meet',778:'Car Test Area',
        779:'Auto Shop Property',780:'Docks Export',781:'Prize Car',
        782:'Test Car',783:'Car Robbery Board',784:'Car Robbery Prep',
        785:'Street Race Series',786:'Pursuit Series',787:'Car Meet Organiser',
        788:'Securoserv',789:'Bounty Collectibles',790:'Movie Collectibles',
        791:'Trailer Ramp',792:'Race Organiser',793:'Chalkboard List',
        794:'Export Vehicle',795:'Train',796:'Heist Diamond',797:'Heist Doomsday',
        798:'Heist Island',799:'Slamvan 2',800:'Crusader',801:'Construction Outfit',
        802:'Overlay Jammed',803:'Heist Island Unavailable',
        804:'Heist Diamond Unavailable',805:'Heist Doomsday Unavailable',
        806:'Placeholder 7',807:'Placeholder 8',808:'Placeholder 9',
        809:'Featured Series',810:'Vehicle For Sale',811:'Van Keys',
        812:'SUV Service',813:'Security Contract',814:'Safe',815:'Ped R',
        816:'Ped E',817:'Payphone',818:'Patriot 3',819:'Music Studio',
        820:'Jubilee',821:'Granger 2',822:'Explosive Charge',823:'Deity',
        824:'D Champion',825:'Buffalo 4',826:'Agency',827:'Biker Bar',
        828:'Simeon Overlay',829:'Junk Skydive',830:'Luxury Car Showroom',
        831:'Car Showroom',832:'Car Showroom Simeon',833:'Flaming Skull',
        834:'Weapon Ammo',835:'Community Series',836:'Cayo Series',
        837:'Clubhouse Contract',838:'Agent ULP',839:'Acid',840:'Acid Lab',
        841:'Dax Overlay',842:'Dead Drop Package',843:'Downtown Cab',
        844:'Gun Van',845:'Stash House',846:'Tractor',
        847:'Warehouse Juggalo',848:'Warehouse Juggalo Dax',849:'Weapon Crowbar',
        850:'Duffel Bag',851:'Oil Tanker',852:'Acid Lab Tent',
        853:'Van Burrito',854:'Acid Boost',855:'Ped Gang Leader',
        856:'Multistorey Garage',857:'Seized Asset Sales',858:'Cayo Attrition',
        859:'Bicycle',860:'Bicycle Trial',861:'Raiju',862:'Conada 2',
        863:'Overlay Ready For Sell',864:'Overlay Missing Supplies',
        865:'Streamer 216',866:'Signal Jammer',867:'Salvage Yard',
        868:'Robbery Prep Equipment',869:'Robbery Prep Overlay',870:'Yusuf',
        871:'Vincent',872:'Vinewood Garage',873:'LSTB',874:'CCTV Workstation',
        875:'Hacking Device',876:'Race Drag',877:'Race Drift',
        878:'Casino Prep',879:'Planning Wall',880:'Weapon Crate',
        881:'Weapon Snowball',882:'Train Signals Green',883:'Train Signals Red',
        884:'Office Transporter',885:'Yankton Survival',886:'Daily Bounty',
        887:'Bounty Target',888:'Filming Schedule',889:'Pizza This',
        890:'Aircraft Carrier',891:'Weapon EMP',892:'Maude Eccles',
        893:'Bail Bonds Office',894:'Weapon EMP Mine',895:'Zombie Disease',
        896:'Zombie Proximity',897:'Zombie Fire',898:'Animal Possessed',
        899:'Mobile Phone',900:'Garment Factory',901:'Garment Factory For Sale',
        902:'Garment Factory Equipment',903:'Field Hangar',
        904:'Field Hangar For Sale',905:'Cargobob CH53',
        906:'Chopper Lift Ammo',907:'Chopper Lift Armor',
        908:'Chopper Lift Explosives',909:'Chopper Lift Upgrade',
        910:'Chopper Lift Weapon',911:'Cargo Ship',912:'Submarine Missile',
        913:'Propeller Engine',914:'Shark',915:'Fast Travel',
        916:'Plane Duster 2',917:'Plane Titan 2',918:'Collectible',
        919:'Field Hangar Discount',920:'Garment Factory Discount',
        921:'Weapon Gusenberg Sweeper',922:'Weapon Tear Gas',923:'Dog',
        924:'Bobcat Security',925:'Smoke Shop',926:'Smoke Shop For Sale',
        927:'Smoke Shop Attention',928:'Helitours',929:'Helitours For Sale',
        930:'Helitours Attention',931:'Car Wash Business',
        932:'Car Wash Business For Sale',933:'Car Wash Business Attention',
        934:'Attention',935:'Alarm',936:'Helitours Discount',
        937:'Smoke Shop Discount',938:'Car Wash Business Discount',
        939:'Real Estate',940:'Medical Courier',941:'Gruppe Sechs',
        942:'Fire Station',943:'Fire Truck',944:'Alpha Mail',945:'LS Meteor',
        946:'Four20 Survival',947:'Community Mission Series',
        948:'Property Mansion',949:'AI Keypad',950:'Taxi Self Drive',
        951:'Train Subway',952:'Trashbag',953:'Mission Creator',954:'Cat',
        955:'Mansion AI M',956:'Mansion AI F',957:'Mansion AI Gang'
    };

    const ZONE_BLIP_SPRITES=Object.keys(ZONE_BLIP_NAMES)
        .map(id=>({id:Number(id),name:ZONE_BLIP_NAMES[id]}))
        .sort((a,b)=>a.id-b.id);

    const ZONE_BLIP_COLORS=[
        {id:0,name:'White',hex:'#ffffff'},
        {id:1,name:'Red',hex:'#f97373'},
        {id:2,name:'Green',hex:'#4ade80'},
        {id:3,name:'Blue',hex:'#60a5fa'},
        {id:4,name:'Light Blue',hex:'#93c5fd'},
        {id:5,name:'Yellow',hex:'#facc15'},
        {id:7,name:'Orange',hex:'#fb923c'},
        {id:11,name:'Cyan',hex:'#22d3ee'},
        {id:27,name:'Purple',hex:'#a855f7'},
        {id:29,name:'Pink',hex:'#f472b6'},
        {id:30,name:'Brown',hex:'#92400e'},
        {id:38,name:'Grey',hex:'#9ca3af'},
        {id:57,name:'Dark Red',hex:'#b91c1c'},
        {id:6,name:'Dark Blue',hex:'#1e40af'},
        {id:10,name:'Light Green',hex:'#86efac'},
        {id:12,name:'Dark Green',hex:'#14532d'},
        {id:13,name:'Olive',hex:'#65a30d'},
        {id:14,name:'Dark Brown',hex:'#451a03'},
        {id:15,name:'Dark Orange',hex:'#9a3412'},
        {id:16,name:'Light Orange',hex:'#fdba74'},
        {id:31,name:'Dark Grey',hex:'#374151'},
        {id:32,name:'Light Grey',hex:'#d1d5db'},
        {id:39,name:'Dark Green 2',hex:'#064e3b'}
    ];

    function setZoneBlipSpriteUi(value){
        if(!zoneBlipSpriteList) return;
        const valStr=value!=null?String(value):'';
        zoneBlipSpriteList.querySelectorAll('.zones-blip-sprite-item').forEach(row=>{
            row.classList.toggle('active',row.dataset.value===valStr && valStr!=='');
        });
    }

    function setZoneBlipColorUi(value){
        if(!zoneBlipColorList) return;
        const valStr=value!=null?String(value):'';
        zoneBlipColorList.querySelectorAll('.zones-blip-color-item').forEach(row=>{
            row.classList.toggle('active',row.dataset.value===valStr && valStr!=='');
        });
    }

    function initZoneBlipPickers(){
        if(zoneBlipSpriteList){
            zoneBlipSpriteList.innerHTML='';
            ZONE_BLIP_SPRITES.forEach(s=>{
                const row=document.createElement('div');
                row.className='zones-blip-item zones-blip-sprite-item';
                row.dataset.value=String(s.id);

                const idSpan=document.createElement('span');
                idSpan.className='blip-id';
                idSpan.textContent=s.id;
                row.appendChild(idSpan);

                const nameSpan=document.createElement('span');
                nameSpan.textContent=s.name;
                row.appendChild(nameSpan);
                row.title=`${s.name} (${s.id})`;
                row.onclick=()=>{
                    if(zoneBlipSpriteSel) zoneBlipSpriteSel.value=String(s.id);
                    setZoneBlipSpriteUi(s.id);
                };
                zoneBlipSpriteList.appendChild(row);
            });
            const spriteSpacer=document.createElement('div');
            spriteSpacer.className='zones-blip-item zones-blip-spacer';
            zoneBlipSpriteList.appendChild(spriteSpacer);
        }
        if(zoneBlipSpriteSel){
            zoneBlipSpriteSel.addEventListener('input',function(){
                const v=parseInt(this.value,10);
                if(!isNaN(v)) setZoneBlipSpriteUi(v);
            });
        }
        if(zoneBlipColorList){
            zoneBlipColorList.innerHTML='';
            ZONE_BLIP_COLORS.forEach(c=>{
                const row=document.createElement('div');
                row.className='zones-blip-item zones-blip-color-item';
                row.dataset.value=String(c.id);
                const dot=document.createElement('span');
                dot.className='zones-color-dot';
                if(c.hex) dot.style.backgroundColor=c.hex;
                row.appendChild(dot);
                const label=document.createElement('span');
                label.textContent=`${c.name} (${c.id})`;
                row.appendChild(label);
                row.onclick=()=>{
                    if(zoneBlipColorSel) zoneBlipColorSel.value=String(c.id);
                    setZoneBlipColorUi(c.id);
                };
                zoneBlipColorList.appendChild(row);
            });
            const colorSpacer=document.createElement('div');
            colorSpacer.className='zones-blip-item zones-blip-spacer';
            zoneBlipColorList.appendChild(colorSpacer);
        }

        if(zoneBlipSpriteSel && zoneBlipSpriteSel.value){
            setZoneBlipSpriteUi(zoneBlipSpriteSel.value);
        }
        if(zoneBlipColorSel && zoneBlipColorSel.value){
            setZoneBlipColorUi(zoneBlipColorSel.value);
        }
    }

    function resetZoneForm(){
        currentZoneId=null;
        const typeSel=document.getElementById('zone-type');
        if(typeSel) typeSel.value='custom';
        const nameInput=document.getElementById('zone-name');
        if(nameInput) nameInput.value='';
        const rInput=document.getElementById('zone-radius');
        if(rInput) rInput.value='';
        const spdInput=document.getElementById('zone-maxspd');
        if(spdInput) spdInput.value='';
        const invCb=document.getElementById('zone-inv');
        if(invCb) invCb.checked=false;
        const disCb=document.getElementById('zone-disarm');
        if(disCb) disCb.checked=false;
        const blipCb=document.getElementById('zone-blip');
        if(blipCb) blipCb.checked=false;
        const jobInput=document.getElementById('zone-job');
        if(jobInput) jobInput.value='';
        const startInput=document.getElementById('zone-start');
        if(startInput) startInput.value='';
        const endInput=document.getElementById('zone-end');
        if(endInput) endInput.value='';
        if(zoneBlipSpriteSel) zoneBlipSpriteSel.value='';
        if(zoneBlipColorSel) zoneBlipColorSel.value='';
        setZoneBlipSpriteUi(null);
        setZoneBlipColorUi(null);
        const btn=document.getElementById('zone-create');
        if(btn) btn.textContent='Create';
    }

    function initZonesUi(){
        initZoneBlipPickers();
        const zoneResetBtn=document.getElementById('zone-reset');
        if(zoneResetBtn){
            zoneResetBtn.onclick=()=>{
                resetZoneForm();
            };
        }

        const createBtn=document.getElementById('zone-create');
        if(createBtn){
            createBtn.onclick=()=>{
                const typeSel=document.getElementById('zone-type');
                const typeValue=typeSel?typeSel.value:'custom';
                let name=document.getElementById('zone-name').value||'Zone';
                let radius=parseFloat(document.getElementById('zone-radius').value||'50');
                let maxspd=parseFloat(document.getElementById('zone-maxspd').value||'0');
                let inv=document.getElementById('zone-inv').checked;
                let disarm=document.getElementById('zone-disarm').checked;

                if(typeValue==='safe'){
                    inv=true;
                    disarm=true;
                    if(!name || name==='Zone') name='Safe Zone';
                }else if(typeValue==='speed'){
                    if(!maxspd || maxspd<=0) maxspd=60;
                }else if(typeValue==='restricted'){
                    disarm=true;
                }

                const rawJob=(document.getElementById('zone-job').value||'').trim();
                const startStr=document.getElementById('zone-start').value||'';
                const endStr=document.getElementById('zone-end').value||'';
                const start=startStr!==''?parseInt(startStr,10):null;
                const stop=endStr!==''?parseInt(endStr,10):null;

                let blipSprite=null;
                let blipColor=null;
                if(zoneBlipSpriteSel && zoneBlipSpriteSel.value!==''){
                    blipSprite=parseInt(zoneBlipSpriteSel.value,10);
                }
                if(zoneBlipColorSel && zoneBlipColorSel.value!==''){
                    blipColor=parseInt(zoneBlipColorSel.value,10);
                }

                const payload={
                    a: currentZoneId ? 'update' : 'create',
                    type:typeValue,
                    name:name,
                    r:radius,
                    maxspd:maxspd,
                    inv:inv,
                    disarm:disarm,
                    blip:document.getElementById('zone-blip').checked,
                    blipSprite:blipSprite,
                    blipColor:blipColor,
                    job:rawJob,
                    start:start,
                    stop:stop
                };
                if(currentZoneId) payload.id=currentZoneId;
                cb('zone',payload);

                resetZoneForm();
            };
        }
    }

    function renderZonesFromMessage(d){
        if(!zonesDiv) return;
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
                jobsText=' jobs: '+z.jobs.join(',');
            }else if(z.job && z.job!==''){
                jobsText=` job:${z.job}`;
            }
            const blipText=z.blip?' [blip]':'';
            const typeText=z.type && z.type!=='custom'?` [${z.type}]`:'';
            let timeText='';
            if(typeof z.start==='number' && typeof z.stop==='number'){
                timeText=` [${z.start}-${z.stop}h]`;
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

    // public API
    window.OxoZones={
        initZonesUi,
        renderZonesFromMessage
    };

    // auto-init when script loads
    initZonesUi();
})();
