--requires Fingercomp's charts (they are on oppm)
local component = require("component")
local charts = require("charts")
local term = require("term")
local event = require("event")

local cOne = charts.Container {
    x = 1,
    y = 2,
    width = 70,
    height = 2,
    payload = charts.ProgressBar {
        direction = charts.sides.RIGHT,
        value = 0,
        colorFunc = function(_, perc)
            if perc >= .9 then
              return 0x20afff
            elseif perc >= .75 then
              return 0x20ff20
            elseif perc >= .5 then
              return 0xafff20
            elseif perc >= .25 then
              return 0xffff20
            elseif perc >= .1 then
              return 0xffaf20
            else
              return 0xff2020
            end
        end
    }
}

local cTwo = charts.Container {
    x = 1,
    y = 5,
    width = 70,
    height = 2,
    payload = charts.ProgressBar {
        direction = charts.sides.RIGHT,
        value = 0,
        colorFunc = cOne.payload.colorFunc
    }
}

function NormProgress(min, max, current) -- returns progress value between 0 and 1
    local curStep = (current - min) / (max - min)
end

while true do -- main loop
    --EBF 1
    local machine = component.proxy("1af3cf80-fcc1-4d4e-bcad-c25824981863") -- manual address, add dynamic selection
    cOne.gpu.set(1,1,"EBF 1")
    if machine.getWorkMaxProgress() ~= 0 then -- checks if machine is working
        local maxProgress = machine.getWorkMaxProgress()
        local progress = machine.getWOrkProgress()
        local percProgress = NormProgress(0, maxProgress, progress)
        cOne.gpu.set(7,1, "Value: " .. ("%d"):format(progress) .. " [" .. ("%3d"):format(math.floor(percProgress * 100)) .. "%]")

        cOne.payload.value = percProgress
        cOne:draw()
    else
        cOne.gpu.set(1,2,"Stopped")
    end

    --EBF 2
    machine = component.proxy("b2295932-1f50-4e4d-bab9-b93f78be5f7d") -- manual address, add dynamic selection (add to table?)
    cTwo.gpu.set(1,4,"EBF 2")
    if machine.getWorkMaxProgress() ~= 0 then -- checks if machine is working
        local maxProgress = machine.getWorkMaxProgress()
        local progress = machine.getWOrkProgress()
        local percProgress = NormProgress(0, maxProgress, progress)
        cTwo.gpu.set(7,4, "Value: " .. ("%d"):format(progress) .. " [" .. ("%3d"):format(math.floor(percProgress * 100)) .. "%]")

        cTwo.payload.value = percProgress
        cTwo:draw()
    else
        cTwo.gpu.set(1,5,"Stopped")
    end

    if event.pull(0.05, "interrupted") then
        term.clear()
        os.exit()
    end
end