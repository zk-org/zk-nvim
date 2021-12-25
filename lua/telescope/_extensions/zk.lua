local api = require("zk.api")
local telescope_pickers = require("zk.pickers.telescope")

---@param opts? table additional options for zk, path for zk, telescope options, all optional and in one table
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
local function show_notes(opts)
  api.list(opts.path, vim.tbl_extend("force", telescope_pickers.note_picker_api_options, opts), function(notes)
    telescope_pickers.show_note_picker(notes, opts)
  end)
end

---@param opts? table additional options for zk, path for zk, telescope options, all optional and in one table
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
local function show_tags(opts)
  api.tag.list(opts.path, vim.tbl_extend("force", telescope_pickers.tag_picker_api_options, opts), function(tags)
    telescope_pickers.show_tag_picker(tags, opts, function(selected_tags)
      api.list(
        opts.path,
        vim.tbl_extend("force", telescope_pickers.note_picker_api_options, { tags = selected_tags }),
        function(notes)
          opts.prompt_title = "Zk Notes for tag(s) " .. vim.inspect(selected_tags)
          telescope_pickers.show_note_picker(opts, notes)
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
