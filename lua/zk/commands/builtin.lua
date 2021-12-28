local zk = require("zk")
local util = require("zk.util")

return {
  index = {
    command = "ZkIndex",
    fn = zk.index,
  },

  new = {
    command = "ZkNew",
    fn = zk.new,
  },

  new_from_title_selection = {
    command = { name = "ZkNewFromTitleSelection", range_only = true },
    fn = function(options)
      local location = util.get_lsp_location_from_selection()
      local selected_text = util.get_text_in_range(location.range)
      assert(selected_text ~= nil, "No selected text")
      zk.new(vim.tbl_extend("keep", options or {}, { insertLinkAtLocation = location, title = selected_text }))
    end,
  },

  new_from_content_selection = {
    command = { name = "ZkNewFromContentSelection", range_only = true },
    fn = function(options)
      local location = util.get_lsp_location_from_selection()
      local selected_text = util.get_text_in_range(location.range)
      assert(selected_text ~= nil, "No selected text")
      zk.new(vim.tbl_extend("keep", options or {}, { insertLinkAtLocation = location, content = selected_text }))
    end,
  },

  cd = {
    command = "ZkCd",
    fn = zk.cd,
  },

  notes = {
    command = "ZkNotes",
    fn = function(options)
      zk.edit(options, { title = "Zk Notes" })
    end,
  },

  backlinks = {
    command = "ZkBacklinks",
    fn = function(options)
      options = vim.tbl_deep_extend("force", { linkTo = { vim.api.nvim_buf_get_name(0) } }, options or {})
      zk.edit(options, { title = "Zk Backlinks" })
    end,
  },

  links = {
    command = "ZkLinks",
    fn = function(options)
      options = vim.tbl_deep_extend("force", { linkedBy = { vim.api.nvim_buf_get_name(0) } }, options or {})
      zk.edit(options, { title = "Zk Links" })
    end,
  },

  match = {
    command = { name = "ZkMatch", range_only = true },
    fn = function(options)
      local selected_text = util.get_selected_text()
      assert(selected_text ~= nil, "No selected text")
      options = vim.tbl_deep_extend("force", { match = selected_text }, options or {})
      zk.edit(options, { title = "Zk Notes matching" .. selected_text })
    end,
  },

  tags = {
    command = "ZkTags",
    fn = function(options)
      zk.edit_from_tags(options, { title = "Zk Tags" })
    end,
  },
}
