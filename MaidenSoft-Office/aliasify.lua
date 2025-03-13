
local programDirectory = fs.getDir(shell.getRunningProgram())

local programs = {
    "Word"
}

for _, program in ipairs(programs) do
    local programPath = fs.combine(programDirectory, program..".lua")
    if (string.sub(programPath, 1, 1) ~= "/") then
        programPath = "/"..programPath
    end

    shell.setAlias(program, programPath)
end
