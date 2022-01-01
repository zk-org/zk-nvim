local zk = require("zk")

---@param opts? table additional options for zk, telescope options, all optional and in one table
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_notes(opts)
  zk.edit(opts, { picker = "telescope", telescope = opts })
end

return require("telescope").register_extension({
  exports = {
    notes = show_notes,
  },
})
