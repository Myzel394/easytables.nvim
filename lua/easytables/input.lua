local string = require("string")

---Extracts the column info from the input
---@param raw_input string
---@return table
local function extract_column_info(raw_input)
    local _, _, cols, create_singular, rows = string.find(raw_input, "(%d+)(x?)(%d*)")

    if rows == "" then
        if create_singular == "x" then
            rows = "1"
        else
            rows = cols
        end
    end

    local m = {}
    m[1] = tonumber(cols)
    m[2] = tonumber(rows)

    return m
end

return {
    extract_column_info = extract_column_info,
}
