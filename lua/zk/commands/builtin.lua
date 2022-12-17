local zk = require("zk")
local util = require("zk.util")
local commands = require("zk.commands")

commands.add("ZkIndex", zk.index)

commands.add("ZkNew", function(options)
  options = options or {}

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = util.get_lsp_location_from_caret()
  end

  zk.new(options)
end)

commands.add("ZkNewFromTitleSelection", function(options)
  local location = util.get_lsp_location_from_selection()
  local selected_text = util.get_text_in_range(location.range)
  assert(selected_text ~= nil, "No selected text")

  options = options or {}
  options.title = selected_text

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  zk.new(options)
end, { needs_selection = true })

commands.add("ZkNewFromContentSelection", function(options)
  local location = util.get_lsp_location_from_selection()
  local selected_text = util.get_text_in_range(location.range)
  assert(selected_text ~= nil, "No selected text")

  options = options or {}
  options.content = selected_text

  if options.inline == true then
    options.inline = nil
    options.dryRun = true
    options.insertContentAtLocation = location
  else
    options.insertLinkAtLocation = location
  end

  zk.new(options)
end, { needs_selection = true })

commands.add("ZkCd", zk.cd)

commands.add("ZkNotes", function(options)
  zk.edit(options, { title = "Zk Notes" })
end)

commands.add("ZkBacklinks", function(options)
  options = vim.tbl_extend("force", { linkTo = { vim.api.nvim_buf_get_name(0) } }, options or {})
  zk.edit(options, { title = "Zk Backlinks" })
end)

commands.add("ZkLinks", function(options)
  options = vim.tbl_extend("force", { linkedBy = { vim.api.nvim_buf_get_name(0) } }, options or {})
  zk.edit(options, { title = "Zk Links" })
end)

commands.add("ZkMatch", function(options)
  local selected_text = util.get_text_in_range(util.get_selected_range())
  assert(selected_text ~= nil, "No selected text")
  options = vim.tbl_extend("force", { match = { selected_text } }, options or {})
  zk.edit(options, { title = "Zk Notes matching " .. vim.inspect(selected_text) })
end, { needs_selection = true })

commands.add("ZkTags", function(options)
  zk.pick_tags(options, { title = "Zk Tags" }, function(tags)
    tags = vim.tbl_map(function(v)
      return v.name
    end, tags)
    zk.edit({ tags = tags }, { title = "Zk Notes for tag(s) " .. vim.inspect(tags) })
  end)
end)
