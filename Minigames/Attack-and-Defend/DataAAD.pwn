/*
	Deathmatch Minigames
	    por Roger Costa

	Filterscript base para o estilo de minigame Attack/Defense
	
	- Atenção -
	Se estiver lendo isso, é porque eu, Roger, lhe passei o mode.
	Se você não souber no que estiver modificando, por favor, contate-me
	para maiores informações:
	    Facebook: 	Roger Gomes Costa
		E-mail: 	roger.gomes@outlook.com


	* Este script faz parte da divisão "Games" da Roger Soluctions
	e está alocada na area San Andreas Multiplayer (SAMP)
		
	Att,
	    Roger Costa
		CEO R.S.Company
		

*/

#include <a_samp>
#include <DeathMinigames/AAD.inc>

#define PlayerLang(%0)     	GetPVarInt(%0, "PlayerLang")
#define LoopPlayer(%0)    	for(new %0 = 0, k = GetPlayerPoolSize(); %0 <= k; %0++)

new SecondTimer;
new CHECKPOINT_TIMER;


public OnFilterScriptInit()
{
    // Carregando Textdraws
	LoadTeamsTextDraws();

	TextDrawSetString(DMG_TEAM_MESSAGE_INFO[ATTACK], GetSVarStringEx("AttMessageBox"));
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO[DEFENSE], GetSVarStringEx("DefMessageBox"));

	TextDrawSetString(DMG_TEAM_OBJECTIVE[ATTACK], GetSVarStringEx("AttObjective"));
	TextDrawSetString(DMG_TEAM_OBJECTIVE[DEFENSE], GetSVarStringEx("DefObjective"));

	TextDrawSetString(DMG_TEAM_MESSAGE_INFO_ENG[ATTACK], GetSVarStringEx("AttMessageBoxEng"));
	TextDrawSetString(DMG_TEAM_MESSAGE_INFO_ENG[DEFENSE], GetSVarStringEx("DefMessageBoxEng"));

	TextDrawSetString(DMG_TEAM_OBJECTIVE_ENG[ATTACK], GetSVarStringEx("AttObjectiveEng"));
	TextDrawSetString(DMG_TEAM_OBJECTIVE_ENG[DEFENSE], GetSVarStringEx("DefObjectiveEng"));

	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[ATTACK], GetSVarStringEx("TeamOneName"));
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[DEFENSE], GetSVarStringEx("TeamTwoName"));
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[2], GetSVarStringEx("TeamOneNameEng"));
	TextDrawSetString(DMG_TEXTDRAW_TEAM_NAME[3], GetSVarStringEx("TeamTwoNameEng"));

	SecondTimer = SetTimer("OneSecondUpdate", 1000, true);
	return true;
}

public OnFilterScriptExit()
{
	KillTimer(SecondTimer);
	KillTimer(CHECKPOINT_TIMER);
	return true;
}

forward OneSecondUpdate();
public OneSecondUpdate()
{
	if(GetSVarInt("GamemodeStatus") == DMG_STATUS_PLAYING_ROUND)
	{
		// Players Update
		new k = GetPlayerPoolSize();
		for(new i = 0; i <= k; i++)
		{
		    if(GetSVarInt("AttackInCP") == 1)
		        PlayerPlaySound(i, 1133, 0.0, 0.0, 0.0);

		    // Player Markers e Nametags

			for(new j = 0; j <= k; j++)
			{
                if(GetSVarInt("MarkerType") == 1)
                {
                    if(GetPVarInt(i, "PlayerTeam") == GetPVarInt(j, "PlayerTeam"))
                    {
						SetPlayerMarkerForPlayer(i, j, GetPlayerColor(j));
					}
					else
					{
		    			SetPlayerMarkerForPlayer(i, j, GetPlayerColor(j) & 0xFFFFFF00);
					}
				}
				else if(GetSVarInt("MarkerType") == 2)
				{
				    SetPlayerMarkerForPlayer(i, j, GetPlayerColor(j));
				}
				else if(GetSVarInt("MarkerType") == 0)
				{
				    SetPlayerMarkerForPlayer(i, j, GetPlayerColor(j) & 0xFFFFFF00);
				}
			}
		}
	}
}

forward EndMinigame();
public EndMinigame()
{
    new str[100];
	SetSVarInt("GamemodeStatus", DMG_STATUS_END_ROUND);

	SendClientMessageToAll(COLOR_ORANGE, "");
	
	LoopPlayer(i)
	{
	    if(PlayerLang(i) == 0)
	    {
			format(str, sizeof str, "Minigame '%s' finalizado!", GetSVarStringEx("MinigameName"));
			SendClientMessage(i, COLOR_ORANGE, str);
		}
	    else if(PlayerLang(i) == 1)
	    {
			format(str, sizeof str, "Minigame '%s' over!", GetSVarStringEx("MinigameName"));
			SendClientMessage(i, COLOR_ORANGE, str);
		}
	}

	if(GetSVarInt("EndMinigameType") == END_CHECKPOINT)
	{
		LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "A equipe '%s' vence por dominar o checkpoint.", GetSVarStringEx("TeamOneName"));
		    else if(PlayerLang(i) == 1) format(str, sizeof str, "Team '%s' wins the minigame because capture checkpoint.", GetSVarStringEx("TeamOneName"));
			SendClientMessage(i, COLOR_WHITE, str);
		}
	}
	else if(GetSVarInt("EndMinigameType") == LOST_TIME)
	{
		LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "A equipe '%s' vence por o tempo do minigame ter acabado.", GetSVarStringEx("TeamTwoName"));
		    else if(PlayerLang(i) == 1) format(str, sizeof str, "Team '%s' wins minigame because the time is up.", GetSVarStringEx("TeamTwoName"));
			SendClientMessage(i, COLOR_WHITE, str);
		}
	}
	else if(GetSVarInt("EndMinigameType") == TEAM_ONE_KILLS)
	{
		LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "A equipe '%s' vence por matar todos da equipe '%s'.", GetSVarStringEx("TeamOneName"), GetSVarStringEx("TeamTwoName"));
		    else if(PlayerLang(i) == 1) format(str, sizeof str, "Team '%s' wins because kills all players of team '%s'.", GetSVarStringEx("TeamOneName"), GetSVarStringEx("TeamTwoName"));
			SendClientMessage(i, COLOR_WHITE, str);
		}
	}
	else if(GetSVarInt("EndMinigameType") == TEAM_TWO_KILLS)
	{
		LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "A equipe '%s' vence por defender o checkpoint.", GetSVarStringEx("TeamTwoName"));
		    else if(PlayerLang(i) == 1) format(str, sizeof str, "Team '%s' wins for defending checkpoint.", GetSVarStringEx("TeamTwoName"));
			SendClientMessage(i, COLOR_WHITE, str);
		}
	}

    if(GetSVarInt("EndMinigameType") == END_CHECKPOINT)
    {
    	LoopPlayer(i)
		{
		    if(PlayerLang(i) == 0) format(str, sizeof str, "'%s' foi o melhor player e escolherá o próximo minigame.", GetPVarStringEx(GetSVarInt("PlayerInCP"), "PlayerName"));
		    else if(PlayerLang(i) == 1) format(str, sizeof str, "'%s' was the best player and choose next minigame.", GetPVarStringEx(GetSVarInt("PlayerInCP"), "PlayerName"));
			SendClientMessage(i, COLOR_WHITE, str);
        }
		SendClientMessageToAll(COLOR_WHITE, "");
		
		SetSVarInt("TopPlayerID", GetSVarInt("PlayerInCP"));
		CallRemoteFunction("ShowDialogVoteMiniGame2", "d", GetSVarInt("PlayerInCP"));

		SetPVarInt(GetSVarInt("PlayerInCP"), "PlayerWinsCP", GetPVarInt(GetSVarInt("PlayerInCP"), "PlayerWinsCP")+1);
	}
	else
	{
		if(GetSVarInt("TopPlayerID") != -1 && IsPlayerConnected(GetSVarInt("TopPlayerID")) &&
		    GetPVarInt(GetSVarInt("TopPlayerID"), "PlayerPlayedRound") == 1)
		{
			LoopPlayer(i)
			{
			    if(PlayerLang(i) == 0) format(str, sizeof str, "'%s' foi o melhor player e escolherá o próximo minigame.", GetPVarStringEx(GetSVarInt("TopPlayerID"), "PlayerName"));
			    else if(PlayerLang(i) == 1) format(str, sizeof str, "'%s' was the best player and choose next minigame.", GetPVarStringEx(GetSVarInt("TopPlayerID"), "PlayerName"));
				SendClientMessage(i, COLOR_WHITE, str);
		    }
			SendClientMessageToAll(COLOR_WHITE, "");
			
			CallRemoteFunction("ShowDialogVoteMiniGame2", "d", GetSVarInt("TopPlayerID"));
		}
		else
		{
		    CallRemoteFunction("RandomDialogMinigame", "d", 1);
		}
	}

	for(new i = 0, k = GetPlayerPoolSize(); i <= k; i++)
	{
		if(GetSVarInt("EndMinigameType") == END_CHECKPOINT || GetSVarInt("EndMinigameType") == TEAM_ONE_KILLS)
		{
			if(GetPVarInt(i, "PlayerTeam") == ATTACK && GetPVarInt(i, "PlayerPlayedRound") == 1)
			{
				SetPVarInt(i, "PlayerWinsMG", GetPVarInt(i, "PlayerWinsMG")+1);
				if(PlayerLang(i) == 0) GameTextForPlayer(i, "~y~Missao Completa!", 3000, 0);
				else if(PlayerLang(i) == 1) GameTextForPlayer(i, "~y~Mission Complete!", 3000, 0);
			}
			else if(GetPVarInt(i, "PlayerTeam") == DEFENSE)
			{
			    if(PlayerLang(i) == 0) GameTextForPlayer(i, "~r~Missao Falhada!", 3000, 0);
			    else if(PlayerLang(i) == 0) GameTextForPlayer(i, "~r~Mission Fail!", 3000, 0);
			}
		}
		else if(GetSVarInt("EndMinigameType") == LOST_TIME || GetSVarInt("EndMinigameType") == TEAM_TWO_KILLS)
		{
		    if(GetPVarInt(i, "PlayerTeam") == DEFENSE && GetPVarInt(i, "PlayerPlayedRound") == 1)
		    {
		        SetPVarInt(i, "PlayerWinsMG", GetPVarInt(i, "PlayerWinsMG")+1);
				if(PlayerLang(i) == 0) GameTextForPlayer(i, "~y~Missao Completa!", 3000, 0);
				else if(PlayerLang(i) == 1) GameTextForPlayer(i, "~y~Mission Complete!", 3000, 0);
			}
			else if(GetPVarInt(i, "PlayerTeam") == ATTACK)
			{
			    if(PlayerLang(i) == 0) GameTextForPlayer(i, "~r~Missao Falhada!", 3000, 0);
			    else if(PlayerLang(i) == 0) GameTextForPlayer(i, "~r~Mission Fail!", 3000, 0);
			}
		}

		PlayerPlaySound(i, 1097, 0.0, 0.0, 0.0);
	}
}

public OnPlayerSpawn(playerid)
{
    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[0]);
	TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[1]);
	TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[2]);
	TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[3]);

	// Minigame já se iniciou...
	if(GetSVarInt("GamemodeStatus") == DMG_STATUS_PLAYING_ROUND 		||
       GetSVarInt("GamemodeStatus") == DMG_STATUS_END_ROUND)
	{
	    SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_END_ROUND);
	    CallRemoteFunction("SetPlayerSpec", "d", playerid);
		//SetPlayerSpec(playerid);
		SetPlayerColor(playerid, SPEC_COLOR);
	}
	// Esperando começar o minigame...
	else if(GetSVarInt("GamemodeStatus") == DMG_STATUS_WAITING_ROUND)
	{
	    SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_WAITING_ROUND);
	    SetPVarInt(playerid, "PlayerPlayedRound", 1);

	    SetPlayerCheckpoint(playerid, GetSVarFloat("CheckpointPosX"), GetSVarFloat("CheckpointPosY"), GetSVarFloat("CheckpointPosZ"), 2.0);

        SetPlayerTeam(playerid, GetPVarInt(playerid, "PlayerTeam"));

		if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
		{
		    SetSVarInt("TeamOneAlive", GetSVarInt("TeamOneAlive")+1);
		    SetSVarInt("TeamOneStart", GetSVarInt("TeamOneStart")+1);

			if(GetPVarInt(playerid, "PlayerLang") == 0)
			{
				TextDrawShowForPlayer(playerid, DMG_TEAM_OBJECTIVE[ATTACK]);
				TextDrawShowForPlayer(playerid, DMG_TEAM_MESSAGE_INFO[ATTACK]);
			}
			else
			{
				TextDrawShowForPlayer(playerid, DMG_TEAM_OBJECTIVE_ENG[ATTACK]);
				TextDrawShowForPlayer(playerid, DMG_TEAM_MESSAGE_INFO_ENG[ATTACK]);
			}
			SetTimerEx("HideTeamObjectiveTextForPlayer", 5000, false, "dd", playerid, ATTACK);
			SetTimerEx("HideTeamMessageBoxTextForPlayer", 10000, false, "dd", playerid, ATTACK);
		}
		else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE)
		{
		    SetSVarInt("TeamTwoAlive", GetSVarInt("TeamTwoAlive")+1);
		    SetSVarInt("TeamTwoStart", GetSVarInt("TeamTwoStart")+1);

			if(GetPVarInt(playerid, "PlayerLang") == 0)
			{
				TextDrawShowForPlayer(playerid, DMG_TEAM_OBJECTIVE[DEFENSE]);
				TextDrawShowForPlayer(playerid, DMG_TEAM_MESSAGE_INFO[DEFENSE]);
			}
			else
			{
				TextDrawShowForPlayer(playerid, DMG_TEAM_OBJECTIVE_ENG[DEFENSE]);
				TextDrawShowForPlayer(playerid, DMG_TEAM_MESSAGE_INFO_ENG[DEFENSE]);
			}

			SetTimerEx("HideTeamObjectiveTextForPlayer", 5000, false, "dd", playerid, DEFENSE);
			SetTimerEx("HideTeamMessageBoxTextForPlayer", 10000, false, "dd", playerid, DEFENSE);
		}
		SetCameraBehindPlayer(playerid);
		
		if(GetPVarInt(playerid, "PlayerVip") == 1)
			CallRemoteFunction("SetArmour", "if", playerid, 100.0);
	}
	return true;
}

public OnPlayerRequestClass(playerid, classid)
{
    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[0]);
    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[1]);
    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[2]);
    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[3]);
    
	if(classid == ATTACK)
	{
	    SetPVarInt(playerid, "PlayerTeam", ATTACK);
	    if(PlayerLang(playerid) == 0)
	    {
		    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[DEFENSE]);
	        TextDrawShowForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[ATTACK]);
		}
	    else if(PlayerLang(playerid) == 1)
	    {
		    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[3]);
	        TextDrawShowForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[2]);
		}
	}
	else if(classid == DEFENSE)
	{
	    SetPVarInt(playerid, "PlayerTeam", DEFENSE);
	    if(PlayerLang(playerid) == 0)
	    {
		    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[ATTACK]);
	        TextDrawShowForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[DEFENSE]);
		}
	    else if(PlayerLang(playerid) == 1)
	    {
		    TextDrawHideForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[2]);
	        TextDrawShowForPlayer(playerid, DMG_TEXTDRAW_TEAM_NAME[3]);
		}
	}

	return true;
}

public OnPlayerEnterCheckpoint(playerid)
{
	// Checkpoint Timer, padrão para todos os Minigames A/D
	// Favor não alterar se não souber o que está fazendo...
    if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
    {
        if(GetSVarInt("AttackInCP") == 0)
        {
            new str[100];
            SetSVarInt("AttackInCP", 1);
            SetSVarInt("PlayerInCP", playerid);

			LoopPlayer(i)
			{
			    if(PlayerLang(i) == 0) format(str, sizeof str, "%s está capturando o checkpoint.", GetPVarStringEx(playerid, "PlayerName"));
			    else if(PlayerLang(i) == 1) format(str, sizeof str, "%s is capturing checkpoint.", GetPVarStringEx(playerid, "PlayerName"));
	            SendClientMessageToAll(COLOR_ORANGE, str);
			}
            CHECKPOINT_TIMER = SetTimer("CheckPointTimer", 1000, true);
		}
	}

	return true;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	// Checkpoint Timer, padrão para todos os Minigames A/D
	// Favor não alterar se não souber o que está fazendo...
	if(GetSVarInt("AttackInCP") == 1)
	{
		if(playerid == GetSVarInt("PlayerInCP"))
		{
		    KillTimer(CHECKPOINT_TIMER);

		    SetSVarInt("CheckpointTime", AAD_CHECKPOINT_TIME);
		    SetSVarInt("AttackInCP", 0);
		    SetSVarInt("PlayerInCP", INVALID_PLAYER_ID);
		}
	}
	return true;
}

forward CheckPointTimer();
public CheckPointTimer()
{
	SetSVarInt("CheckpointTime", GetSVarInt("CheckpointTime")-1);
	if(GetSVarInt("CheckpointTime") <= 0)
	{
	    KillTimer(CHECKPOINT_TIMER);

		SetSVarInt("EndMinigameType", END_CHECKPOINT);
		EndMinigame();
	}
}

forward OnPlayerDeath_Data(playerid, killerid, reason);
public OnPlayerDeath_Data(playerid, killerid, reason)
{
	if(killerid != INVALID_PLAYER_ID)
	{
	    if(GetPVarInt(killerid, "PlayerTeam") == ATTACK)
	        SetSVarInt("TeamOneKills", GetSVarInt("TeamOneKills")+1);
	    else if(GetPVarInt(killerid, "PlayerTeam") == DEFENSE)
	        SetSVarInt("TeamTwoKills", GetSVarInt("TeamTwoKills")+1);

    	if(GetPVarInt(playerid, "PlayerStatus") == DMG_STATUS_PLAYING_ROUND)
    	{
    	    SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_END_ROUND);

		    if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
		        SetSVarInt("TeamOneAlive", GetSVarInt("TeamOneAlive")-1);
		    else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE)
		        SetSVarInt("TeamTwoAlive", GetSVarInt("TeamTwoAlive")-1);
		}
	}
	else
	{
    	if(GetPVarInt(playerid, "PlayerStatus") == DMG_STATUS_PLAYING_ROUND)
    	{
    	    SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_END_ROUND);

            SendClientMessage(playerid, -1, "tste");
		    if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
		        SetSVarInt("TeamOneAlive", GetSVarInt("TeamOneAlive")-1);
		    else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE)
		        SetSVarInt("TeamTwoAlive", GetSVarInt("TeamTwoAlive")-1);
		}
	}
}

public OnPlayerDisconnect(playerid, reason)
{
    if(GetPVarInt(playerid, "PlayerPlayedRound") == 1)
    {
        SetPVarInt(playerid, "PlayerStatus", DMG_STATUS_END_ROUND);
        if(GetPVarInt(playerid, "PlayerTeam") == ATTACK)
            SetSVarInt("TeamOneAlive", GetSVarInt("TeamOneAlive")-1);
        else if(GetPVarInt(playerid, "PlayerTeam") == DEFENSE)
            SetSVarInt("TeamTwoAlive", GetSVarInt("TeamTwoAlive")-1);
	}
	return true;
}

/*
	Deathmatch Minigames
	    por Roger Costa
	    
	Novas funções criadas pro minigame
*/

forward HideTeamObjectiveTextForPlayer(playerid, team);
public HideTeamObjectiveTextForPlayer(playerid, team)
{
	if(PlayerLang(playerid) == 0) TextDrawHideForPlayer(playerid, DMG_TEAM_OBJECTIVE[team]);
	else TextDrawHideForPlayer(playerid, DMG_TEAM_OBJECTIVE_ENG[team]);
}

forward HideTeamMessageBoxTextForPlayer(playerid, team);
public HideTeamMessageBoxTextForPlayer(playerid, team)
{
    if(PlayerLang(playerid) == 0) TextDrawHideForPlayer(playerid, DMG_TEAM_MESSAGE_INFO[team]);
    else TextDrawHideForPlayer(playerid, DMG_TEAM_MESSAGE_INFO_ENG[team]);
}

stock GetSVarStringEx(var_name[])
{
	new name[128];
	GetSVarString(var_name, name, sizeof name);
	return name;
}

stock GetPVarStringEx(playerid, var_name[])
{
	new name[50];
	GetPVarString(playerid, var_name, name, sizeof name);
	return name;
}
