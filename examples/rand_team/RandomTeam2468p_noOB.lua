-- Options
defeatedPlayerToOB = true  -- true: keep the player in the game, false: defeat()
defeatedPlayerRemoveUnit = false  -- true: remove all his units, false: give his units to P12

-- Algorithm
--[[
第一轮扫触发根据玩家总数来使用8个variables辅助分组，记为vars[]数组。变量N和temp的取值都为玩家数量n，其中temp为辅助变量
若N=2，则仅使用vars[]的前2个，分别取值1,0
若N=4，则仅使用vars[]的前4个，分别取值1,1,0,0
若N=6，则仅使用vars[]的前6个，分别取值1,1,1,0,0,0
若N=8，则仅使用vars[]的前8个，分别取值1,1,1,1,0,0,0,0
用随机swap算法来给它们做random shuffle (Fisher-Yates Shuffle)，（以N=6为例）最终的结果可能为[1, 0, 1, 1, 0, 0]

第二轮扫触发： （以N=6为例）
AllPlayers:
condition {N==6 && temp==6 && vars[6]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==6 && temp==6 && vars[6]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
condition {N==6 && temp==5 && vars[5]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==6 && temp==5 && vars[5]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
condition {N==6 && temp==4 && vars[4]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==6 && temp==4 && vars[4]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
...
condition {N==6 && temp==1 && vars[1]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==6 && temp==1 && vars[1]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
N=4,8 同理
最后 AllPlayers: Action {temp -= 1}

第三轮扫触发：
与所有随机分组算法的最后一步一样，CustomScore为1的玩家相互结盟给视野，为2的玩家相互结盟给视野
]]

timeCounter = {p = CurrentPlayer, u = Critters[1]}
numPlayers = {p = P1, u = Critters[2]}
numPlayersTemp = {p = P2, u = Critters[2]}
vars = {
    {p = P1, u = Critters[3]},
    {p = P2, u = Critters[3]},
    {p = P3, u = Critters[3]},
    {p = P4, u = Critters[3]},
    {p = P5, u = Critters[3]},
    {p = P6, u = Critters[3]},
    {p = P7, u = Critters[3]},
    {p = P8, u = Critters[3]},
}
rand_var = {p = P3, u = Critters[2]}
buffer_var = {p = P4, u = Critters[2]}


-- Score custom
teamOB = 0
teamNum = {1, 2}
teamUnassigned = 3


-- phases (time counter value)
initialization = 1
randomization = 1
assignTeam = 2
allyVision = 3
startGame = 4
totalPhases = 4


-- Switches
s_random = 100
nRandSwitchUsed = 10


-- Locations
playerStartLocs = {
    "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8"
}

-- Strings
str_leaderboard = "作者PereC"
gameModePops = {
"\4玩家总数少于2人，无法分组，请重新开始", 
"\4总共2位玩家，开始1v1", 
"\4总共3位玩家，无法分组，请重新开始", 
"\4总共4位玩家，开始2v2", 
"\4总共5位玩家，无法分组，请重新开始", 
"\4总共6位玩家，开始3v3",  
"\4总共7位玩家，无法分组，请重新开始", 
"\4总共8位玩家，开始4v4"}
-- youAreOB = "您已成为OB，请安静观看，严禁通风报信"

--------------------------------------------------------------
--Phase 1, initial settings.
--------------------------------------------------------------

-- Phase 1.1, time control and basics.
Trigger {
    players = {AllPlayers},
    actions = {
        SetResources(CurrentPlayer, SetTo, 50, Ore);
        SetVar(numPlayers, Add, 1);
        SetVar(numPlayersTemp, Add, 1);
		SetScore(CurrentPlayer, SetTo, teamUnassigned, Custom);
        LeaderBoardScore(Custom, str_leaderboard);
    },
}

Trigger {
    players = {AllPlayers},
    actions = {
        Wait(0);
        Wait(0);
        Wait(0);
        Wait(0);
        Wait(0);
    },
}


Trigger {
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, AtMost, totalPhases);
    },
    actions = {
        SetVar(timeCounter, Add, 1)
    },
    flag = {preserved}
}

-- Phase 1.2, randomization
teamsFlags = {
    {0, 1},
    {0, 0, 1, 1},
    {0, 0, 0, 1, 1, 1},
    {0, 0, 0, 0, 1, 1, 1, 1}
}
for i, teamflag in ipairs(teamsFlags) do  -- N in {2,4,6,8}
    N = #teamflag
    vars_used = {}
    for j = 1, N do
        vars_used[j] = vars[j]
    end
    
    RandAssign{
        trgPlayer = AllPlayers,
        trgCon = {
            VarComp(timeCounter, Exactly, randomization),
            VarComp(numPlayers, Exactly, N)
        },
        varlist = vars_used,
        numlist = teamflag,
        rand_startSwitch = s_random,
        rand_nSwitch = nRandSwitchUsed,
        randVar = rand_var,
        bufferVar = buffer_var
    }
end

--------------------------------------------------------------
-- Phase 2, Set custom score according to randomization result
--------------------------------------------------------------
for i = 1, 8 do  -- Set game mode, draw, 1v1, draw, 2v2, ...
    if i % 2 == 0 then  -- Even number, can play
        Trigger { -- 1v1, 2v2, 3v3, 4v4
            players = {AllPlayers},
            conditions = {
                VarComp(timeCounter, Exactly, assignTeam),
                VarComp(numPlayers, Exactly, i)
            },
            actions = {
                DisplayText(gameModePops[i]);
            },
        }
    else 
        Trigger { -- Draw, please restart
            players = {AllPlayers},
            conditions = {
                VarComp(timeCounter, Exactly, assignTeam),
                VarComp(numPlayers, Exactly, i)
            },
            actions = {
                DisplayText(gameModePops[i]);
                Draw();
            },
        }
        
    end
end


for N = 2, 8, 2 do  -- for N in {2, 4, 6, 8}, Set custom score
    for ntemp = N, 1, -1 do
        for flg = 0, 1 do
            Trigger {
                players = {AllPlayers},
                conditions = {
                    VarComp(timeCounter, Exactly, assignTeam),
                    VarComp(numPlayers, Exactly, N),
                    VarComp(numPlayersTemp, Exactly, ntemp),
                    VarComp(vars[ntemp], Exactly, flg),
                },
                actions = {
                    SetScore(CurrentPlayer, SetTo, teamNum[2 - flg], Custom),
                },
            }
        end
    end
end

Trigger {  -- Subtract numPlayersTemp
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, Exactly, assignTeam),
    },
    actions = {
        SetVar(numPlayersTemp, Subtract, 1),
    },
}

--------------------------------------------------------------
-- Phase 3, Ally and give vision according to Custom Score
--------------------------------------------------------------
Trigger {  -- Debug: computers unally
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, Exactly, allyVision),
    },
    actions = {
        SetAllianceStatus(Force1, Enemy);
    },
}
        
for tm = 1, 2 do
    for i = 1, 8 do 
        Trigger {
            players = {AllPlayers},
            conditions = {
                VarComp(timeCounter, Exactly, allyVision),
                Score(CurrentPlayer, Custom, Exactly, teamNum[tm]);
                Score(i - 1, Custom, Exactly, teamNum[tm]);
            },
            actions = {
                SetAllianceStatus(i - 1, AlliedVictory);
                MinimapPing(playerStartLocs[i]);
                RunAIScript("Turn ON Shared Vision for Player " .. i);
            },
        }
    end
end

--------------------------------------------------------------
-- Phase 4, Game Start
--------------------------------------------------------------
defeatedAction = {
    Defeat();
}

if defeatedPlayerToOB then
    defeatedAction = {
		DisplayText(youAreOB);
    }
    if defeatedPlayerRemoveUnit then
        defeatedAction = {
            defeatedAction,
            RemoveUnit("Any unit", CurrentPlayer);
        }
    else
        defeatedAction = {
            defeatedAction,
            GiveUnits(All, "Any unit", CurrentPlayer, "Anywhere", P12) 
        }
    end
end


Trigger {
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, AtLeast, startGame),
        Command(CurrentPlayer, AtMost, 0, "Buildings"),
    },
    actions = {
        defeatedAction
    },
}

Trigger {
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, AtLeast, startGame),
        Command(NonAlliedVictoryPlayers, AtMost, 0, "Buildings"),
    },
    actions = {
        Victory();
    },
}

