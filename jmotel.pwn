/*
	Deathmatch Mini Games
		por Roger Costa
		
		
	Minigame:       Jeferson Motel
	Tipo: 			Attack/Defense
	Idéia por: 		Roger Costa 'NikO'
	Script por: 	Roger Costa 'NikO'
	Mapa por:       Roger Costa 'NikO'
	
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
#define MG_NAME                         	"Invasão ao Jeferson Motel"
#define MG_IDEA                         	"NikO"
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
#define CHECKPOINT_X                        2190.6748
#define CHECKPOINT_Y                        -1146.4613
#define CHECKPOINT_Z                        1033.7969

// Definições dos Times
#define TEAMS                               2

// Nome da Equipe 1 (Ataque)
#define TEAM_ONE_NAME           			"Swat/Fbi"
#define TEAM_ONE_NAME_ENG           		"Swat/Fbi"
// Nome da Equipe 2 (Defesa)
#define TEAM_TWO_NAME           			"Bandidos"
#define TEAM_TWO_NAME_ENG          			"Thugs"
// Cor da Equipe 1
#define TEAM_ONE_COLOR                      COLOR_BLUE
// Cor da Equipe 2
#define TEAM_TWO_COLOR                      COLOR_RED
// Skins da Equipe 1 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_ONE_SKIN_ID                    285
// Skins da Equipe 2 - Selecione quantas skins quiser, separando por vírgula
#define TEAM_TWO_SKIN_ID                    110, 111

// Armas da Equipe 1 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_ONE_WEAPONS_IDS
	#define TEAM_ONE_WEAPONS_IDS            24, 27, 31, 33
// Armas da Equipe 2 - Selecione quantas armas quiser, separando por vírgula
#undef TEAM_TWO_WEAPONS_IDS
	#define TEAM_TWO_WEAPONS_IDS            24, 25, 30, 33
	
#define TEAM_ONE_SPAWN_INTERIOR             15
#define TEAM_TWO_SPAWN_INTERIOR             15

// Definições para o Radar e TagNames
#define HIDE_ALL                 			0
#define ONLY_TEAM                           1
#define SHOW_ALL                            2
#define DMG_MARKER_TYPE                     ONLY_TEAM

// Horário e Tempo do Minigame
#define MINIGAME_WEATHER                	6
#define MINIGAME_HOUR                   	13

#define PlayerLang(%0)     	GetPVarInt(%0, "PlayerLang")
#define PlayerStatus(%0)    GetPVarInt(%0, "PlayerStatus")
#define LoopPlayer(%0)    	for(new %0 = 0, k = GetPlayerPoolSize(); %0 <= k; %0++)

forward OneSecondUpdate();
forward CheckPointTimer();

new Float:TEAM_SPAWN[TEAMS][4] =
{
	{2220.3906, -1150.8214, 1025.7969, 271.6136},      		// Ataque Spawn
	{2194.1191, -1141.9155, 1029.7969, 179.4926}       		// Defesa Spawn
};

new const TeamObjective[TEAMS][128] =
{
	{"~y~Objetivo: ~w~Acabe com a reuniao dos bandidos capturando o checkpoint."},
	{"~y~Objetivo: ~w~Defenda o checkpoint da policia."}
};

new const TeamObjectiveEng[TEAMS][128] =
{
	{"~y~Objetivo: ~w~End the meeting of thugs capturing the checkpoint."},
	{"~y~Objetivo: ~w~Defense the checkpoint againt police."}
};

new const TeamMessage[TEAMS][] =
{
	{"Foi informado que bandidos estao em reuniao no Jeferson Motel. Va verificar e domine o checkpoint."},
	{"A policia esta prestes a invadir o Jeferson Motel. Nao deixe que capturem o checkpoint."}
};

new const TeamMessageEng[TEAMS][] =
{
	{"It was reported that thugs are meeting at the Jefferson Motel. Go and fuck all!"},
	{"The police are coming to invade the Jefferson Motel. Protect the checkpoint!"}
};

new TEAM_ONE_WEAPONS[] = { TEAM_ONE_WEAPONS_IDS };
new TEAM_TWO_WEAPONS[] = { TEAM_TWO_WEAPONS_IDS };
new SKINS_TEAM_ONE[] = { TEAM_ONE_SKIN_ID };
new SKINS_TEAM_TWO[] = { TEAM_TWO_SKIN_ID };
new GANGZONE;
new Float:MIN_COORDS[8] = { 0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.25 };
new JM_Objects[38];
new WaitingTimer, SecondTimer;

public OnFilterScriptInit()
{
	LoadEssentialsFunc(); // Não remova.
	CreateMinigameObjects();
	
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
	
	KillTimer(WaitingTimer);
	KillTimer(SecondTimer);
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
	// Abaixo se você quiser adicionar alguma música, audio, etc...
	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
	
	if(classid == ATTACK)
		SetPlayerSkin(playerid, SKINS_TEAM_ONE[0]);
	else if(classid == DEFENSE)
		SetPlayerSkin(playerid, SKINS_TEAM_TWO[0]);

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
		GetWeaponName(reason, weapon, sizeof weapon);
		GetPlayerPos(killerid, pos[0], pos[1], pos[2]);
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

	LoadTeamsTextDraws();

	/*
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO[ATTACK], TeamMessage[ATTACK]);
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO[DEFENSE], TeamMessage[DEFENSE]);
	TextDrawSetString(DMG_TEAM_OBJECTIVE[ATTACK], TeamObjective[ATTACK]);
	TextDrawSetString(DMG_TEAM_OBJECTIVE[DEFENSE], TeamObjective[DEFENSE]);
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO_ENG[ATTACK], TeamMessageEng[ATTACK]);
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO_ENG[DEFENSE], TeamMessageEng[DEFENSE]);
	TextDrawSetString(DMG_TEAM_OBJECTIVE_ENG[ATTACK], TeamObjectiveEng[ATTACK]);
	TextDrawSetString(DMG_TEAM_OBJECTIVE_ENG[DEFENSE], TeamObjectiveEng[DEFENSE]);
	*/
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[ATTACK], TEAM_ONE_NAME);
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[DEFENSE], TEAM_TWO_NAME);
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[2], TEAM_ONE_NAME_ENG);
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[3], TEAM_TWO_NAME_ENG);


	SetTimer("WaitingPlayers", 1000, false);
	SetTimer("OneSecondUpdate", 1000, true);
}

CreateMinigameObjects()
{
	JM_Objects[0] = CreateObject(19836, 2240.8828, -1191.3874, 1029.2999, 0.0000, 0.0000, 0.0000); //BloodPool1
	JM_Objects[1] = CreateObject(19364, 2228.8647, -1142.7231, 1030.6683, 0.0000, 0.0000, 0.0000); //wall012
	SetObjectMaterialText(JM_Objects[1], "Deathmatch Minigames 2k16", 0, 140, "Consolas", 24, 1, 0xFF000000, 0x0, 1);
	JM_Objects[2] = CreateObject(2987, 2238.8310, -1170.9425, 1030.0373, -0.0997, 0.9998, 127.3999); //lxr_motel_doorsim
	JM_Objects[3] = CreateObject(19836, 2241.2031, -1191.5876, 1029.2999, 0.0000, 0.0000, 0.0000); //BloodPool1
	JM_Objects[4] = CreateObject(18706, 2232.0820, -1177.1689, 1027.7874, 0.0000, 0.0000, 0.0000); //prt_blood
	JM_Objects[5] = CreateObject(1582, 2224.3483, -1182.7772, 1029.2873, 0.0000, 0.0000, -22.3999); //pizzabox
	JM_Objects[6] = CreateObject(19121, 2206.9650, -1196.1251, 1028.7236, 0.0000, 0.0000, 0.0000); //BollardLight1
	JM_Objects[7] = CreateObject(19298, 2208.4360, -1194.3121, 1031.7166, 0.0000, 0.0000, 0.0000); //PointLight18
	JM_Objects[8] = CreateObject(19578, 2195.6752, -1176.5555, 1029.8226, 0.0000, 0.0000, 0.0000); //Banana1
	JM_Objects[9] = CreateObject(19577, 2195.8051, -1176.5653, 1029.8232, 0.0000, 0.0000, 0.0000); //Tomato1
	JM_Objects[10] = CreateObject(19577, 2195.8051, -1176.4852, 1029.8232, 0.0000, 0.0000, 0.0000); //Tomato1
	JM_Objects[11] = CreateObject(18704, 2202.7353, -1175.2690, 1027.3641, 0.0000, 0.0000, 0.0000); //overheat_car_elec
	JM_Objects[12] = CreateObject(19579, 2183.7099, -1150.7569, 1028.9809, 0.0000, 0.0000, 78.5998); //BreadLoaf1
	SetObjectMaterial(JM_Objects[12], 0, 16640, "a51", "Alumox64", 0xFF1E9999);
	JM_Objects[13] = CreateObject(2987, 2238.0432, -1159.6599, 1028.8419, -90.9999, -0.8999, 65.5998); //lxr_motel_doorsim
	JM_Objects[14] = CreateObject(2114, 2229.4709, -1157.0997, 1029.6092, 0.0000, 0.0000, 0.0000); //basketball
	SetObjectMaterial(JM_Objects[14], 0, 8487, "ballyswater", "waterclear256", 0xFFFFFFFF);
	JM_Objects[15] = CreateObject(2911, 2229.1550, -1155.2702, 1029.1522, -90.0999, 0.0000, 0.0000); //kmb_petroldoor
	SetObjectMaterial(JM_Objects[15], 0, 16646, "a51_alpha", "waterdirty256", 0xFF0E316D);
	JM_Objects[16] = CreateObject(1484, 2231.5651, -1186.4023, 1029.4157, 0.0000, 0.0000, 0.0000); //CJ_BEAR_BOTTLE
	JM_Objects[17] = CreateObject(2714, 2233.4033, -1158.0904, 1029.7281, 0.0000, 0.0000, 55.0999); //CJ_OPEN_SIGN_2
	SetObjectMaterialText(JM_Objects[17], "Classificação: 18 anos", 0, 90, "Microsoft Sans Serif", 25, 1, 0xFFFFFFFF, 0xFF142407, 1);
	JM_Objects[18] = CreateObject(19823, 2229.6704, -1186.3564, 1029.7973, 0.0000, 0.0000, 0.0000); //AlcoholBottle4
	JM_Objects[19] = CreateObject(19823, 2229.4602, -1186.3564, 1029.7973, 0.0000, 0.0000, -19.7999); //AlcoholBottle4
	JM_Objects[20] = CreateObject(19820, 2229.2194, -1186.3856, 1029.7774, 0.0000, 0.0000, 0.0000); //AlcoholBottle1
	JM_Objects[21] = CreateObject(2987, 2225.2619, -1186.2519, 1030.0035, 0.0000, 0.0000, 42.2000); //lxr_motel_doorsim
	JM_Objects[22] = CreateObject(2394, 2223.5483, -1179.3724, 1029.4808, 0.0000, 0.0000, 0.0000); //CJ_CLOTHES_STEP_1
	JM_Objects[23] = CreateObject(2372, 2223.0119, -1179.5621, 1028.7821, 0.0000, 0.0000, -89.7998); //CLOTHES_RAIL2
	JM_Objects[24] = CreateObject(3109, 2231.2070, -1176.0268, 1029.3730, 0.0000, -87.5998, 176.1999); //imy_la_door
	SetObjectMaterial(JM_Objects[24], 0, 16646, "a51_alpha", "waterdirty256", 0xFFFFFFFF);
	JM_Objects[25] = CreateObject(19317, 2230.6237, -1183.3282, 1029.4450, -90.8000, 66.0998, 38.5999); //bassguitar01
	JM_Objects[26] = CreateObject(2987, 2225.2756, -1186.2668, 1030.6640, 0.0000, 0.0000, 42.2000); //lxr_motel_doorsim
	SetObjectMaterialText(JM_Objects[26], "Proprietário: NikO", 0, 100, "Arial", 15, 1, 0xFFFFFFFF, 0x0, 1);
	JM_Objects[27] = CreateObject(19609, 2230.6948, -1181.2142, 1028.7788, 0.0000, 0.0000, 156.6999); //DrumKit1
	JM_Objects[28] = CreateObject(19617, 2231.3071, -1180.1251, 1030.6639, 0.0000, 0.0000, 0.0000); //GoldRecord1
	JM_Objects[29] = CreateObject(19897, 2230.1008, -1182.7243, 1029.4687, 0.0000, 0.0000, 49.7999); //CigarettePack2
	JM_Objects[30] = CreateObject(19897, 2230.2773, -1182.7657, 1029.4687, 0.0000, 0.0000, 118.7998); //CigarettePack2
	JM_Objects[31] = CreateObject(3027, 2231.5849, -1184.6387, 1029.5571, 90.1999, 0.0000, -59.9000); //ciggy
	JM_Objects[32] = CreateObject(18673, 2231.4687, -1184.6981, 1027.9730, 0.0000, 0.0000, 0.0000); //cigarette_smoke
	JM_Objects[33] = CreateObject(2125, 2230.4328, -1181.8828, 1029.1037, 0.0000, 0.0000, 0.0000); //MED_DIN_CHAIR_1
	JM_Objects[34] = CreateObject(19616, 2230.5346, -1186.1877, 1028.8104, 0.0000, 0.0000, -179.0999); //GuitarAmp5
	JM_Objects[35] = CreateObject(19319, 2229.2512, -1186.6914, 1030.8677, 2.2000, 39.5000, -179.3001); //warlock01
	JM_Objects[36] = CreateObject(19319, 2228.7797, -1186.6759, 1030.8649, -4.6999, -43.5999, -179.3001); //warlock01
	JM_Objects[37] = CreateObject(11745, 2231.9428, -1184.8928, 1029.7015, 0.0000, 0.0000, -21.2999); //HoldAllEdited1
}

DeleteMinigameObjects()
{
	for(new i = 0, k = sizeof(JM_Objects); i < k; i++)
	{
	    if(IsValidObject(JM_Objects[i]))
	        DestroyObject(JM_Objects[i]);
	}
}
