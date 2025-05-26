-- Variables
--[[
A variable can be a death count, a score value, or a resource amount.
A variable is defined to be a table with two keys, the first key is "p", the other is "u" or "s" or "r"
If the 2 keys are "p" and "u", it's a death count.
If the 2 keys are "p" and "s", it's a score value.
If the 2 keys are "p" and "r", it's a resource amount.

The values that p, u, s, r can take:
p: any number from 0 to 26, or the corresponding player (player group) name:
    0 = P1
    1 = P2
    2 = P3
    3 = P4
    4 = P5
    5 = P6
    6 = P7
    7 = P8
    8 = P9
    9 = P10
    10 = P11
    11 = P12
    12 = (Unused)
    13 = CurrentPlayer
    14 = Foes
    15 = Allies
    16 = NeutralPlayers
    17 = AllPlayers
    18 = Force1
    19 = Force2
    20 = Force3
    21 = Force4
    22 = (Unused)
    23 = (Unused)
    24 = (Unused)
    25 = (Unused)
    26 = NonAlliedVictoryPlayers
See: 
http://www.staredit.net/wiki/index.php/Scenario.chk#List_of_Players.2FGroup_IDs
https://github.com/phu54321/TrigEditPlus/blob/master/Package/triggersyntax.txt

u: any number from 0 to 227, or the corresponding unit name string:
    0 = "Terran Marine"
    1 = "Terran Ghost"
    ...
    226 = "Vespene Tank (Terran Type 1)"
    227 = "Vespene Tank (Terran Type 2)"
    228 = "Unused unit 228"
    229 = "Any unit"
    230 = "Men"
    231 = "Buildings"
    232 = "Factories"
See: 
http://www.staredit.net/wiki/index.php/Scenario.chk#Trigger_Unit_Types
https://github.com/phu54321/TrigEditPlus/blob/master/Package/triggersyntax.txt

s: any number from 0 to 7, or the corresponding score name:
    0 = Total
    1 = Units
    2 = Buildings
    3 = UnitsAndBuildings
    4 = Kills
    5 = Razings
    6 = KillsAndRazings
    7 = Custom
See: 
http://www.staredit.net/wiki/index.php/Scenario.chk#Score_Types
https://github.com/phu54321/TrigEditPlus/blob/master/Package/triggersyntax.txt

r: any of 0, 1, 2, or the corresponding resource name:
    0 = Ore
    1 = Gas
    2 = OreAndGas
See: 
http://www.staredit.net/wiki/index.php/Scenario.chk#Resource_Types
https://github.com/phu54321/TrigEditPlus/blob/master/Package/triggersyntax.txt

For example:
The variable {p=P1, u="Terran Marine"} is a death count, represents P1's death count of "Terran Marine"
The variable {p=P1, s=Custom} is a score value, represents P1's Custom Score

The follow 4 are exactly the same variable:
a = {p=P1, u="Terran Marine"}
b = {p=0, u="Terran Marine"}
c = {p=P1, u=0}
d = {p=0, u=0}

Likewise, the following are the same variable:
{p=P1, s=Custom}
{p=0, s=Custom}
{p=P1, s=7}
{p=0, s=7}

Likewise, the following are the same variable:
{p=P1, r=Gas}
{p=0, r=Gas}
{p=P1, r=1}
{p=0, r=1}

Note that, the "p" key can have a value of 13 (CurrentPlayer) or 17 (AllPlayers), which has special meaning, recommended to used together with "AllPlayers",
For example:
x = {p=AllPlayers, s=Custom}
y = {p=CurrentPlayer, u=226}
]]

function SetVar(varName, modifier, value)
    if varName.u then
        return SetDeaths(varName.p, modifier, value, varName.u)
    end
    if varName.s then
        return SetScore(varName.p, modifier, value, varName.s)
    end
    if varName.r then
        return SetResources(varName.p, modifier, value, varName.r)
    end
end

function VarComp(varName, comp, value)
    if varName.u then
        return Deaths(varName.p, comp, value, varName.u)
    end
    if varName.s then
        return Score(varName.p, varName.s, comp, value)
    end
    if varName.r then
        return Accumulate(varName.p, comp, value, varName.r)
    end
end

function SetVars(varlist, modifier, valuelist)
    if #varlist ~= #valuelist then
        error(string.format("varlist and valuelist must have the same length. Got %d and %d.", #varlist, #valuelist))
    end
    local ret = {}
    for i = 1, #varlist do
        ret[i] = SetVar(varlist[i], modifier, valuelist[i])
    end
    return ret
end

function TrgVarAdd1Preserve(trgPlayer, trgCon, varName)
    local a = {}
    -- if #trgCon == 0 then
        -- a = Always();
    -- end
    Trigger {
        players = trgPlayer,
        conditions = {trgCon, a},
        actions = {
            SetVar(varName, Add, 1),
            -- PreserveTrigger()
        },
        flag = {preserved}
    }
end

function TrgVarSetTo0Preserve(trgPlayer, trgCon, varName, span)
    Trigger {
        players = trgPlayer,
        conditions = {trgCon, 
            VarComp(varName, AtLeast, span)},
        actions = {
            SetVar(varName, SetTo, 0),
            -- PreserveTrigger()
        },
        flag = {preserved}
    }
end



function CreateLoopingTimer(trgPlayer, trgCon, varName, span)
    TrgVarAdd1Preserve(trgPlayer, trgCon, varName)
    TrgVarSetTo0Preserve(trgPlayer, trgCon, varName, span)
end



--[[
Add srcvar to dstvar
note that dstvar will become dstvar+srcvar, srcvar will become 0
i.e.: dstvar += srcvar, srcvar=0

Args:
trgPlayer: Player execution
trgCon: Conditions
numBits: the size of the maximum possible value of srcvar (in bits)
(if srcvar is guaranteed to be at most 9, it needs only 4 bits, then numBits can be set to 4)
srcvar: source variable (pass by reference)
dstvar: destination variable (pass by reference)
]]
function AddValueTo(trgPlayer, trgCon, numBits, srcvar, dstvar, preserve)
    AddScaledValueTo(trgPlayer, trgCon, numBits, srcvar, dstvar, 1, 1, preserve)
end


--[[
dstvar += (numerator/denominator) * srcvar
srcvar = 0

Args:
trgPlayer: Player execution
trgCon: Conditions
numBits: the size of the maximum possible value of srcvar (in bits)
(if srcvar is guaranteed to be at most 9, it needs only 4 bits, then numBits can be set to 4)
srcvar: source variable (pass by reference)
dstvar: destination variable (pass by reference)
numerator: integer
denominator: integer
preserve: boolean. Whether or not this trigger has "preserved" flag
]]
function AddScaledValueTo(trgPlayer, trgCon, numBits, srcvar, dstvar, numerator, denominator, preserve)
    -- Error checking for denominator to avoid division by zero
    if denominator == 0 then
        error("Denominator cannot be zero.")
    end
    
    local flag = preserve and {preserved} or {}
    
    for i = numBits - 1, 0, -1 do
        local x = 1 << i
        local subtractAmount = x * denominator
        local addAmount = x * numerator
        Trigger {
            players = trgPlayer,
            conditions = {
                trgCon,
                VarComp(srcvar, AtLeast, subtractAmount)
            },
            actions = {
                SetVar(srcvar, Subtract, subtractAmount),
                SetVar(dstvar, Add, addAmount),
            },
            flag = flag
        }
    end
end

--[[
dstvar = max(dstvar - (numerator/denominator) * srcvar, 0)
srcvar = 0

Args:
trgPlayer: Player execution
trgCon: Conditions
numBits: the size of the maximum possible value of srcvar (in bits)
(if srcvar is guaranteed to be at most 9, it needs only 4 bits, then numBits can be set to 4)
srcvar: source variable (pass by reference)
dstvar: destination variable (pass by reference)
numerator: integer
denominator: integer
preserve: boolean. Whether or not this trigger has "preserved" flag

Example:
SubtractScaledValueTo(
    P1,
    {VarComp(vars_m, Exactly, 2)},
    5,  -- numBits=5, number<=31
    {p = controller_player, u = "Zerg Overlord"},
    vars_x,
    3,
    1,
    true
)
]]
function SubtractScaledValueTo(trgPlayer, trgCon, numBits, srcvar, dstvar, numerator, denominator, preserve)
    -- Error checking for denominator to avoid division by zero
    if denominator == 0 then
        error("Denominator cannot be zero.")
    end
    
    local flag = preserve and {preserved} or {}
    
    for i = numBits - 1, 0, -1 do
        local x = 1 << i
        local subtractAmount_src = x * denominator
        local subtractAmount_dst = x * numerator
        Trigger {
            players = {P1},
            conditions = {
                trgCon,
                VarComp(srcvar, AtLeast, subtractAmount_src)
            },
            actions = {
                SetVar(srcvar, Subtract, subtractAmount_src),
                SetVar(dstvar, Subtract, subtractAmount_dst),
            },
            flag = flag
        }
    end
end


--[[
swap value of var1 and var2
need an addition variable "buffer"

Args:
trgPlayer: The player execution
trgCon: Conditions
numBits: the size of the maximum value of srcvar (in bits)
(if srcvar is guaranteed to be at most 9, it needs only 4 bits, then numBits can be set to 4)
var1: the 1st variable (pass by reference)
var2: the 2nd variable (pass by reference)
buffer: the buffer variable (pass by reference)
]]
function SwapValue(trgPlayer, trgCon, numBits, var1, var2, buffer, preserve)
    flag = {}
    if preserve then
        flag = {preserved}
    end
    Trigger {
        players = trgPlayer,
        conditions = trgCon,
        actions = {
            SetVar(buffer, SetTo, 0)
        },
        flag = flag
    }
    AddValueTo(trgPlayer, trgCon, numBits, var1, buffer, preserve)
    AddValueTo(trgPlayer, trgCon, numBits, var2, var1, preserve)
    AddValueTo(trgPlayer, trgCon, numBits, buffer, var2, preserve)
end


-- Example
-- 功能：每轮扫触发都 +1 Ore，每 +3 Ore 就 +1 Gas，每 +4 Gas 就 Create 一个 Medic
--[[
x = {p = P2, u = Critters[1]}
y = {p = P3, u = Critters[2]}
CreateLoopingTimer(P8, {VarComp(x, Exactly, 0)}, y, 4)
CreateLoopingTimer(P8, {}, x, 3)

Trigger {
    players = P8,
    actions = {
        SetResources(P1, Add, 1, Ore)
    },
    flag = {preserved}
}

Trigger {
    players = P8,
    conditions = {
        VarComp(x, Exactly, 0)
    },
    actions = {
        SetResources(P1, Add, 1, Gas)
    },
    flag = {preserved}
}

Trigger {
    players = P8,
    conditions = {
        VarComp(x, Exactly, 0),
        VarComp(y, Exactly, 0)
    },
    actions = {
        CreateUnit(1, "Terran Medic", "Anywhere", P1)
    },
    flag = {preserved}
}
]]
