-- lua2 security configuration
-- Replace the example entries with the real Minecraft player names/UUIDs.
-- Keep this file on the trusted computer/server side. Do not let normal
-- players edit it.

return {
  enabled = true,
  defaultPermission = false,
  allowNameFallback = true,
  requireComputer = false,

  -- Set to true and add computer addresses to bind access to specific OC PCs.
  computers = {
    -- ["aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"] = { role = "admin" },
  },

  players = {
    -- Example:
    -- ["YourMinecraftName"] = {
    --   uuid = "00000000-0000-0000-0000-000000000000",
    --   role = "admin"
    -- },
  },

  roles = {
    admin = { all = true },
    operator = {
      reactor = true,
      ae2 = true,
      network = true,
      buldacity = true,
      status = true,
      printer = true
    },
    user = {
      status = true
    },
    guest = {}
  }
}
