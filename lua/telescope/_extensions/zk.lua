local util = require("telescope.zk.util")
local zk = require("zk")

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_notes(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Notes" })
  zk.api.list(opts.path, util.wrap_note_options(opts), function(notes)
    util.show_note_picker(opts, notes)
  end)
end

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_orphans(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Orphans" })
  opts = vim.tbl_deep_extend("force", opts, { orphan = true })
  show_notes(opts)
end

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_backlinks(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Backlinks" })
  opts = vim.tbl_deep_extend("force", opts, { linkTo = { vim.api.nvim_buf_get_name(0) } })
  show_notes(opts)
end

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_links(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Links" })
  opts = vim.tbl_deep_extend("force", opts, { linkedBy = { vim.api.nvim_buf_get_name(0) } })
  show_notes(opts)
end

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_related(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Related" })
  opts = vim.tbl_deep_extend("force", opts, { related = { vim.api.nvim_buf_get_name(0) } })
  show_notes(opts)
end

---@param opts table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
local function show_tags(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Tags" })
  zk.api.tag.list(opts.path, util.wrap_tag_options({}), function(tags)
    util.show_tag_picker(opts, tags, function(selected_tags)
      zk.api.list(opts.path, util.wrap_note_options({ tags = selected_tags }), function(notes)
        opts.prompt_title = "Zk Notes for tag(s) " .. vim.inspect(selected_tags)
        util.show_note_picker(opts, notes)
      end)
    end)
  end)
end

return require("telescope").register_extension({
  exports = {
    notes = show_notes,
    orphans = show_orphans,
    backlinks = show_backlinks,
    links = show_links,
    related = show_related,
    tags = show_tags,
  },
})
