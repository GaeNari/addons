--[[ code to work around getting mounts ]]--

local AddonName, Addon = ...

local SUMMON_RANDOM_MOUNT_ID = 268435455
local SUMMON_RANDOM_MOUNT_INDEX = 0

local PickupMount = _G.C_MountJournal.Pickup
local GetNumMounts = _G.C_MountJournal.GetNumMounts
local GetCursorInfo = _G.GetCursorInfo
local ClearCursor = _G.ClearCursor

local mountCache = nil

local function makeMountCache()
	local mountCache = {[SUMMON_RANDOM_MOUNT_ID] = SUMMON_RANDOM_MOUNT_INDEX}
	local numMounts = GetNumMounts()

	for mountIndex = 1, numMounts do
		PickupMount(mountIndex)

		local type, mountId = GetCursorInfo()
		if mountId then
			mountCache[mountId] = mountIndex
		end

		ClearCursor()
	end

	return mountCache
end

local function getMountIndex(mountId)
	if not mountCache then
		mountCache = makeMountCache()
	end

	return mountCache[mountId]
end

Addon.PickupMount = function(mountId)
	local index = getMountIndex(mountId)

	if index then
		PickupMount(index)
		return true
	end
end

Addon.ClearMountCache = function()
	mountCache = nil
end
