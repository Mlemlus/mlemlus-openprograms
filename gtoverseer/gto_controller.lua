-- GTOverseer controller
local internet = require("internet")
local server = "http://10.21.31.5:40649/data"
local session_id = ""

function toJSON(tbl)
    local result = '{'
    for k, v in pairs(tbl) do
        -- Add key
        result = result .. '"' .. tostring(k) .. '":'

        -- check if table to recursively call toJSON 
        if type(v) == "table" then
            result = result .. toJSON(v)
        -- check if string (value)
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        -- if anything else (int/boolean) convert to string
        else
            result = result .. tostring(v)
        end

        result = result .. ','  -- add the , after value
    end
    if result:sub(-1) == ',' then
        result = result:sub(1, -2)-- remove the last , 
    end
    result = result .. '}'
    return result -- pray it works
end

function postData(tbl)
    local body = toJSON(tbl)
    local response, status = internet.request(server, body, { ["Content-Type"] = "application/json" })

    if response then 
        local response_body = ""
        for chunk in response do -- build the response from chunks
            response_body = response_body .. chunk
        end
        return response_body, status
    else
        return status
    end
end

function reset()
    local oc_data = {}
    -- OC controller machine
    for address in component.list("computer") do
        oc_data[1] = {
            name = "computer",
            oc_address = address
        }
    end

    -- Iteration over GT machines
    for address in component.list("gt_machine") do
        local adapter = component.proxy(address) -- proxy address for interaction
        local machine_name = adapter.getName()
        if machine_name:sub(1,5) == "cable" or machine_name:sub(1,7) == "gt_pipe" then
            goto continue -- skip gt_machines that are not machines
        end
        local component_data = {}
        local sensor_info = (adapter.getSensorInformation and adapter.getSensorInformation()) or ""

        component_data["machine"] = {
            oc_address = address,
            name = adapter.getName(),
            owner_name = adapter.getOwnerName(),
            coords = {adapter.getCoordinates()},
            sensor_info = sensor_info,
            input_eu = adapter.getInputVoltage(),
            allowed_work = adapter.isWorkAllowed()
        }

        -- the lapron cap, basic singleblock generators"
        if adapter.getName() == "multimachine.supercapacitor" or adapter.getName():sub(1,14) == "basicgenerator" then
            component_data["power_source"] = {
            output_voltage = adapter.getOutputVoltage(),
            output_voltage_avg = adapter.getAverageElectricOutput(),
            input_voltage = adapter.getInputVoltage(),
            input_voltage_avg = adapter.getAverageElectricInput(),
            eu_capacity = adapter.getStoredEUString(),
            eu_capacity_current = adapter.getEUCapacityString(),
            output_amp = adapter.getOutputAmperage()
            }
        end

        oc_data[#oc_data+1] = component_data
        ::continue::
    end

    -- Battery buffer
    for address in component.list("gt_batterybuffer") do
        local component_data = {}
        local adapter = component.proxy(address) -- proxy address for interaction
        local sensorInfo = (adapter.getSensorInformation and adapter.getSensorInformation()) or ""


        component_data["machine"] = {
            oc_address = address,
            name = adapter.getName(),
            owner_name = adapter.getOwnerName(),
            coords = adapter.getCoordinates(),
            sensor_info = sensorInfo,
            input_eu = adapter.getInputVoltage(),
            allowed_work = adapter.isWorkAllowed()
        }

        component_data["power_source"] = {
            output_amp = adapter.getOutputAmperage(),
            output_voltage = adapter.getOutputVoltage(),
            output_voltage_avg = adapter.getAverageElectricOutput(),
            input_voltage_avg = adapter.getAverageElectricInput()
        }

        oc_data[#oc_data+1] = component_data
    end
    local data={}
    data["data"] = oc_data
    data["status"] = "205" -- 205 HTTP code to reset content 
    return data
end

-- function update()
    -- check if machine has new problems
    -- if yes add to address to data
    -- send work progress data if machine working

local response = postData(reset())
session_id = response:sub(4,-1) -- initial data reset and get session_id 
print(session_id) --debug

