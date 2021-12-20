local util = require("telescope.zk.util")
local zk = require("zk")

local function show_notes(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Notes" })
  zk.api.list(opts.path, util.wrap_note_args({}), function(notes)
    util.show_note_picker(opts, notes)
  end)
end

local function show_backlinks(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Backlinks" })
  zk.api.list(opts.path, util.wrap_note_args({ linkTo = { vim.api.nvim_buf_get_name(0) } }), function(notes)
    util.show_note_picker(opts, notes)
  end)
end

local function show_links(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Links" })
  zk.api.list(opts.path, util.wrap_note_args({ linkedBy = { vim.api.nvim_buf_get_name(0) } }), function(notes)
    util.show_note_picker(opts, notes)
  end)
end

local function show_related(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Related" })
  zk.api.list(opts.path, util.wrap_note_args({ related = { vim.api.nvim_buf_get_name(0) } }), function(notes)
    util.show_note_picker(opts, notes)
  end)
end

local function show_tags(opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Tags" })
  zk.api.tag.list(opts.path, util.wrap_tag_args({}), function(tags)
    util.show_tag_picker(opts, tags, function(selected_tags)
      zk.api.list(opts.path, util.wrap_note_args({ tags = selected_tags }), function(notes)
        opts.prompt_title = "Zk Notes for tag(s) " .. vim.inspect(selected_tags)
        util.show_note_picker(opts, notes)
      end)
    end)
  end)
end

return require("telescope").register_extension({
  exports = {
    notes = show_notes,
    backlinks = show_backlinks,
    links = show_links,
    related = show_related,
    tags = show_tags,
  },
})
