local api = require("zk.api")
local util = require("telescope.zk.util")

---@param opts? table additional options for zk, path for zk, telescope options, all optional and in one table
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_notes(opts)
  api.list(opts.path, vim.tbl_extend("force", util.note_picker_api_options, opts), function(notes)
    util.show_note_picker(notes, opts)
  end)
end

---@param opts? table additional options for zk, path for zk, telescope options, all optional and in one table
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
local function show_tags(opts)
  api.tag.list(opts.path, vim.tbl_extend("force", util.tag_picker_api_options, opts), function(tags)
    util.show_tag_picker(tags, opts, function(selected_tags)
      api.list(
        opts.path,
        vim.tbl_extend("force", util.note_picker_api_options, { tags = selected_tags }),
        function(notes)
          opts.prompt_title = "Zk Notes for tag(s) " .. vim.inspect(selected_tags)
          util.show_note_picker(opts, notes)
        end
      )
    end)
  end)
end

return require("telescope").register_extension({
  exports = {
    notes = show_notes,
    tags = show_tags,
  },
})
