/*
	Deathmatch Mini Games
		por Roger Costa
		
		
	Minigame:       Ataque na Area 51
	Tipo: 			Attack/Defense
	Idéia por: 		Felipe Bisineli
	Script por: 	Roger Costa "NikO"
	Mapa por:       Roger Costa "NikO"
	
	- Explicação -
	Aqui explique sobre como funciona o minigame.


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
#define MG_NAME                         	"Ataque na Area 51"
#define MG_IDEA                         	"Felipe Bisineli"
#define MG_SCRIPT                       	"NikO"
#define MG_MAP                       		"NikO"
#define MG_STYLE                        	"Attack/Defense"

// Não alterar essa parte.
#undef TYPE_MINIGAME
	#define TYPE_MINIGAME                	MINIGAME_AAD

// Tempo para captura do Checkpoint
#undef AAD_CHECKPOINT_TIME
	#define AAD_CHECKPOINT_TIME             20

// X, Y, Z do local do Checkpoint
#define CHECKPOINT_X                        247.3914
#define CHECKPOINT_Y                        1859.6935
#define CHECKPOINT_Z                        14.0840

// Definições dos Times
#define TEAMS                               2

// Nome da Equipe 1 (Ataque)
#define TEAM_ONE_NAME           			"Terroristas"
#define TEAM_ONE_NAME_ENG           		"Terrorists"
// Nome da Equipe 2 (Defesa)
#define TEAM_TWO_NAME           			"Exercito"
#define TEAM_TWO_NAME_ENG           		"Army"
// Cor da Equipe 1
#define TEAM_ONE_COLOR                      COLOR_RED
// Cor da Equipe 2
#define TEAM_TWO_COLOR                      COLOR_BLUE
// Skins da Equipe 1 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_ONE_SKIN_ID                    125
// Skins da Equipe 2 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_TWO_SKIN_ID                    286, 287

// Armas da Equipe 1 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_ONE_WEAPONS_IDS
	#define TEAM_ONE_WEAPONS_IDS            30, 24, 33, 46
// Armas da Equipe 2 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_TWO_WEAPONS_IDS
	#define TEAM_TWO_WEAPONS_IDS            27, 31, 33
	
#define TEAM_ONE_SPAWN_INTERIOR             0
#define TEAM_TWO_SPAWN_INTERIOR             0

// Definições para o Radar e TagNames
#define HIDE_ALL                 			0
#define ONLY_TEAM                           1
#define SHOW_ALL                            2
#define DMG_MARKER_TYPE                     ONLY_TEAM

// Horário e Tempo do Minigame
#define MINIGAME_WEATHER                	1
#define MINIGAME_HOUR                   	0

#define PlayerLang(%0)     					GetPVarInt(%0, "PlayerLang")
#define PlayerStatus(%0)    				GetPVarInt(%0, "PlayerStatus")
#define LoopPlayer(%0)    					for(new %0 = 0, k = GetPlayerPoolSize(); %0 <= k; %0++)

forward OneSecondUpdate();
forward CheckPointTimer();

new Float:TEAM_SPAWN[TEAMS][4] =
{
	{-18.6716, 1922.3711, 237.2519, 271.6858},      		// Ataque Spawn
	{213.4106, 1864.1744, 13.1406, 359.4199}       			// Defesa Spawn
};

new TeamObjective[TEAMS][128] =
{
	{"~y~Objetivo: ~w~Capture o Checkpoint!"},
	{"~y~Objetivo: ~w~Mate os terroristas e defenda o Checkpoint!"}
};

new TeamObjectiveEng[TEAMS][128] =
{
	{"~y~Objective: ~w~Capture the Checkpoint!"},
	{"~y~Objective: ~w~Kill the terrorists and defense checkpoint!"}
};

new TeamMessage[TEAMS][] =
{
	{"Ataque a Area 51 e capture o checkpoint. Cuidado para nao morrer!"},
	{"Terroristas planejam um ataque na Area 51. Nao deixe que capturem o checkpoint!"}
};

new TeamMessageEng[TEAMS][] =
{
	{"Attack Area 51 and capture the checkpoint. Attention to not death."},
	{"Terrorists plan attacks Area 51. Do not let capture checkpoint!"}
};

new TEAM_ONE_WEAPONS[] = { TEAM_ONE_WEAPONS_IDS };
new TEAM_TWO_WEAPONS[] = { TEAM_TWO_WEAPONS_IDS };
new SKINS_TEAM_ONE[] = { TEAM_ONE_SKIN_ID };
new SKINS_TEAM_TWO[] = { TEAM_TWO_SKIN_ID };
new GANGZONE;
new Float:MIN_COORDS[8] = { 0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.25 };
new A51_Objects[6];
new A51_Vehicles[2];
new WaitingTimer, SecondTimer;

public OnFilterScriptInit()
{
	LoadEssentialsFunc(); // Não remova.
	CreateMinigameObjects();
	CreateMinigameVehicles();
	
	/*
	    Adicione a partir desse comentário os scripts únicos do minigame
	    atual...
	*/
	GANGZONE = GangZoneCreate(GetSVarFloat("CheckpointPosX")-50, GetSVarFloat("CheckpointPosY")-50, GetSVarFloat("CheckpointPosX")+50, GetSVarFloat("CheckpointPosY")+50);
	
	return true;
}

public OnFilterScriptExit()
{
    DeleteMinigameObjects();
    DeleteMinigameVehicles();
    
    KillTimer(SecondTimer);
    KillTimer(WaitingTimer);
    SendRconCommand("unloadfs DataAAD"); // Não remova.
	return true;
}

// Favor não remover nem editar essa função.
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
	RemovePlayerAttachedObject(playerid, 0);
	RemovePlayerAttachedObject(playerid, 1);
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
	if(vehicleid == A51_Vehicles[0] || vehicleid == A51_Vehicles[1])
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
	    SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_WAITING_ROUND);
	    
	    CallRemoteFunction("SetHealth", "if", playerid, 100.0);
	    CallRemoteFunction("SetArmour", "if", playerid, 100.0);
	    
	    GangZoneShowForPlayer(playerid, GANGZONE, TEAM_TWO_COLOR & 0xFFFFFF50);

		if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
		{
		    new rand2 = random(sizeof(SKINS_TEAM_ONE)), rand = random(sizeof(MIN_COORDS));
			SetPlayerPos(playerid, TEAM_SPAWN[ATTACK][0]+MIN_COORDS[rand], TEAM_SPAWN[ATTACK][1]+MIN_COORDS[rand], TEAM_SPAWN[ATTACK][2]);
			SetPlayerFacingAngle(playerid, TEAM_SPAWN[ATTACK][3]);
			SetPlayerInterior(playerid, TEAM_ONE_SPAWN_INTERIOR);
			SetPlayerColor(playerid, TEAM_ONE_COLOR);
			SetPlayerSkin(playerid, SKINS_TEAM_ONE[rand2]);
			
			SetPlayerAttachedObject(playerid, 0, 19801, 2, 0.0737, 0.0208, 0.0000, 8.9997, 89.0000, 173.0997, 1.0540, 1.0888, 1.0819, 0xFFFFFFFF, 0xFFFFFFFF); // Balaclava1 attached to the Head of NikO
			SetPlayerAttachedObject(playerid, 1, 373, 1, 0.2818, -0.0379, -0.1480, 68.4999, 20.5000, 31.5000, 1.0000, 0.9240, 1.1510, 0xFF2E2D33, 0xFFFFFFFF); // armour attached to the Spine of NikO
			
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
	// Abaixo se você quiser adicionar alguma música, audio, etc...
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


/*
	Deathmatch Minigames
		por Roger Costa

	Não remova nem altere nada dos scripts abaixo. Só mexa se realmente
	souber no que estiver mexendo, pois quaisquer mudanças
	podem acarretar no mau funcionamento do minigame.
*/

//LoadPlayerSpec(playerid)
//{
//    CallRemoteFunction("SetPlayerSpec", "d", playerid);
//}

LoadEssentialsFunc()
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

	SetSVarString("TeamOneName", TEAM_ONE_NAME);
	SetSVarString("TeamTwoName", TEAM_TWO_NAME);
	SetSVarString("TeamOneNameEng", TEAM_ONE_NAME_ENG);
	SetSVarString("TeamTwoNameEng", TEAM_TWO_NAME_ENG);

	SendRconCommand("loadfs DataAAD");
	
	SetSVarInt("MarkerType", DMG_MARKER_TYPE);

	SetWeather(MINIGAME_WEATHER);
	SetWorldTime(MINIGAME_HOUR);

    SetSVarInt("CheckpointTime", AAD_CHECKPOINT_TIME);
	SetSVarFloat("CheckpointPosX", CHECKPOINT_X);
	SetSVarFloat("CheckpointPosY", CHECKPOINT_Y);
	SetSVarFloat("CheckpointPosZ", CHECKPOINT_Z);

	SetSVarFloat("AttPosX", TEAM_SPAWN[0][0]);
	SetSVarFloat("AttPosY", TEAM_SPAWN[0][1]);
	SetSVarFloat("AttPosZ", TEAM_SPAWN[0][2]);

	WaitingTimer = SetTimer("WaitingPlayers", 1000, false);
	SecondTimer = SetTimer("OneSecondUpdate", 1000, true);
}

CreateMinigameObjects()
{
	A51_Objects[0] = CreateObject(3095, 268.3228, 1884.5003, 16.0450, 0.0000, 0.0000, 0.0000); //a51_jetdoor
	A51_Objects[1] = CreateObject(14553, -20.7015, 1922.9836, 239.0000, 0.0000, 0.0000, -89.7998); //androm_des_obj
	A51_Objects[2] = CreateObject(14548, -17.3206, 1922.6778, 238.0000, 0.4999, 0.0000, -89.0000); //cargo_test
	A51_Objects[3] = CreateObject(19369, 218.2732, 1878.0443, 14.1431, 0.0000, 0.0000, -6.3999); //wall017
	SetObjectMaterialText(A51_Objects[3], "M", 0, 140, "Arial", 90, 1, 0xFF840410, 0x0, 1);
	A51_Objects[4] = CreateObject(19369, 218.2790, 1878.1362, 14.2732, 0.0000, 0.0000, -7.7998); //wall017
	SetObjectMaterialText(A51_Objects[4], "Death     atch", 0, 140, "Arial", 50, 1, 0xFF000000, 0x0, 1);
	A51_Objects[5] = CreateObject(19369, 218.1809, 1877.3006, 14.0632, 0.0000, 0.0000, -7.5998); //wall017
	SetObjectMaterialText(A51_Objects[5], "inigames", 0, 140, "Arial", 50, 1, 0xFF000000, 0x0, 1);
}

DeleteMinigameObjects()
{
	for(new i = 0; i < 6; i++)
	{
	    if(IsValidObject(A51_Objects[i]))
	        DestroyObject(A51_Objects[i]);
	}
}

CreateMinigameVehicles()
{
	A51_Vehicles[0] = CreateVehicle(433, 178.7446, 1930.8122, 18.4779, 179.1163, 0, 165, -1); //Barracks
	A51_Vehicles[1] = CreateVehicle(433, 172.8564, 1930.9735, 18.7023, 180.3937, 145, 230, -1); //Barracks
}

DeleteMinigameVehicles()
{
	for(new i = 0; i < sizeof A51_Objects; i++)
	{
	    if(A51_Vehicles[i] != INVALID_VEHICLE_ID)
	        DestroyVehicle(A51_Vehicles[i]);
	}
}
