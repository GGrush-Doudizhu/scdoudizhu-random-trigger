-- Options
defeatedPlayerToOB = true  -- true: keep the player in the game, false: defeat()
defeatedPlayerRemoveUnit = true  -- true: remove all his units, false: give his units to P12
teammatesMinimapPing = false  -- true: 开局小地图ping队友位置

-- Algorithm
--[[
第一轮扫触发根据玩家总数来使用8个variables辅助分组，记为vars[]数组。变量N和temp的取值都为玩家数量n，其中temp为辅助变量
若N=2，则仅使用vars[]的前2个，分别取值0,1
若N=3，则仅使用vars[]的前3个，分别取值0,1,2
若N=4，则仅使用vars[]的前4个，分别取值0,0,1,1
若N=5，则仅使用vars[]的前5个，分别取值0,0,1,1,2
若N=6，则仅使用vars[]的前6个，分别取值0,0,0,1,1,1
若N=7，则仅使用vars[]的前7个，分别取值0,0,0,1,1,1,2
若N=8，则仅使用vars[]的前8个，分别取值0,0,0,0,1,1,1,1
用随机swap算法来给它们做random shuffle (Fisher-Yates Shuffle)，（以N=7为例）最终的结果可能为[1, 0, 1, 1, 0, 2, 0]
0: team1, custom score = 1
1: team2, custom score = 2
2: OB, custom score = 0
为何不让1代表team1、2代表team2、0代表OB： 要尽量让vars的取值为0或1，这样可以节省swap时所需要的触发数。

第二轮扫触发： （以N=7为例）
AllPlayers:
condition {N==7 && temp==7 && vars[7]==2} Action {CurrentPlayer 的 CustomScore 设为 0}
condition {N==7 && temp==7 && vars[7]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==7 && temp==7 && vars[7]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
condition {N==7 && temp==6 && vars[7]==2} Action {CurrentPlayer 的 CustomScore 设为 0}
condition {N==7 && temp==6 && vars[7]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==7 && temp==5 && vars[7]==2} Action {CurrentPlayer 的 CustomScore 设为 2}
condition {N==7 && temp==5 && vars[7]==1} Action {CurrentPlayer 的 CustomScore 设为 0}
condition {N==7 && temp==5 && vars[7]==0} Action {CurrentPlayer 的 CustomScore 设为 1}
...
condition {N==7 && temp==1 && vars[1]==2} Action {CurrentPlayer 的 CustomScore 设为 0}
condition {N==7 && temp==1 && vars[1]==1} Action {CurrentPlayer 的 CustomScore 设为 1}
condition {N==7 && temp==1 && vars[1]==0} Action {CurrentPlayer 的 CustomScore 设为 2}
其他N同理
最后 AllPlayers: Action {temp -= 1}

第三轮扫触发：
与所有随机分组算法的最后一步一样，CustomScore为1的玩家相互结盟给视野，为2的玩家相互结盟给视野，为0的玩家获得其他所有玩家视野
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
customScore_OB = 0
customScore_Unassigned = 3
flag2customScore = {
    [0] = 2,  -- team 2
    [1] = 1,  -- team 1
    [2] = customScore_OB,  -- OB
}


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
"\4总共3位玩家，随机抽取一名OB，开始1v1", 
"\4总共4位玩家，开始2v2", 
"\4总共5位玩家，随机抽取一名OB，开始2v2", 
"\4总共6位玩家，开始3v3", 
"\4总共7位玩家，随机抽取一名OB，开始3v3",
"\4总共8位玩家，开始4v4"}
youAreOB = "您已成为OB，请安静观看，严禁通风报信"

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
		SetScore(CurrentPlayer, SetTo, customScore_Unassigned, Custom);
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
    {0, 1, 2},
    {0, 0, 1, 1},
    {0, 0, 1, 1, 2},
    {0, 0, 0, 1, 1, 1},
    {0, 0, 0, 1, 1, 1, 2},
    {0, 0, 0, 0, 1, 1, 1, 1}
}
for i, teamflag in ipairs(teamsFlags) do  -- N in {2,3,4,5,6,7,8}
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
Trigger { -- less than 2 players. Draw
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, Exactly, assignTeam),
        VarComp(numPlayers, AtMost, 1),
    },
    actions = {
        DisplayText(gameModePops[1]);
        Draw();
    },
}

for i = 2, 8 do  -- Set game mode, draw, 1v1, 1v1+1OB, 2v2, 2v2+1OB, ...
    Trigger {
        players = {AllPlayers},
        conditions = {
            VarComp(timeCounter, Exactly, assignTeam),
            VarComp(numPlayers, Exactly, i)
        },
        actions = {
            DisplayText(gameModePops[i]);
        },
    }
end


for N = 2, 8 do  -- for N in {2,3,4,5,6,7,8}, Set custom score
    for ntemp = N, 1, -1 do
        for flg = 0, 2 do  -- flag = 0 or 1 or 2
            if (N % 2 == 1 or (N % 2 == 0 and flg < 2)) then  -- If 奇数, flg=0,1,2, 偶数则flg=0,1
                Trigger {
                    players = {AllPlayers},
                    conditions = {
                        VarComp(timeCounter, Exactly, assignTeam),
                        VarComp(numPlayers, Exactly, N),
                        VarComp(numPlayersTemp, Exactly, ntemp),
                        VarComp(vars[ntemp], Exactly, flg),
                    },
                    actions = {
                        SetScore(CurrentPlayer, SetTo, flag2customScore[flg], Custom),
                    },
                }
            end
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

ActPing = {}
if teammatesMinimapPing then
    ActPing = {MinimapPing(playerStartLocs[i])}
end

for tm = 1, 2 do
    for i = 1, 8 do 
        Trigger {
            players = {AllPlayers},
            conditions = {
                VarComp(timeCounter, Exactly, allyVision),
                Score(CurrentPlayer, Custom, Exactly, tm);
                Score(i - 1, Custom, Exactly, tm);
            },
            actions = {
                SetAllianceStatus(i - 1, AlliedVictory),
                ActPing,
                RunAIScript("Turn ON Shared Vision for Player " .. i),
            },
        }
    end
end

Trigger { -- Remove all units of OB players and give vision
    players = {AllPlayers},
    conditions = {
        VarComp(timeCounter, Exactly, allyVision);
        Score(CurrentPlayer, Custom, Exactly, customScore_OB);
    },
    actions = {
        RemoveUnit("Any unit", CurrentPlayer);
        DisplayText(youAreOB);
        RunAIScript("Turn ON Shared Vision for Player 1");
        RunAIScript("Turn ON Shared Vision for Player 2");
        RunAIScript("Turn ON Shared Vision for Player 3");
        RunAIScript("Turn ON Shared Vision for Player 4");
        RunAIScript("Turn ON Shared Vision for Player 5");
        RunAIScript("Turn ON Shared Vision for Player 6");
        RunAIScript("Turn ON Shared Vision for Player 7");
        RunAIScript("Turn ON Shared Vision for Player 8");
    },
}

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
        Score(CurrentPlayer, Custom, AtLeast, 1),  -- not OB player
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

