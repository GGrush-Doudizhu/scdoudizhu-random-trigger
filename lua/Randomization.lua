--The following code must be compiled by TriggerEditPlus with version >= 0.086

--[[
ActionRandSwitches(1, 6) will be compiled to:
    SetSwitch("Switch 2", Random);
    SetSwitch("Switch 3", Random);
    SetSwitch("Switch 4", Random);
    SetSwitch("Switch 5", Random);
    SetSwitch("Switch 6", Random);
    SetSwitch("Switch 7", Random);

Args:
startSwitch: the 1st switch
n: should be a number less than or equal to 32
]]
function ActionRandSwitches(startSwitch, n) 
    local act = {}
    for i = 1, n do
        if i < 33 then
            act[i] = SetSwitch(EncodeSwitchName(startSwitch) + i - 1, Random)
        end
    end
    return act
end


--[[
Generates a random variable taking value from [lowerBound, lowerBound + 2^n - 1]

Example:
TrgRandNumNbit(P8, {}, 1, 20, 8, {p=P1, u=0}, false)
Use "Switch 21" - "Switch 28" to randomly draw a number from [1, 256] and assign it to the variable {p=P1, u=0} (P1's "Terran Marine" death count)

TrgRandNumNbit(P1, {}, 100, 0, 10, {p=P1, u=0}, false)
Use "Switch 1" - "Switch 10" to randomly draw a number from [100, 1123] and assign it to the variable {p=P1, u=0} (P1's "Terran Marine" death count)

Args:
lowerBound: The lower bound of the interval
startSwitch: the 1st switch
numSwitch: n. should be a number less than 32, and lowerBound + 2^numSwitch - 1 < 2^32
resultVar: The variable
preserve: Boolean. true or false
]]
function TrgRandNumNbit(trgPlayer, trgCon, lowerBound, startSwitch, numSwitch, resultVar, preserve)
    if numSwitch > 32 then
        error("numSwitch must not exceed 32")
    end
    if lowerBound > (2^32) - 1 - (2^numSwitch) then
        error("lowerBound + 2^numSwitch (" .. lowerBound + 1 + 2^numSwitch.. ") must be less than 2^32 (" .. (2^32) .. ").")
    end

    flag = {}
    if preserve then
        flag = {preserved}
    end

    int_sw = EncodeSwitchName(startSwitch)

    Trigger {
        players = trgPlayer,
        conditions = trgCon,
        actions = {
            ActionRandSwitches(int_sw, numSwitch)
        },
        flag = flag
    }
            
    Trigger {
        players = trgPlayer,
        conditions = trgCon,
        actions = {
            SetVar(resultVar, SetTo, lowerBound)
        },
        flag = flag
    }

    power = numSwitch
    if numSwitch > 31 then  -- TEP bug: cannot calculate 2^31
        power = 31
    end

    for i = 1, power do
        Trigger {
            players = trgPlayer,
            conditions = {
                trgCon,
                Switch(int_sw + i - 1, Set)
            },
            actions = {
                SetVar(resultVar, Add, 1 << (i - 1))
            },
            flag = flag
        }
    end

    if numSwitch > 31 then
        Trigger {
            players = trgPlayer,
            conditions = {
                trgCon,
                Switch(int_sw + 31, Set)
            },
            actions = {
                SetVar(resultVar, Add, 2147483648)
            },
            flag = flag
        }
    end
end



--[[
Evenly partition "{0,1,2,...,number-1}" into "p" parts, return the delimiters (0 <= x <= d1 - 1, d1 <= x <= d2 - 1, ..., x >= d2)
NumberPartition(24, 6) should return {0, 4, 8, 12, 16, 20}
NumberPartition(24, 7) should return {0, 4, 8, 12, 15, 18, 21}

Args:
number: [0, number)
p: number of partitions
]]
function NumberPartition(number, p)
    if p > number then
        return NumberPartition(number, number)
    end
    if p == 0 then
        return
    end
    local quo = number // p
    local rem = number % p
    local r = {0}
    for i = 1, p-1 do
        if i <= rem then
            r[i + 1] = r[i] + quo + 1
        else
            r[i + 1] = r[i] + quo
        end
    end
    return r
end


--[[
Example:
TrgRandGen(P2, {}, 7, "Switch 1", 3, {p=P1, u="Terran Ghost"}, true) will result in:
P2's death of "Terran Ghost" becomes 1, or 2, or 3, ..., or 7, with probability {1/4, 1/8, 1/8, 1/8, 1/8, 1/8, 1/8}

TrgRandGen(P2, {}, 7, "Switch 1", 4, {p=P1, u="Terran Ghost"}, true) will result in:
P2's death of "Terran Ghost" becomes 1, or 2, or 3, ..., or 7, with probability {3/16, 3/16, 1/8, 1/8, 1/8, 1/8, 1/8}

TrgRandGen(P2, {}, 7, "Switch 1", 10, {p=P1, u="Terran Ghost"}, true) will result in:
P2's death of "Terran Ghost" becomes 1, or 2, or 3, ..., or 7, with nearly same probability, nearly 1/7 for each number

TrgRandGen(P2, {}, 8, "Switch 1", 10, {p=P1, u="Terran Ghost"}, true) will result in:
P2's death of "Terran Ghost" becomes 1, or 2, or 3, ..., or 8, with exactly 1/8 probality each. Only "Switch 1", "Switch 2", "Switch 3" are used

Args:
trgPlayer: list of trigger owners
trgCon: list of trigger conditions. Can be empty {}
x: the resultVar would be one of {1, 2, 3, ..., x}, with (nearly) same probability. When x is a power of 2, the result will be perfectly same probability.
startSwitch: the index of the first switch used for generating random number. Can be switch name (string) or switchID (int)
numSwitch: number of switches. If 0, then use default. Larger value will result in more even probabilities
(Caution: it is recommended that n is not greater than 20. There may be bug if the number is large)
resultVar: the result variable (pass by reference)
"preserve": Boolean. true or false. Whether to add "preserve" flag

]]
function TrgRandGen(trgPlayer, trgCon, x, startSwitch, numSwitch, resultVar, preserve)
    -- Use default
    if numSwitch == 0 then
        numSwitch = 15
    end
    if (1 << numSwitch) < x then
        error(string.format("TrgRandGen: 2^numSwitch must be greater than or equal to x \nfunction call: x=%d, numSwitch=%d", x, numSwitch))
        return
    end

    local pre = {}
    if preserve then
        pre = PreserveTrigger()
    end
    local trg = {}
    
    flag = {}
    if preserve then
        flag = {preserved}
    end

    int_sw = EncodeSwitchName(startSwitch)

    -- If x is a power of 2 (maximum 2^12), optimize.
    for power = 1, 12 do
        if x == (1 << power) then
            TrgRandNumNbit(trgPlayer, trgCon, 1, startSwitch, power, resultVar, preserve)
            return
        end
    end
    
    initialValue = x+1

    TrgRandNumNbit(trgPlayer, trgCon, initialValue, startSwitch, numSwitch, resultVar, preserve)

    
    local delim = NumberPartition(1 << numSwitch, x)
    for i = 1, x - 1 do
        local low = initialValue + delim[i]
        local high =  initialValue + delim[i+1]-1
        local cmp = {} 
        if low == high then
            cmp = VarComp(resultVar, Exactly, low)
        else
            cmp = {VarComp(resultVar, AtLeast, low),
                    VarComp(resultVar, AtMost, high)}
        end
        Trigger {
            players = trgPlayer,
            conditions = {
                trgCon,
                cmp
            },
            actions = {
                SetVar(resultVar, SetTo, i)
            },
            flag = flag
        }
    end
    
    Trigger {
        players = trgPlayer,
        conditions = {
            trgCon,
            VarComp(resultVar, AtLeast, initialValue + delim[x])
        },
        actions = {
            SetVar(resultVar, SetTo, x)
        },
        flag = flag
    }
end

-- TrgRandGen(P2, {}, 7, 10, 3, {p=P1, u="Bengalaas (Jungle)"}, true)