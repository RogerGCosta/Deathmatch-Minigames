/*
	Deathmatch Mini Games
		por Roger Costa
		
		
	Minigame:       A Fábrica
	Tipo: 			Attack and Defense
	Idéia por: 		Roger Costa
	Script por: 	Roger Costa
	Mapa por:       Não tem Mapa
	
	- Explicação -
	O minigame é composto por 2 equipes: FBI (Ataque) e Traficantes (Defesa)
	O objetivo é a equipe FBI capturar o checkpoint na base dos Traficantes,
	e os mesmo impedir isso matando todos da equipe do FBI!


	- Atenção -
	Não remova nada do esboço do gamemode padrão, é de extrema importância
	que todos as variáveis, arrays, funções, etc.. estejam com os mesmos nomes
	pra uma melhor organização do servidor e para não ocorrer problemas.
	
	
	Roger Costa
	    CEO RSCo - Roger Soluctions Company
	
	Este servidor faz parte da divisão GAMES >> SA-MP.
*/

//#define USE_WEAPON_CONFIG

#include 									<a_samp>
#include    								<SII>
#if defined USE_WEAPON_CONFIG
	#include                                <weapon-config>
	#include                                <SKY>
#endif
#include                                    <sscanf2>
#include    								<DeathMinigames/AAD.inc>

// Definições sobre o Minigame
#define MG_NAME                         	"A Fabrica"
#define MG_IDEA                         	"NikO"
#define MG_SCRIPT                       	"NikO"
#define MG_MAP                       		"NikO"
#define MG_STYLE                        	"Attack/Defense"

#undef TYPE_MINIGAME
	#define TYPE_MINIGAME                	MINIGAME_AAD

// Tempo para captura do Checkpoint
#undef AAD_CHECKPOINT_TIME
	#define AAD_CHECKPOINT_TIME             20

// Base Checkpoint
#define CHECKPOINT_X                        -2184.4380
#define CHECKPOINT_Y                        -262.4561
#define CHECKPOINT_Z                        40.7195

// Definições dos Times
#define TEAMS                               2

// Nome da Equipe 1
#define TEAM_ONE_NAME           			"Policia"
#define TEAM_ONE_NAME_ENG           		"Police"
// Nome da Equipe 2
#define TEAM_TWO_NAME           			"Traficantes"
#define TEAM_TWO_NAME_ENG          			"Drug Dealers"
// Cor da Equipe 1
#define TEAM_ONE_COLOR                      COLOR_BLUE
// Cor da Equipe 2
#define TEAM_TWO_COLOR                      COLOR_RED
// Skins da Equipe 1 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_ONE_SKIN_ID                    265, 266, 267, 280, 281, 286, 285
// Skins da Equipe 2 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_TWO_SKIN_ID                    145, 146

// Armas da Equipe 1 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_ONE_WEAPONS_IDS
	#define TEAM_ONE_WEAPONS_IDS            24, 25, 33
// Armas da Equipe 2 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_TWO_WEAPONS_IDS
	#define TEAM_TWO_WEAPONS_IDS            24, 25, 33
	
#define TEAM_ONE_SPAWN_INTERIOR             0
#define TEAM_TWO_SPAWN_INTERIOR             0

// Definições para o Radar e TagNames
#define HIDE_ALL                 			0
#define ONLY_TEAM                           1
#define SHOW_ALL                            2
#define DMG_MARKER_TYPE                     ONLY_TEAM
#define DMG_TAGNAME_TYPE                    SHOW_ALL

#define MINIGAME_WEATHER                	6
#define MINIGAME_HOUR                   	13

#define PlayerLang(%0)     					GetPVarInt(%0, "PlayerLang")
#define PlayerStatus(%0)    				GetPVarInt(%0, "PlayerStatus")
#define LoopPlayer(%0)    					for(new %0 = 0, k = GetPlayerPoolSize(); %0 <= k; %0++)

forward OneSecondUpdate();
forward CheckPointTimer();

new Float:TEAM_SPAWN[TEAMS][4] =
{
	{-1630.7030, 689.5757, 7.1875, 184.6310},      // Ataque Spawn
	{-2151.6899, -244.8481, 36.5156, 1.1807}       	// Defesa Spawn
};

new const TeamObjective[TEAMS][128] =
{
	{"~y~Objetivo: ~w~Elimine todos os traficantes ou capture o Checkpoint!"},
	{"~y~Objetivo: ~w~Defenda o checkpoint contra a Policia!"}
};

new const TeamObjectiveEng[TEAMS][128] =
{
	{"~y~Objetivo: ~w~Elimine all drug dealers or capture checkpoint!"},
	{"~y~Objetivo: ~w~Defend against the police checkpoint!"}
};

new const TeamMessage[TEAMS][] =
{
	{"Capture o checkpoint para destruir~n~o laboratorio de drogas dos traficantes!"},
	{"Proteja o laboratorio e nao deixe~n~que a Policia acabe com tudo!"}
};

new const TeamMessageEng[TEAMS][] =
{
	{"Capture the checkpoint to destruct drug labs!"},
	{"Protect the lab and do not let the police destroy everything!"}
};

new TEAM_ONE_WEAPONS[] = { TEAM_ONE_WEAPONS_IDS };
new TEAM_TWO_WEAPONS[] = { TEAM_TWO_WEAPONS_IDS };
new SKINS_TEAM_ONE[] = { TEAM_ONE_SKIN_ID };
new SKINS_TEAM_TWO[] = { TEAM_TWO_SKIN_ID };
new GANGZONE;
new Float:MIN_COORDS[8] = { 0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.25 };
new AF_Objects[67];
new AF_Vehicles[20];
new WaitingTimer, SecondTimer;

public OnFilterScriptInit()
{
    SetGameModeText(MG_NAME);
    
    SetSVarString("AttMessageBox", TeamMessage[ATTACK]);
    SetSVarString("DefMessageBox", TeamMessage[DEFENSE]);
    SetSVarString("AttObjective", TeamObjective[ATTACK]);
    SetSVarString("DefObjective", TeamObjective[DEFENSE]);

    SetSVarString("AttMessageBoxEng", TeamMessageEng[ATTACK]);
    SetSVarString("DefMessageBoxEng", TeamMessageEng[DEFENSE]);
    SetSVarString("AttObjectiveEng", TeamObjectiveEng[ATTACK]);
    SetSVarString("DefObjectiveEng", TeamObjectiveEng[DEFENSE]);
	
	SetSVarInt("MinigameType", TYPE_MINIGAME);
	SetSVarString("MinigameName", MG_NAME);
	SetSVarString("MinigameIdea", MG_IDEA);
	SetSVarString("MinigameScript", MG_SCRIPT);
	SetSVarString("MinigameMap", MG_MAP);
	SetSVarString("MinigameStyle", MG_STYLE);
	
	SetSVarInt("MarkerType", DMG_TAGNAME_TYPE);
	
	// Equipes
	SetSVarString("TeamOneName", TEAM_ONE_NAME);
	SetSVarString("TeamTwoName", TEAM_TWO_NAME);
	SetSVarString("TeamOneNameEng", TEAM_ONE_NAME_ENG);
	SetSVarString("TeamTwoNameEng", TEAM_TWO_NAME_ENG);
	
	SendRconCommand("loadfs DataAAD");
	
	SetWeather(MINIGAME_WEATHER);
	SetWorldTime(MINIGAME_HOUR);

    SetSVarInt("CheckpointTime", AAD_CHECKPOINT_TIME);
	SetSVarFloat("CheckpointPosX", CHECKPOINT_X);
	SetSVarFloat("CheckpointPosY", CHECKPOINT_Y);
	SetSVarFloat("CheckpointPosZ", CHECKPOINT_Z);
	
	SetSVarFloat("AttPosX", TEAM_SPAWN[0][0]);
	SetSVarFloat("AttPosY", TEAM_SPAWN[0][1]);
	SetSVarFloat("AttPosZ", TEAM_SPAWN[0][2]);
	
	CreateMinigameObjects();
	CreateMinigameVehicles();
	
	GANGZONE = GangZoneCreate(GetSVarFloat("CheckpointPosX")-50, GetSVarFloat("CheckpointPosY")-50, GetSVarFloat("CheckpointPosX")+50, GetSVarFloat("CheckpointPosY")+50);
	
	WaitingTimer = SetTimer("WaitingPlayers", 1000, false);
	SecondTimer = SetTimer("OneSecondUpdate", 1000, true);
	
	return true;
}

public OnFilterScriptExit()
{
	DeleteMinigameObjects();
	DeleteMinigameVehicles();
	
	KillTimer(WaitingTimer);
	KillTimer(SecondTimer);
    SendRconCommand("unloadfs DataAAD");
	return true;
}

forward WaitingPlayers();
public WaitingPlayers()
{
	if(GetSVarInt("PlayersConnected") >= 2)
	{
		SetSVarInt("GamemodeStatus", DMG_STATUS_WAITING_ROUND);
	    SetTimer("StartMinigame", GetSVarInt("TimeStartMinigame")*1000, false);
	}
	else if(GetSVarInt("PlayersConnected") < 2)
	{
	    KillTimer(WaitingTimer);
	    WaitingTimer = SetTimer("WaitingPlayers", 1000, false);
	}
}

forward StartMinigame();
public StartMinigame()
{
    SetSVarInt("GamemodeStatus", DMG_STATUS_PLAYING_ROUND);

	LoopPlayer(i)
	{
	    if(PlayerStatus(i) == DMG_STATUS_WAITING_ROUND)
	    {
	        SetPVarInt(i, "PlayerStatus", DMG_STATUS_PLAYING_ROUND);
	        PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	        TogglePlayerControllable(i, true);
	        SetCameraBehindPlayer(i);
	        if(GetPVarInt(i, "PlayerTeam") == ATTACK)
	        {
	            if(PlayerLang(i) == 0) GameTextForPlayer(i, "~w~Capture o Checkpoint!", 3000, 5);
	            else if(PlayerLang(i) == 1) GameTextForPlayer(i, "~w~Capture the Checkpoint!", 3000, 5);
				for(new j = 0; j < sizeof(TEAM_ONE_WEAPONS); j++)
					GivePlayerWeapon(i, TEAM_ONE_WEAPONS[j], 250);
			}
	        else if(GetPVarInt(i, "PlayerTeam") == DEFENSE)
	        {
	            if(PlayerLang(i) == 0) GameTextForPlayer(i, "~w~Defenda o Checkpoint!", 3000, 5);
	            else if(PlayerLang(i) == 1) GameTextForPlayer(i, "~w~Defense the Checkpoint!", 3000, 5);
	            for(new j = 0; j < sizeof(TEAM_TWO_WEAPONS); j++)
					GivePlayerWeapon(i, TEAM_TWO_WEAPONS[j], 250);
			}
		}
	}
}

public OneSecondUpdate()
{
	if(GetSVarInt("GamemodeStatus") == DMG_STATUS_PLAYING_ROUND)
	{
		if(GetSVarInt("TimeMinutes") == 0)
	    {
			// Fim do Minigame por acabar o tempo...
			if(GetSVarInt("TimeSeconds") <= 0)
			{
	            SetSVarInt("EndMinigameType", LOST_TIME);
	            CallRemoteFunction("EndMinigame", "d", 1);
	            //EndMinigame();
			}
	    }
	    
	    if(GetSVarInt("TeamOneAlive") <= 0)
	    {
	        SetSVarInt("EndMinigameType", TEAM_TWO_KILLS);
	        CallRemoteFunction("EndMinigame", "d", 1);
	    }
	    else if(GetSVarInt("TeamTwoAlive") <= 0)
	    {
	        SetSVarInt("EndMinigameType", TEAM_ONE_KILLS);
	        CallRemoteFunction("EndMinigame", "d", 1);
	    }
	}
}

public OnPlayerConnect(playerid)
{
	SetPlayerMapIcon(playerid, 0, TEAM_SPAWN[ATTACK][0], TEAM_SPAWN[ATTACK][1], TEAM_SPAWN[ATTACK][2], MAPICON_POLICE, 0xFFFFFFFF, MAPICON_GLOBAL);
    SetPlayerMapIcon(playerid, 1, GetSVarFloat("CheckpointPosX"), GetSVarFloat("CheckpointPosY"), GetSVarFloat("CheckpointPosZ"), MAPICON_ENEMY, 0xFFFFFFFF, MAPICON_GLOBAL);
	return true;
}

public OnPlayerDisconnect(playerid, reason)
{
	return true;
}

public OnPlayerRequestSpawn(playerid)
{
	if(GetSVarInt("GamemodeStatus") == DMG_STATUS_WAITING_ROUND)
	{
		if(GetPVarInt(playerid, "PlayerTeam") == ATTACK && GetSVarInt("TeamOneAlive") > GetSVarInt("TeamTwoAlive"))
		{
		    SetPVarInt(playerid, "PlayerTeam", DEFENSE);
		    if(PlayerLang(playerid) == 0) SendClientMessage(playerid, COLOR_RED, "A equipe de ataque está cheia e você foi mandado para defesa.");
		    else if(PlayerLang(playerid) == 1) SendClientMessage(playerid, COLOR_RED, "The attack team is full and you have been sent to defense team.");
		}
		else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE && GetSVarInt("TeamTwoAlive") > GetSVarInt("TeamOneAlive"))
		{
		    SetPVarInt(playerid, "PlayerTeam", ATTACK);
		    if(PlayerLang(playerid) == 0) SendClientMessage(playerid, COLOR_RED, "A equipe de defesa está cheia e você foi mandado para ataque.");
		    else if(PlayerLang(playerid) == 1) SendClientMessage(playerid, COLOR_RED, "The defense team is full and you have been sent to attack team.");
		}
	}
	return true;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	if(vehicleid == AF_Vehicles[0]) // Boxville de enfeite
	    SetVehicleParamsForPlayer(vehicleid, forplayerid, 0, 1);
	    
	if(GetPVarInt(forplayerid, "PlayerTeam") == DEFENSE)
		SetVehicleParamsForPlayer(vehicleid, forplayerid, 0, 1);
	return true;
}

public OnPlayerSpawn(playerid)
{
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

	// Esperando começar o minigame...
	if(GetSVarInt("GamemodeStatus") == DMG_STATUS_WAITING_ROUND)
	{
	    CallRemoteFunction("SetHealth", "if", playerid, 100.0);
	    CallRemoteFunction("SetArmour", "if", playerid, 100.0);
	    
	    SetPlayerCheckpoint(playerid, GetSVarFloat("CheckpointX"), GetSVarFloat("CheckpointY"), GetSVarFloat("CheckpointZ"), 1.5);
	    GangZoneShowForPlayer(playerid, GANGZONE, TEAM_TWO_COLOR & 0xFFFFFF50);

		if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
		{
		    new rand2 = random(sizeof(SKINS_TEAM_ONE)), rand = random(sizeof(MIN_COORDS));
		    
			SetPlayerPos(playerid, TEAM_SPAWN[ATTACK][0]+MIN_COORDS[rand], TEAM_SPAWN[ATTACK][1]+MIN_COORDS[rand], TEAM_SPAWN[ATTACK][2]);
			SetPlayerFacingAngle(playerid, TEAM_SPAWN[ATTACK][3]);
			SetPlayerInterior(playerid, TEAM_ONE_SPAWN_INTERIOR);
			SetPlayerColor(playerid, TEAM_ONE_COLOR);
			SetPlayerSkin(playerid, SKINS_TEAM_ONE[rand2]);
			
			TogglePlayerControllable(playerid, 0);
		}
		else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE)
		{
		    new rand = random(sizeof(MIN_COORDS)), rand2 = random(sizeof(SKINS_TEAM_TWO));
		    
			SetPlayerPos(playerid, TEAM_SPAWN[DEFENSE][0]+MIN_COORDS[rand], TEAM_SPAWN[DEFENSE][1]+MIN_COORDS[rand], TEAM_SPAWN[DEFENSE][2]);
			SetPlayerFacingAngle(playerid, TEAM_SPAWN[DEFENSE][3]);
            SetPlayerInterior(playerid, TEAM_TWO_SPAWN_INTERIOR);
            SetPlayerColor(playerid, TEAM_TWO_COLOR);
            SetPlayerSkin(playerid, SKINS_TEAM_TWO[rand2]);
            
            TogglePlayerControllable(playerid, 0);
		}
		SetCameraBehindPlayer(playerid);
	}
	return true;
}

public OnPlayerRequestClass(playerid, classid)
{
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	
	if(classid == ATTACK)
	{
	    SetPlayerSkin(playerid, SKINS_TEAM_ONE[0]);
	}
	else if(classid == DEFENSE)
	{
	    SetPlayerSkin(playerid, SKINS_TEAM_TWO[0]);
	}
	
	return true;
}

forward OnPlayerDeath_Minigame(playerid, killerid, reason);
public OnPlayerDeath_Minigame(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID)
	{
	    new str[100];

		new Float:pos[3], Float:distance, weapon[20], name[24], namek[24];
		GetPlayerName(playerid, name, sizeof name);
		GetPlayerName(killerid, namek, sizeof namek);
		GetPlayerPos(killerid, pos[0], pos[1], pos[2]);
		GetWeaponName(reason, weapon, sizeof weapon);
		distance = GetPlayerDistanceFromPoint(playerid, pos[0], pos[1], pos[2]);
		
		LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "'%s' matou '%s' (Distância: %0.2f / Arma: %s).", namek, name, distance, weapon);
		    else if(PlayerLang(i) == 0) format(str, sizeof str, "'%s' has killed '%s' (Distance: %0.2f / Weapon: %s).", namek, name, distance, weapon);
			SendClientMessage(i, COLOR_YELLOW, str);
		}

		GameTextForPlayer(killerid, "~y~+1 Kill", 2000, 5);

		if(PlayerLang(playerid) == 0) GameTextForPlayer(playerid, "~r~Morreu!", 3000, 5);
		else if(PlayerLang(playerid) == 1) GameTextForPlayer(playerid, "~r~Dead!", 3000, 5);
	}
	else
	{
		if(PlayerLang(playerid) == 0) GameTextForPlayer(playerid, "~r~Morreu!", 3000, 5);
		else if(PlayerLang(playerid) == 1) GameTextForPlayer(playerid, "~r~Dead!", 3000, 5);
	}
}


CreateMinigameObjects()
{
	AF_Objects[0] = CreateObject(355, -2142.4108, -241.8421, 36.6944, 81.4999, -31.6000, 172.6000); //ak47
	AF_Objects[1] = CreateObject(355, -2142.9675, -242.0247, 36.6972, 81.4999, -31.6000, 172.6000); //ak47
	AF_Objects[2] = CreateObject(355, -2141.8291, -242.0330, 36.7076, 81.4999, -31.6000, 172.6000); //ak47
	AF_Objects[3] = CreateObject(19355, -2137.9675, -80.3041, 38.1501, 0.0000, 0.0000, -89.0998); //wall003
	SetObjectMaterialText(AF_Objects[3], "DMG", 0, 90, "Arial", 70, 0, 0xFF840410, 0x0, 1);
	AF_Objects[4] = CreateObject(19355, -2138.0278, -80.3424, 37.4001, 0.0000, 0.0000, -89.8000); //wall003
	SetObjectMaterialText(AF_Objects[4], "RECICLAGEM DE MATERIAIS QUIMICOS", 0, 140, "Arial", 30, 1, 0xFF000000, 0x0, 1);
	AF_Objects[5] = CreateObject(19355, -2116.1303, -80.3563, 37.4001, 0.0000, 0.0000, -90.0999); //wall003
	SetObjectMaterialText(AF_Objects[5], "RECICLAGEM DE MATERIAIS QUIMICOS", 0, 140, "Arial", 30, 1, 0xFF000000, 0x0, 1);
	AF_Objects[6] = CreateObject(19355, -2116.0729, -80.3501, 38.1501, 0.0000, 0.0000, -89.4999); //wall003
	SetObjectMaterialText(AF_Objects[6], "DMG", 0, 90, "Arial", 70, 0, 0xFF840410, 0x0, 1);
	AF_Objects[7] = CreateObject(11700, -2132.7463, -80.2602, 33.8702, 0.0000, 0.0000, 179.8999); //SAMPRoadSign47
	AF_Objects[8] = CreateObject(971, -2131.5134, -81.5190, 37.1433, 0.0000, 0.0000, 179.8000); //subwaygate
	AF_Objects[9] = CreateObject(8292, -2161.3859, -225.6025, 43.1237, 0.0000, 0.0000, 55.3000); //vgsbboardsigns01
	SetObjectMaterialText(AF_Objects[9], "FABRICA RECICLAGEM", 0, 90, "Arial", 24, 1, 0xFF840410, 0x0, 0);
	SetObjectMaterialText(AF_Objects[9], "a", 1, 90, "Arial", 24, 1, 0xFFFFFFFF, 0x0, 0);
	AF_Objects[10] = CreateObject(1217, -2111.8659, -111.0699, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[10], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[11] = CreateObject(1217, -2112.6967, -111.0699, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[11], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[12] = CreateObject(1217, -2113.5676, -111.0699, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[12], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[13] = CreateObject(1217, -2113.5676, -112.0899, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[13], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[14] = CreateObject(1217, -2112.7968, -112.0899, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[14], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[15] = CreateObject(1217, -2111.9160, -112.0899, 34.7349, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[15], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[16] = CreateObject(1217, -2111.9160, -111.6500, 35.8348, 0.0000, 0.0000, 0.0000); //barrel2
	SetObjectMaterial(AF_Objects[16], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[17] = CreateObject(1217, -2113.2175, -111.6921, 35.7280, 0.0000, 87.7998, -41.9999); //barrel2
	SetObjectMaterial(AF_Objects[17], 0, 18065, "ab_sfammumain", "ab_wallpaper02", 0xFFFFFFFF);
	AF_Objects[18] = CreateObject(1497, -2163.5534, -225.5541, 35.4979, 0.0000, 0.0000, 0.0000); //Gen_doorEXT02
	SetObjectMaterial(AF_Objects[18], 0, 18233, "cuntwshopscs_t", "des_adobedoor3", 0xFF000000);
	SetObjectMaterial(AF_Objects[18], 1, 11301, "carshow_sfse", "ws_basheddoor1", 0xFF706C67);
	AF_Objects[19] = CreateObject(348, -2143.5698, -242.4310, 36.7800, -71.4999, 0.0000, -0.6999); //desert_eagle
	AF_Objects[20] = CreateObject(18862, -2155.6164, -267.6355, 35.0354, 0.0000, 0.0000, 0.0000); //GarbagePileRamp1
	AF_Objects[21] = CreateObject(348, -2143.3999, -242.5373, 36.7451, -71.4999, 0.0000, -0.6999); //desert_eagle
	AF_Objects[22] = CreateObject(1580, -2162.5231, -267.1814, 36.6110, 0.0000, 0.0000, 0.0000); //drug_red
	AF_Objects[23] = CreateObject(1580, -2162.9233, -266.7315, 36.6110, 0.0000, 0.0000, 0.0000); //drug_red
	AF_Objects[24] = CreateObject(1580, -2163.2636, -266.3215, 36.6110, 0.0000, 0.0000, 0.0000); //drug_red
	AF_Objects[25] = CreateObject(1576, -2163.1208, -266.6091, 36.7510, 0.0000, 0.0000, -32.6999); //drug_orange
	AF_Objects[26] = CreateObject(1576, -2162.3447, -266.7510, 36.5811, 0.0000, 0.0000, -32.6999); //drug_orange
	AF_Objects[27] = CreateObject(1578, -2162.7185, -266.3335, 36.5811, 0.0000, 0.0000, 0.0000); //drug_green
	AF_Objects[28] = CreateObject(1299, -2113.3107, -115.9338, 34.8486, 0.0000, 0.0000, 0.0000); //smashboxpile
	AF_Objects[29] = CreateObject(3630, -2112.8310, -121.6492, 35.7668, -0.1000, 0.0000, 89.7000); //crdboxes2_LAs
	AF_Objects[30] = CreateObject(3630, -2112.8811, -131.4791, 35.7668, -0.1000, 0.0000, 89.7000); //crdboxes2_LAs
	AF_Objects[31] = CreateObject(3550, -2118.9030, -80.9611, 37.4627, 0.0000, -0.1999, -90.8999); //vgsn_fncelec_msh
	AF_Objects[32] = CreateObject(3550, -2112.9716, -81.0543, 37.4627, 0.0000, -0.1999, -90.8999); //vgsn_fncelec_msh
	AF_Objects[33] = CreateObject(3550, -2107.0419, -81.1474, 37.4627, 0.0000, -0.1999, -90.8999); //vgsn_fncelec_msh
	AF_Objects[34] = CreateObject(3550, -2101.1135, -81.2405, 37.4627, 0.0000, -0.1999, -90.8999); //vgsn_fncelec_msh
	AF_Objects[35] = CreateObject(3550, -2099.5920, -81.2644, 37.4627, 0.0000, -0.1999, -90.8999); //vgsn_fncelec_msh
	AF_Objects[36] = CreateObject(3550, -2096.7678, -83.9596, 37.4523, 0.0000, -0.1999, 179.7000); //vgsn_fncelec_msh
	AF_Objects[37] = CreateObject(3550, -2096.7976, -89.8895, 37.4523, 0.0000, -0.1999, 179.7000); //vgsn_fncelec_msh
	AF_Objects[38] = CreateObject(3550, -2096.8264, -95.8195, 37.4523, 0.0000, -0.1999, 179.7000); //vgsn_fncelec_msh
	AF_Objects[39] = CreateObject(3550, -2096.8562, -101.7494, 37.4523, 0.0000, -0.1999, 179.7000); //vgsn_fncelec_msh
	AF_Objects[40] = CreateObject(3550, -2096.8867, -107.6593, 37.4523, 0.0000, -0.1999, 179.7000); //vgsn_fncelec_msh
	AF_Objects[41] = CreateObject(3550, -2141.7990, -80.8344, 37.4635, 0.0000, -0.1999, -89.9999); //vgsn_fncelec_msh
	AF_Objects[42] = CreateObject(3550, -2135.8483, -80.8344, 37.4635, 0.0000, -0.1999, -89.9999); //vgsn_fncelec_msh
	AF_Objects[43] = CreateObject(3550, -2147.7194, -80.8344, 37.4635, 0.0000, -0.1999, -89.9999); //vgsn_fncelec_msh
	AF_Objects[44] = CreateObject(3550, -2153.7004, -80.8344, 37.4635, 0.0000, -0.1999, -89.9999); //vgsn_fncelec_msh
	AF_Objects[45] = CreateObject(3550, -2156.8520, -83.4575, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[46] = CreateObject(3550, -2156.8618, -89.3575, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[47] = CreateObject(3550, -2156.8706, -95.3175, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[48] = CreateObject(3550, -2156.8813, -101.2575, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[49] = CreateObject(3550, -2156.8906, -107.1775, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[50] = CreateObject(3550, -2156.9013, -113.0875, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[51] = CreateObject(3550, -2156.9113, -119.0075, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[52] = CreateObject(3550, -2156.9223, -124.9375, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[53] = CreateObject(3550, -2156.9326, -130.8475, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[54] = CreateObject(3550, -2156.9418, -136.7574, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[55] = CreateObject(3550, -2156.9526, -142.6774, 37.4746, 0.0000, 0.3000, 179.9000); //vgsn_fncelec_msh
	AF_Objects[56] = CreateObject(3630, -2112.8562, -125.5292, 38.7469, -0.1000, 0.0000, 89.6999); //crdboxes2_LAs
	AF_Objects[57] = CreateObject(3630, -2124.3815, -112.0960, 35.6525, -0.1000, 0.0000, -179.9999); //crdboxes2_LAs
	AF_Objects[58] = CreateObject(3630, -2132.4028, -112.0960, 35.6525, -0.1000, 0.0000, -179.9999); //crdboxes2_LAs
	AF_Objects[59] = CreateObject(3630, -2128.6127, -112.1013, 38.6625, -0.1000, 0.0000, -179.9999); //crdboxes2_LAs
	AF_Objects[60] = CreateObject(3630, -2118.6430, -108.5161, 35.6688, -0.1000, 0.0000, -179.9999); //crdboxes2_LAs
	AF_Objects[61] = CreateObject(1578, -2161.3374, -266.3335, 36.5811, 0.0000, 0.0000, 0.0000); //drug_green
	AF_Objects[62] = CreateObject(1578, -2161.6201, -266.7782, 36.5811, 0.0000, 0.0000, 133.2000); //drug_green
	AF_Objects[63] = CreateObject(1575, -2161.5881, -265.9154, 36.5761, 0.0000, 0.0000, 0.0000); //drug_white
	AF_Objects[64] = CreateObject(1575, -2161.6357, -266.3248, 36.7150, -1.3999, -15.1000, -30.1000); //drug_white
	AF_Objects[65] = CreateObject(19359, -2175.0065, -208.4910, 35.1653, -0.4000, 0.0000, -83.9000); //wall007
	SetObjectMaterialText(AF_Objects[65], "DMG", 0, 90, "Arial", 40, 1, 0xFF840410, 0x0, 0);
	SetObjectMaterialText(AF_Objects[65], "AA", 1, 90, "Arial", 24, 1, 0xFFFFFFFF, 0x0, 0);
	AF_Objects[66] = CreateObject(19359, -2175.0065, -208.4910, 35.1653, -0.4000, 0.0000, -83.9000); //wall007
	SetObjectMaterialText(AF_Objects[66], "RECICLAGEM DE MATERIAIS QUIMICOS", 0, 140, "Arial", 20, 1, 0xFFFFFFFF, 0x0, 1);
}

DeleteMinigameObjects()
{
	for(new i = 0, k = sizeof(AF_Objects); i < k; i++)
	{
	    if(IsValidObject(AF_Objects[i]))
	        DestroyObject(AF_Objects[i]);
	}
}

CreateMinigameVehicles()
{
	AF_Vehicles[0] = CreateVehicle(498, -2110.8137, -75.9040, 35.3865, 295.0596, 0, 0, -1); //Boxville
	AF_Vehicles[1] = CreateVehicle(597, -1634.2303, 651.3612, 6.9242, 1.3657, 0, 253, -1); //Police Car (SFPD)
	AF_Vehicles[2] = CreateVehicle(597, -1628.3862, 651.4252, 6.9570, 0.8451, 0, 253, -1); //Police Car (SFPD)
	AF_Vehicles[3] = CreateVehicle(597, -1622.3481, 651.5460, 6.9555, 0.2281, 0, 253, -1); //Police Car (SFPD)
	AF_Vehicles[4] = CreateVehicle(597, -1616.4238, 651.4952, 6.9567, 0.4756, 0, 0, -1); //Police Car (SFPD)
	AF_Vehicles[5] = CreateVehicle(597, -1610.7198, 651.7146, 6.9566, 0.6641, 0, 0, -1); //Police Car (SFPD)
	AF_Vehicles[6] = CreateVehicle(597, -1605.0137, 651.7822, 6.9556, 1.3043, 0, 0, -1); //Police Car (SFPD)
	AF_Vehicles[7] = CreateVehicle(490, -1611.9410, 673.5765, 7.3153, 180.3363, 0, 0, -1); //FBI Rancher
	AF_Vehicles[8] = CreateVehicle(427, -1606.1125, 673.4191, 7.3192, 179.5864, 250, 81, -1); //Enforcer
	AF_Vehicles[9] = CreateVehicle(497, -1687.9822, 697.2801, 30.7814, 0.0772, 1, 1, -1); //Police Maverick
	AF_Vehicles[10] = CreateVehicle(497, -1688.8843, 715.4637, 30.7490, 179.4947, 0, 0, -1); //Police Maverick
	AF_Vehicles[11] = CreateVehicle(497, -1671.8026, 714.6179, 30.7678, 178.8272, 1, 1, -1); //Police Maverick
	AF_Vehicles[12] = CreateVehicle(497, -1670.7315, 697.8349, 30.7401, 0.1684, 0, 0, -1); //Police Maverick
	AF_Vehicles[13] = CreateVehicle(490, -1600.0965, 673.5725, 7.3155, 180.3483, 0, 0, -1); //FBI Rancher
	AF_Vehicles[14] = CreateVehicle(597, -1599.3277, 651.8567, 6.9565, 0.4410, 1, 1, -1); //Police Car (SFPD)
	AF_Vehicles[15] = CreateVehicle(597, -1593.6325, 651.8572, 6.9558, 0.2887, 1, 1, -1); //Police Car (SFPD)
	AF_Vehicles[16] = CreateVehicle(597, -1587.7052, 651.9602, 6.9556, 0.9968, 1, 1, -1); //Police Car (SFPD)
	AF_Vehicles[17] = CreateVehicle(523, -1594.1785, 673.5504, 6.7568, 179.5854, 6, 6, -1); //HPV1000
	AF_Vehicles[18] = CreateVehicle(523, -1588.2849, 673.7481, 6.7580, 180.9470, 175, 68, -1); //HPV1000
	AF_Vehicles[19] = CreateVehicle(523, -1582.3297, 673.9848, 6.7534, 179.7855, 252, 236, -1); //HPV1000
	AttachObjectToVehicle(AF_Objects[65], AF_Vehicles[0], -1.1399, -1.6299, 0.1799, 359.8999, 0.0000, 0.0000);
	AttachObjectToVehicle(AF_Objects[66], AF_Vehicles[0], -1.1499, -0.5500, 0.8999, 359.8999, 0.0000, 0.0000);
}

DeleteMinigameVehicles()
{
	for(new i = 0, k = sizeof(AF_Vehicles); i < k; i++)
	{
	    if(AF_Vehicles[i] != INVALID_VEHICLE_ID)
	        DestroyObject(AF_Vehicles[i]);
	}
}
