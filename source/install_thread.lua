local utils = require("utils")
local https = require("https")

love["window"] = require("love.window")
love["timer"] = require("love.timer")
love["keyboard"] = require("love.keyboard")
local channel = love.thread.getChannel("installPipe")

local change_list = {}
local roll_back_changes = nil

local function send_channel_message(message_name, ...)
    channel:push({message_name, ...})
end

local function set_title_subtitle(title, subtitle)
    send_channel_message("SetTitleAndSubtitle", title, subtitle)
end

local function set_animation(animation)
    send_channel_message("SetAnimation", animation)
end

local function throw_error(call_description)
    set_animation("ERROR")
    set_title_subtitle("Installation failed", "You may now close this window.")
    love.window.showMessageBox("R1Delta Installer", call_description, "error")
    roll_back_changes(change_list)
    love.timer.sleep(3)
    os.exit()
end

local function safe_call(func, ...)
    local success_status, function_response = pcall(func, ...)
    if(success_status == false) then 
        throw_error(function_response) 
    end

    return function_response
end

local function rename_file(original_path, new_path)
    safe_call(utils.RenameFile, utils, original_path, new_path)
    table.insert(change_list, {"RenameFile", original_path, new_path})
end

local function create_directory(path)
    local CreateDirectoryReturn = safe_call(utils.CreateDirectory, utils, path)
    if(CreateDirectoryReturn ~= ERROR_ALREADY_EXISTS) then
        table.insert(change_list, {"CreateDirectory", path})
    end
end

local function create_file(path)
    table.insert(change_list, {"CreateFile", path})
end

local function split_comma(line)
    local fields = {}
    for field in line:gmatch('([^,]+)') do
        table.insert(fields, field)
    end

    return fields
end

--
--  Roll back R1Delta changes
--
local roll_back_actions = {
    ["RenameFile"] = function(original_path, new_path)
        rename_file(new_path, original_path)
    end,

    ["CreateDirectory"] = function(path)
        utils:RemoveDirectory(path)
    end,

    ["CreateFile"] = function(path)
        utils:DeleteFile(path)
    end
}
roll_back_changes = function(changes)
    for _, i in pairs(changes) do
        roll_back_actions[i[1]](i[2], i[3])
    end
end









--
--  See if Titanfall is open and stop installation early.
--
local function check_titanfall_open()
    local found_titanfall_process = safe_call(utils.FindProcessByName, utils, "Titanfall.exe")
    if(found_titanfall_process) then
        set_animation("ERROR")
        set_title_subtitle("Installation failed", "Please close Titanfall and try again.")
        love.window.showMessageBox("R1Delta Installer", "Please close Titanfall and try again.", "error")
        love.timer.sleep(3)
        os.exit()
    end
end

--
--  Get Titanfall install directory(from Steam uninstall, or Respawn registry keys)
--
local function get_titanfall_dir()
    -- TODO: Custom folder selection
    local install_dir = nil

    install_dir = utils:RegistryGetString(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 1454890", "InstallLocation")
    if(install_dir) then 
        install_dir = install_dir .. "\\" 
        return install_dir
    end

    install_dir = utils:RegistryGetString(HKEY_LOCAL_MACHINE, "SOFTWARE\\Respawn\\Titanfall", "Install Dir")
    if(install_dir) then 
        return install_dir
    end

    local self_select_dir = love.window.showMessageBox("R1Delta Installer", "Unable to find your Titanfall directory. Would you like to proceed by manually selecting Titanfall.exe?", {"No", "Yes"}, "info")
    if(self_select_dir == 2) then
        install_dir, _ = utils:GetOpenFile({"Titanfall.exe", "Titanfall.exe"}, "Open Titanfall.exe")
        if(install_dir) then return install_dir:sub(1, -14) end
    end

    throw_error("Failed to find Titanfall install directory.")
end

--
--  Check for Titanfall.exe and Titanfall BME
--
local function check_for_modded_install()
    local titanfall_exe_path = string.format("%sTitanfall.exe", install_dir)
    local titanfall_exe_checksum_vanilla = "6193c3ee12b662d182aaec31c8aef917186191d326f35b120c259ba296f4cc48"
    if(not utils:DoesFileExist(titanfall_exe_path) or utils:ChecksumSHA256(titanfall_exe_path) ~= titanfall_exe_checksum_vanilla) then
        throw_error("Failed to find Titanfall installation folder. Your installation is heavily modded or corrupt.")
    end

    local launcher_dll_path = string.format("%sbin\\x64_retail\\launcher.dll", install_dir)
    local launcher_dll_checksum_vanilla = "c0320bbe75b59ce221e3fb1dbdcdf8857e9305845ff9b0f3f3bfb4897d4b7a38"
    if(utils:DoesFileExist(launcher_dll_path) and utils:ChecksumSHA256(launcher_dll_path) ~= launcher_dll_checksum_vanilla) then
        local disable_bme_choice = love.window.showMessageBox("R1Delta Installer", "Titanfall Black Market Edition is not compatible with R1Delta. Would you like to disable Titanfall Black Market Edition?", {"No", "Yes"}, "warning")
        if(disable_bme_choice == 1) then
            throw_error("The user has cancelled the installation. Please uninstall Titanfall Black Market Edition and try again.")
        else
            rename_file(launcher_dll_path, launcher_dll_path .. ".r1delta")
        end
    end
end

--
--  Check for an already-existing R1Delta installation to remove.
--
local function check_for_former_r1delta_install()
    local log_File_path = string.format("%sr1delta.log", install_dir)
    if(utils:DoesFileExist(log_File_path)) then
        local file = io.open(string.format("%sr1delta.log", install_dir), "r")

        local changes = {}
        for line in file:lines() do
            table.insert(changes, split_comma(line))
        end
        
        roll_back_changes(changes)
        file:close()

        utils:DeleteFile(log_File_path)
    end
end

--
--  Check for Advanced Settings
--
local function check_advanced_settings() 
    -- Right now, only used for uninstalling.

    if(not utils:DoesFileExist(string.format("%sr1delta.log", install_dir))) then return end

    local start_time = love.timer.getTime()
    local do_uninstall = false
    local i = 0
    while((love.timer.getTime() - start_time) < 3 and do_uninstall == false) do

        -- Press SHIFT to uninstall - 3.0s
        if(math.floor((love.timer.getTime() - start_time) * 10) % 10 ~= i) then
            i = math.floor((love.timer.getTime() - start_time) * 10) % 10
            set_title_subtitle("R1Delta installer", string.format("Press SHIFT to uninstall - %.1f", 3 - (love.timer.getTime() - start_time)))
        end

        if(love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")) then
            do_uninstall = true
        end
    end

    if(do_uninstall) then
        check_for_former_r1delta_install()
        set_animation("ERROR")
        set_title_subtitle("Uninstallation complete", "You may now close this window.")
        love.timer.sleep(3)
        os.exit()
    end
end

--
--  Download R1Delta resources
--
local function donwload_resources()
    local code, body = https.request("https://github.com/r1delta/r1delta/releases/latest/download/r1delta.zip")
    if(code ~= 200) then throw_error(string.format("Failed to download R1Delta resources. %s", code)) end
    return body
end

--
--  Extract R1Delta resources into Titanfall directory
--
local function extract_files()
    local fs_mount_status = love.filesystem.mount(r1delta_zip, "r1delta", "r1delta")
    if(not fs_mount_status) then
        throw_error("Failed to mount R1Delta resources.")
    end

    local run_file_logic = nil
    run_file_logic = function(current_path)
        local mounted_path = string.format("r1delta/%s", table.concat(current_path, "/"))
        local system_path = string.format("%s%s", install_dir, table.concat(current_path, "\\"))

        local mounted_file_info = love.filesystem.getInfo(mounted_path)
        if(not mounted_file_info) then return end

        if(mounted_file_info.type == "directory") then
            create_directory(system_path)

            for _, file in pairs(love.filesystem.getDirectoryItems(mounted_path)) do
                local new_path = {unpack(current_path)}
                table.insert(new_path, file)
                run_file_logic(new_path)
            end
        elseif(mounted_file_info.type == "file") then
            if(utils:DoesFileExist(system_path)) then
                rename_file(system_path, system_path .. ".r1delta")
            end

            local file = io.open(system_path, "wb")
            local mounted_file, _ = love.filesystem.read(mounted_path)
            file:write(mounted_file)
            file:close()
            create_file(system_path)
        end
    end

    local mounted_fs_root = love.filesystem.getDirectoryItems("r1delta")
    for _, i in pairs(mounted_fs_root) do
        run_file_logic({i})
    end
end

--
--  Saves the changes list to disk.
--
local function save_change_list()
    local file = io.open(string.format("%sr1delta.log", install_dir), "w")

    -- Save them in reverse order to make it easier when loading.
    for i=#change_list,1,-1 do
        file:write(table.concat(change_list[i], ",") .. "\n")
    end
end

-- 
-- Check for replacement, and show deprecation messages.
-- 
local function deprecation_message()
    local deprecated_message = "The R1Delta installer has been deprecated and will soon be discontinued. \
While you can continue using this version for now, please note that support will no longer be available. \
We're excited to announce that an upgraded installer, packed with new features will be available soon!"

    local replaced_message = "The R1Delta installer has been discontinued and superseded by an updated version. \
Please download the latest version from "

    local replaced = false 
    local new_link = ""

    local code, body = https.request("https://gist.githubusercontent.com/quad-damage/caf4dbbf4e048419a522c97f84c9031f/raw/r1delta_installer.ini")
    if(code ~= 200) then
        replaced, new_link = false, ""
    else
        _replaced, new_link = body:match("replaced=(%a+)%s+new_link=(.+)")
        replaced = _replaced == "true" and true or false

    end
    
    replaced_message = replaced_message .. new_link

    love.window.showMessageBox("R1Delta Installer", replaced and replaced_message or deprecated_message, replaced and "error" or "warning")
    return replaced
end


local function main()
    if(not deprecation_message()) then
        check_titanfall_open()

        set_title_subtitle("R1Delta installer", "Finding Titanfall installation folder...")
        install_dir = get_titanfall_dir()

        check_advanced_settings()

        set_title_subtitle("R1Delta installer", "Checking for older R1Dleta installations")
        check_for_former_r1delta_install()

        -- set_title_subtitle("R1Delta installer", "Checking for modded Titanfall installation...")
        check_for_modded_install()

        set_title_subtitle("R1Delta installer", "Downloading R1Delta resources...")
        r1delta_zip_content = donwload_resources()
        r1delta_zip = love.data.newByteData(r1delta_zip_content, 0, #r1delta_zip_content)

        set_title_subtitle("R1Delta installer", "Extracting R1Delta resources...")
        extract_files()

        set_animation("IDLE")
        set_title_subtitle("Installation complete", "You may now close this window.")
        save_change_list()
    else
        set_animation("IDLE")
        set_title_subtitle("R1Delta installer", "Please download the new version.")
    end
end

main()