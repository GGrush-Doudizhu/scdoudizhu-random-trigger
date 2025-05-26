-- Options
defeatedPlayerToOB = true  -- true: keep the player in the game, false: defeat()
defeatedPlayerRemoveUnit = false  -- true: remove all his units, false: give his units to P12

-- Algorithm (由Ar3gice提出)
--[[
N为玩家总数、numUnassigned是当前还未被分配队伍的玩家个数(一开始也设为玩家总数)。
teamIdentifier: CurrentPlayer Custom Score，标记每个玩家是否被分了组以及被分到哪个组：
0: OB
1: team1
2: team2
3: 未被分组

第1轮扫触发:
数玩家总数。
每个玩家的一个Score变量（除了Custem Score之外的任意一个score变量，记作randScore）取随机数(范围是1至0x80000000, 使用31个switch)，得到8个随机数
为什么让随机数的最小取值为1而不是0: 如果随机数的取值范围包含0，那么可能出现的极端情况就是有玩家的score随机到0，这样的话其它玩家score清零之后仍可能是HighestScore, 导致算法失败。

第2至x轮扫触发(x可能为2到6的任何值)：用HighestScore()，以N=7为例，写以下7个触发 (AllPlayers):
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==7 && HighestScore(randScore.s)} actions {CurrentPlayer设为OB, randScore=0, numUnassigned-=1}
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==6 && HighestScore(randScore.s)} actions {CurrentPlayer设为1队, randScore=0, numUnassigned-=1}
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==5 && HighestScore(randScore.s)} actions {CurrentPlayer设为1队, randScore=0, numUnassigned-=1}
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==4 && HighestScore(randScore.s)} actions {CurrentPlayer设为1队, randScore=0, numUnassigned-=1}
注：剩下的3个玩家不需要判定HighestScore，可以直接全部归为2队
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==3} actions {CurrentPlayer设为2队, randScore=0, numUnassigned-=1}
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==2} actions {CurrentPlayer设为2队, randScore=0, numUnassigned-=1}
Conditions {触发轮数>=2 && Curpl未被分组 && N==7 && numUnassigned==1} actions {CurrentPlayer设为2队, randScore=0, numUnassigned-=1}
以上过程最快1轮触发即可完成：即前N/2+1名高的randScore刚好是最前面的player且刚好单调递减（可有相同值）时，
最慢需要N/2 + 1轮：即当前N/2+1名高的randScore刚好严格单调递增时

numUnassigned==0时：
与所有随机分组算法的最后一步一样，CustomScore为1的玩家相互结盟给视野，为2的玩家相互结盟给视野，为0的玩家获得其他所有玩家视野

此算法的优点是，任意两个玩家被分到同一组的概率都是相同的。而现存的很多“伪随机分组”地图，P1P2被分到同一组的概率是P3P4被分到同一组的概率的若干倍
此算法是真正的随机分组的原因是玩家的分组情况仅取决于随机数randScore的排名
以N=7为例，randScore最高的玩家永远是OB，第234高的玩家永远是1队，最低的3名的玩家永远是2队
注意，当若干名玩家randScore并列第一时，星际判定playerID小的玩家是HighestScore，然而我们的randScore取值范围非常大，且是均匀分布，所以出现两个玩家score相同的概率小于28/(2^31)，数量级在10^-8，几乎为0 
所以每个玩家的score排名是完全随机且均等的，以N=7为例，总共P(7, 7)=7!=5040种排名情况，每种情况的概率都相同。


举例:
例1:
P2不在场，P1,P3,45678的randScore分别是: 7777, 6666, 6666, 5555, 3333, 2222, 4444
则前4高(7/2+1=4)的score分别是7777, 6666, 6666, 5555，且是最前面的4个player，且单调递减, 所以只需要1轮触发即可完成：
第1轮扫触发: 计玩家个数,初始化等
第2轮扫触发时P1被判定为最高score (7777)，所以P1被分配到OB并score归零, numUnassigned减一变为6
然后执行P3触发，P3的6666此时就是最高分，P3被分配到1队并score归零, numUnassigned减一变为5
然后执行P4触发，P3的6666此时就是最高分，P4被分配到1队并score归零, numUnassigned减一变为4
然后执行P5触发，P3的5555此时就是最高分，P5被分配到1队并score归零, numUnassigned减一变为3
由于已经分配了4个玩家(7/2+1=4)，所以剩下的玩家直接被分到2队
所以执行P6 P7 P8触发时，这三个玩家就自动被分配到2队，执行完毕后numUnassigned变为0
然后P8执行共享视野、结盟触发
第3轮扫触发其他玩家开始共享视野、结盟，此轮触发执行完毕后，随机分组全部完成。

例2:
P2不在场，P1,P3,45678的randScore分别是: (P1)3333, (P3)5555, (P4)7777, (P5)6666, (P6)2222, (P7)6666, (P8)4444
则前4高(7/2+1=4)的score分别是(P3)5555, (P4)7777, (P5)6666, (P7)6666
第1轮扫触发: 计玩家个数,初始化等
第2轮扫触发时:
执行P1触发，P1的3333不是最高score,所以P1暂未被分队
执行P3触发，P3的5555不是最高score,所以P3暂未被分队
执行P4触发，P4是最高score 7777, 所以P4被分配到OB并score归零, numUnassigned减一变为6
执行P5触发，P5是最高score 6666，P5被分配到1队并score归零, numUnassigned减一变为5
执行P6触发，P6的2222不是最高score,所以P6暂未被分队
执行P7触发，P7是最高score 6666，P7被分配到1队并score归零, numUnassigned减一变为4
执行P8触发，P8的4444不是最高score,所以P8暂未被分队
第3轮扫触发时:
执行P1触发,发现P1的3333不是最高score,所以P1未被分队
执行P3触发,P3的5555正是此时最高score, 所以P3被分配到1队并score归零, numUnassigned减一变为3
由于已经分配了4个玩家(7/2+1=4)，所以剩下的玩家直接被分到2队
执行P4触发,P4已被分组，所以不执行任何action
执行P5触发,P5已被分组，所以不执行任何action
执行P6触发,P6被分到2队并score归零, numUnassigned减一变为2
执行P7触发,P7已被分组，所以不执行任何action
执行P8触发,P8被分到2队并score归零, numUnassigned减一变为1
第4轮扫触发时:
执行P1触发,P1被分到2队并score归零, numUnassigned减一变为0, 至此所有玩家都完成分队
此时刚好接着执行P1的结盟、共享视野触发。
然后是P3至P8的结盟、共享视野触发。
此轮触发执行完毕后，随机分组全部完成。
]]

timeCounter = {p = CurrentPlayer, u = Critters[1]}
numPlayers = {p = P1, u = Critters[2]}
numUnassigned = {p = P2, u = Critters[2]}
randScore = {p = CurrentPlayer, s = Razings}  -- Must be s Score variable
teamIdentifier = {p = CurrentPlayer, s = Custom}

-- Switches
s_random = 0


-- Score custom
customScore_OB = 0
customScore_Unassigned = 3  -- must be larger than any "assigned" state
flag2customScore = {
    [0] = 2,  -- team 2
    [1] = 1,  -- team 1
    [2] = customScore_OB,  -- OB
}


-- phases (time counter value)
Con1stTrigCycle = VarComp(timeCounter, Exactly, 1)
ConAtLeast2ndTrigCycle = VarComp(timeCounter, AtLeast, 2)
ConFinishAssignTeam = VarComp(numUnassigned, Exactly, 0)
allyVision = 3
startGame = 4
totalPhases = 4


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
        SetVar(numUnassigned, Add, 1);
		SetVar(teamIdentifier, SetTo, customScore_Unassigned);
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
        VarComp(timeCounter, AtMost, 2),
    },
	actions = {
		SetVar(timeCounter, Add, 1)
	},
	flag = {preserved}
}


TrgRandNumNbit(
	AllPlayers,
	Con1stTrigCycle,
	1,
	s_random,
	31, randScore,
	false)


--------------------------------------------------------------
-- Phase 2, Set team (custom score) according to randomization result
--------------------------------------------------------------
Trigger { -- less than 2 players. Draw
    players = {AllPlayers},
    conditions = {
        ConAtLeast2ndTrigCycle,
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
            ConAtLeast2ndTrigCycle,
            VarComp(numPlayers, Exactly, i)
        },
        actions = {
            DisplayText(gameModePops[i]);
        },
    }
end


teamsFlags = {
    {2, 1},
    {2, 1, 0},
    {2, 2, 1, 1},
    {2, 2, 1, 1, 0},
    {2, 2, 2, 1, 1, 1},
    {2, 2, 2, 1, 1, 1, 0},
    {2, 2, 2, 2, 1, 1, 1, 1}
}


for i, teamflag in ipairs(teamsFlags) do  -- N in {2,3,4,5,6,7,8}
    local N = #teamflag
    for ntemp = N, 1, -1 do
		local ConHighest = {}
		if ntemp > N // 2 then
			ConHighest = HighestScore(randScore.s)
		end
		Trigger {
			players = {AllPlayers},
			conditions = {
				ConAtLeast2ndTrigCycle,
				VarComp(teamIdentifier, AtLeast, customScore_Unassigned),  -- CurrentPlayer not yet assigned to any team
				VarComp(numPlayers, Exactly, N),  -- Total number of players is N
				VarComp(numUnassigned, Exactly, ntemp),  -- Number of players who are not yet assigned to any team
				ConHighest,  -- CurrentPlayer has the highest score
			},
			actions = {
				SetVar(teamIdentifier, SetTo, teamflag[ntemp]),
				SetVar(randScore, SetTo, 0),
				SetVar(numUnassigned, Subtract, 1)
			},
		}
    end
end

--------------------------------------------------------------
-- Phase 3, Ally and give vision according to Custom Score
--------------------------------------------------------------
Trigger {  -- Debug: computers unally
    players = {AllPlayers},
    conditions = {
		ConFinishAssignTeam,
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
                ConFinishAssignTeam,
                Score(CurrentPlayer, Custom, Exactly, tm);
                Score(i - 1, Custom, Exactly, tm);
            },
            actions = {
                SetAllianceStatus(i - 1, AlliedVictory),
                MinimapPing(playerStartLocs[i]),
                RunAIScript("Turn ON Shared Vision for Player " .. i),
            },
        }
    end
end

Trigger { -- Remove all units of OB players and give vision
    players = {AllPlayers},
    conditions = {
        ConFinishAssignTeam;
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
        ConFinishAssignTeam,
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
        ConFinishAssignTeam,
        Command(NonAlliedVictoryPlayers, AtMost, 0, "Buildings"),
    },
    actions = {
        Victory();
    },
}
