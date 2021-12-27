local M = {}

M.note_picker_list_api_selection = { "title", "absPath" }

function M.show_note_picker(notes, options, cb)
  options = options or {}
  local select_options = vim.tbl_extend("force", {
    prompt = options.title,
    format_item = function(item)
      return item.title
    end,
  }, options.select or {})
  vim.ui.select(notes, select_options, function(item)
    if not item then
      -- user aborted
      return
    end
    if options.multi_select then
      cb({ item })
    else
      cb(item)
    end
  end)
end

function M.show_tag_picker(tags, options, cb)
  options = options or {}
  local select_options = vim.tbl_extend("force", {
    prompt = "Zk Tags",
    format_item = function(item)
      return item.name
    end,
  }, options.select or {})
  vim.ui.select(tags, select_options, function(item)
    if not item then
      -- user aborted
      return
    end
    if options.multi_select then
      cb({ item })
    else
      cb(item)
    end
  end)
end

return M
