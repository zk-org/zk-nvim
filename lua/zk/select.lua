local M = {}

M.note_picker_api_options = { select = { "title", "absPath" }, sort = { "created" } }

M.tag_picker_api_options = {
  sort = { "note-count" },
}

function M.show_note_picker(notes, options)
  options = vim.tbl_extend("force", {
    prompt = "Zk Notes",
    format_item = function(item)
      return item.title
    end,
  }, options or {})
  vim.ui.select(notes, options, function(item)
    if not item then
      -- user aborted
      return
    end
    vim.cmd("e " .. item.absPath)
  end)
end

function M.show_tag_picker(tags, options, cb)
  options = vim.tbl_extend("force", {
    prompt = "Zk Tags",
    format_item = function(item)
      return item.name
    end,
  }, options or {})
  vim.ui.select(tags, options, function(item)
    if not item then
      -- user aborted
      return
    end
    cb({ item.name })
  end)
end

return M
