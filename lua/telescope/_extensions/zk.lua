local zk = require("zk")

---@param opts? table additional options for zk, telescope options, all optional and in one table
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zklist
local function show_notes(opts)
  zk.edit(opts, { picker = "telescope", telescope = opts })
end

---@param opts? table additional options for zk, telescope options, all optional and in one table
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zktaglist
local function show_tags(opts)
  zk.pick_tags(opts, { picker = "telescope", telescope = opts }, function(tags)
    tags = vim.tbl_map(function(v)
      return v.name
    end, tags)
    opts = vim.tbl_extend("force", { tags = tags }, opts or {})
    zk.edit(opts, { picker = "telescope", telescope = opts })
  end)
end

return require("telescope").register_extension({
  exports = {
    notes = show_notes,
    tags = show_tags,
  },
})
