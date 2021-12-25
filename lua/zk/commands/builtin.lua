local api = require("zk.api")
local pickers = require("zk.pickers")
local util = require("zk.util")

return {
  index = {
    command = "ZkIndex",
    fn = function(options, path)
      api.index(path, options, function(stats)
        vim.notify(vim.inspect(stats))
      end)
    end,
  },

  new = {
    command = "ZkNew",
    fn = function(options, path)
      api.new(path, options, function(res)
        if options and options.edit == false then
          return
        end
        -- neovim does not yet support window/showDocument, therefore we handle options.edit locally
        vim.cmd("edit " .. res.path)
      end)
    end,
  },

  new_from_title_selection = {
    command = { name = "ZkNewFromTitleSelection", range_only = true },
    fn = function(options, path)
      local location = util.get_lsp_location_from_selection()
      local selected_text = util.get_text_in_range(location.range)
      api.new(
        path,
        vim.tbl_extend("keep", options or {}, { insertLinkAtLocation = location, title = selected_text }),
        function(res)
          if options and options.edit == false then
            return
          end
          -- neovim does not yet support window/showDocument, therefore we handle options.edit locally
          vim.cmd("edit " .. res.path)
        end
      )
    end,
  },

  new_from_content_selection = {
    command = { name = "ZkNewFromContentSelection", range_only = true },
    fn = function(options, path)
      local location = util.get_lsp_location_from_selection()
      local selected_text = util.get_text_in_range(location.range)
      api.new(
        path,
        vim.tbl_extend("keep", options or {}, { insertLinkAtLocation = location, content = selected_text }),
        function(res)
          if options and options.edit == false then
            return
          end
          -- neovim does not yet support window/showDocument, therefore we handle options.edit locally
          vim.cmd("edit " .. res.path)
        end
      )
    end,
  },

  cd = {
    command = function(fn_name)
      return string.format("command! ZkCd lua %s()", fn_name)
    end,
    fn = function(path)
      path = path or util.resolve_notebook_path(0)
      local root = util.notebook_root(path)
      if root then
        vim.cmd("cd " .. root)
      end
    end,
  },

  notes = {
    command = "ZkNotes",
    fn = function(options, path)
      options = pickers.make_note_picker_api_options(nil, options)
      api.list(path, options, function(notes)
        pickers.note_picker(notes, "Zk Notes")
      end)
    end,
  },

  backlinks = {
    command = "ZkBacklinks",
    fn = function(options, path)
      options = pickers.make_note_picker_api_options({ linkTo = { vim.api.nvim_buf_get_name(0) } }, options)
      api.list(path, options, function(notes)
        pickers.note_picker(notes, "Zk Backlinks")
      end)
    end,
  },

  links = {
    command = "ZkLinks",
    fn = function(options, path)
      options = pickers.make_note_picker_api_options({ linkedBy = { vim.api.nvim_buf_get_name(0) } }, options)
      api.list(path, options, function(notes)
        pickers.note_picker(notes, "Zk Links")
      end)
    end,
  },

  match = {
    command = { name = "ZkMatch", range_only = true },
    fn = function(options, path)
      local selected_text = util.get_selected_text()
      options = pickers.make_note_picker_api_options({ match = selected_text }, options)
      api.list(path, options, function(notes)
        pickers.note_picker(notes, "Zk Notes matching " .. selected_text)
      end)
    end,
  },

  tags = {
    command = "ZkTags",
    fn = function(options, path)
      options = pickers.make_tag_picker_api_options(nil, options)
      api.tag.list(path, options, function(tags)
        pickers.tag_picker(tags, "Zk Tags", function(selected_tags)
          api.list(path, pickers.make_note_picker_api_options({ tags = selected_tags }, nil), function(notes)
            pickers.note_picker(notes, "Zk Notes for tag(s) " .. vim.inspect(selected_tags))
          end)
        end)
      end)
    end,
  },
}
