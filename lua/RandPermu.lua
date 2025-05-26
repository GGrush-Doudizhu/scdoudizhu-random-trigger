-- All variables should be in the form of {p = xxxplayer, u = xxxunit}
-- For example:
-- x = {p = P1, u = "Terran Marine"}
-- y = {p = 5, u = 226}

--[[
RandAssign({P6}, {Always()}, {0, 1, 2, 3}, {1, 2, 3, 4}, "Terran Ghost", ...) may result in:
P1's death of "Terran Ghost" = 3
P2's death of "Terran Ghost" = 1
P3's death of "Terran Ghost" = 4
P4's death of "Terran Ghost" = 2

Args:
varlist: list of variables to be assigned
numlist: list of number to assign, length must equal to length of varlist
"du": death unit
"rand_xxx": the arguments to be passed to TrgRandGen(...)
]]
function _RandAssign(trgPlayer, trgCon, varlist, numlist, rand_startSwitch, rand_nSwitch, randVar, bufferVar, preserve)
    if #varlist ~= #numlist then
        error(string.format("Length of varlist must equal to length of numlist. Got #varlist=%d, #numlist=%d", #varlist, #numlist))
        return
    end
    local n = #varlist
    if n > 64 then
        error("Size of numlist cannot be greater than 64.")
    end

    flag = {}
    if preserve then
        flag = {preserved}
    end
    
    -- Get max number in numlist:
    table.sort(numlist)
    maxnum = numlist[n]
    nbits = 0
    for mb = 0, 20 do
        if maxnum >= (1 << mb) then
            nbits = nbits + 1
        else break end
    end
    
    Trigger {
        players = trgPlayer,
        conditions = trgCon,
        actions = {
            -- Comment("Rand assign init"),
            SetVars(varlist, SetTo, numlist)
        },
        flag = flag
    }
    
    -- Fisher–Yates shuffle
    for i = 1, n-1 do
        TrgRandGen(trgPlayer, trgCon, n-i+1, rand_startSwitch, rand_nSwitch, randVar, preserve)
        -- if rand==1, do not swap; elseif rand==r, swap value of varlist[i] and varlist[i+r-1]
        for r = 2, n-i+1 do
            SwapValue(trgPlayer, {trgCon, VarComp(randVar, Exactly, r)}, nbits, varlist[i], varlist[i+r-1], bufferVar, preserve)
        end
    end
    
end


function RandAssign(args)
    if not args.trgPlayer then  -- trgPlayer is not provided
        error("trgPlayer is not provided.")
    end
    if not args.varlist then  -- varlist is not provided
        error("varlist is not provided.")
    end

    numlist_default = {}
    for i = 1, #args.varlist do
        numlist_default[i] = i
    end

    _RandAssign(
        args.trgPlayer, 
        args.trgCon or {}, 
        args.varlist, 
        args.numlist or numlist_default,
        args.rand_startSwitch or 200, 
        args.rand_nSwitch or 10, 
        args.randVar or {p=P1, u=226}, 
        args.bufferVar or {p=P2, u=226}, 
        args.preserve or false)
end
--SwapValue({P8}, {Always()}, 4, 0, 1, 1, 2, 5, 6)

--[[
varlist={
    {p=P1, u=1},
    {p=P2, u=1},
    {p=P3, u=1},
    {p=P4, u=1},
    {p=P5, u=1},
    {p=P6, u=1},
}
numlist={1,2,3,4,5,6}
RandPermuTime = 0
timer = {p=CurrentPlayer, u=200}

RandAssign{trgPlayer=P1, trgCon={VarComp(timer, Exactly, RandPermuTime)}, varlist=varlist, numlist=numlist,
    randVar={p=P1, u=Critters[1]}, bufferVar={p=P2, u=Critters[2]}}

for i = 1, #numlist do
    Trigger {
        players = {AllPlayers},
        conditions = {
            VarComp(timer, Exactly, RandPermuTime+1),
            Deaths(CurrentPlayer, Exactly, numlist[i], 1);
        },
        actions = {
            Comment("Set custom score");
            SetScore(CurrentPlayer, SetTo, numlist[i], Custom)
        }
    }
end

Trigger {
    players = {P1},
    actions = {
        LeaderBoardScore(Custom, "随机排列");
    },
}

Trigger {
    players = {AllPlayers},
    actions = {
        SetVar(timer, Add, 1)
    },
}
]]



-- test AllPlayers
--[[
uID = 20
varlist={
    {p=P1, u=uID},
    {p=P2, u=uID},
    {p=P3, u=uID},
    {p=P4, u=uID},
    {p=P5, u=uID},
    {p=P6, u=uID},
    {p=P7, u=uID},
    {p=P8, u=uID},
}
numlist={1,2,3,4,5,6,7,8}
timer = {p=CurrentPlayer, u=200}
alternate_count = {p=CurrentPlayer, u=201}

CreateLoopingTimer(AllPlayers, {}, alternate_count, 2)

RandAssign{trgPlayer=AllPlayers, trgCon={VarComp(alternate_count, Exactly, 1)}, varlist=varlist, numlist=numlist, preserve=true,
    randVar={p=P1, u=Critters[1]}, bufferVar={p=P2, u=Critters[2]}}

for i = 1, #numlist do
    Trigger {
        players = {AllPlayers},
        conditions = {
            VarComp(alternate_count, Exactly, 0),
            Deaths(CurrentPlayer, Exactly, numlist[i], uID);
        },
        actions = {
            Comment("Set custom score");
            SetScore(CurrentPlayer, SetTo, numlist[i], Custom)
        },
        flag = {preserved}
    }
end

Trigger {
    players = {P1},
    actions = {
        LeaderBoardScore(Custom, "Random Shuffle");
    },
}

Trigger {
    players = {AllPlayers},
    actions = {
        SetVar(timer, Add, 1)
    },
    flag = {preserved}
}

]]

--Test
-- resultDU = Critters[3]
-- maxBits = 3
-- startSw = 100
-- numSw = 20
-- rand_duOwner = 6
-- rand_du = Critters[2]
-- bufferOwner = 7
-- bufferUnit = Critters[2]
-- pList = {0,1,2,3,4,5,6,7}
-- numlist = {0,1,2,3,4,5,6,7}

-- RandAssign({AllPlayers}, {Deaths(CurrentPlayer, Exactly, RandPermuTime, timer)}, pList, numlist, resultDU, maxBits, startSw, numSw, rand_duOwner, rand_du, bufferOwner, bufferUnit)


--[[
for i = 1, #numlist do
    Trigger {
        players = {AllPlayers},
        conditions = {
            Deaths(CurrentPlayer, Exactly, RandPermuTime+1, timer);
            Deaths(CurrentPlayer, Exactly, numlist[i], resultDU);
        },
        actions = {
            Comment("Set custom score");
            SetScore(CurrentPlayer, SetTo, numlist[i], Custom)
        }
    }
end

Trigger {
    players = {P1},
    conditions = {
        Always();
    },
    actions = {
        LeaderBoardScore(Custom, "随机排列");
    },
}
]]
