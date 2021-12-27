local M = {}

M.note_picker_list_api_selection = { "title", "absPath" }

function M.show_note_picker(notes, options, action)
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
    if action == "edit" then
      vim.cmd("e " .. item.absPath)
    else
      if options.multi_select then
        action({ item })
      else
        action(item)
      end
    end
  end)
end

function M.show_tag_picker(tags, options, action)
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
      action({ item })
    else
      action(item)
    end
  end)
end

return M
