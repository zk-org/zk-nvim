local zk = {}

local utils = require 'zk.utils'

local config = {
  create_user_commands = true,
  daily_dir = nil,
}

-- set up basic options and functionality
zk.setup = function(user_config)
  config = user_config and vim.tbl_deep_extend('keep', user_config, config) or config

  -- setup user commands for zk
  if config.create_user_commands then
    vim.api.nvim_exec(
      [[
      command! -nargs=? ZkNew lua require'zk'.new(<args>)
      command! -nargs=0 ZkIndex lua require'zk'.index()
    ]],
      false
    )
  end
end

-- wrapper for `zk index`
zk.index = function(lsp_opts)
  -- set default options to pass to LSP server
  local lsp_defaults = {
    force = false,
  }
  lsp_opts = lsp_opts and vim.tbl_extend('keep', lsp_opts, lsp_defaults) or lsp_defaults

  table.insert(lsp_opts, 1, vim.api.nvim_buf_get_name(0))

  vim.lsp.buf.execute_command {
    command = 'zk.index',
    arguments = lsp_opts,
  }
end

-- wrapper for `zk new`
zk.new = function(lsp_opts, wrapper_opts)
  -- set default options to pass to LSP server
  local lsp_defaults = {
    title = nil,
    dir = nil,
    content = nil,
    group = nil,
    template = nil,
    extra = nil,
    date = nil,
    insertLinkAtLocation = nil,
  }
  lsp_opts = lsp_opts and vim.tbl_extend('keep', lsp_opts, lsp_defaults) or lsp_defaults

  -- options for this wrapper function
  local wrapper_defaults = {
    edit_cmd = 'edit',
    debug = false,
  }
  wrapper_opts = wrapper_opts and vim.tbl_extend('keep', wrapper_opts, wrapper_defaults) or wrapper_defaults

  -- prompt the user for a title for the note
  if not lsp_opts.title then
    vim.ui.input({
      prompt = 'Title: ',
      default = nil,
      completion = nil,
    }, function(input)
      lsp_opts.title = input
    end)
  end

  table.insert(lsp_opts, 1, vim.api.nvim_buf_get_name(0))

  if debug then
    utils.debug_tbl(lsp_opts, 'LSP Options')
  end

  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.new',
    arguments = lsp_opts,
  }, function(err, result, _, _)
    if not err and result and result.path and wrapper_opts.edit_cmd then
      vim.cmd(wrapper_opts.edit_cmd .. ' ' .. result.path)
    end

    if debug then
      utils.debug_tbl(err, 'LSP Error Message')
      utils.debug_tbl(result, 'LSP Result')
    end
  end)
end

-- lists notes
zk.list = function(lsp_opts, wrapper_opts)
  -- set default options to pass to LSP server
  local lsp_defaults = {
    select = {
      'title',
      'filename',
      'created',
      'lead',
    },
    hrefs = nil,
    limit = nil,
    match = nil,
    exactMatch = nil,
    excludeHrefs = nil,
    tags = nil,
    mention = nil,
    mentionedBy = nil,
    linkTo = nil,
    linkedBy = nil,
    orphan = nil,
    related = nil,
    maxDistance = nil,
    recursive = nil,
    created = nil,
    createdBefore = nil,
    createdAfter = nil,
    modified = nil,
    modifiedBefore = nil,
    modifiedAfter = nil,
    sort = nil,
  }
  lsp_opts = lsp_opts and vim.tbl_extend('keep', lsp_opts, lsp_defaults) or lsp_defaults

  -- options for this wrapper function
  local wrapper_defaults = {
    edit_cmd = 'edit',
    debug = false,
  }
  wrapper_opts = wrapper_opts and vim.tbl_extend('keep', wrapper_opts, wrapper_defaults) or wrapper_defaults

  table.insert(lsp_opts, 1, vim.api.nvim_buf_get_name(0))

  if debug then
    utils.debug_tbl(lsp_opts, 'LSP Options')
  end

  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.list',
    arguments = lsp_opts,
  }, function(err, result, _, _)
    if debug then
      utils.debug_tbl(err, 'LSP Error Message')
      utils.debug_tbl(result, 'LSP Result')
    end

    if not err then
      return result
    end
  end)
end

-- lists tags out
zk.list_tags = function(wrapper_opts, lsp_opts)
  -- set default options to pass to LSP server
  local lsp_defaults = {
    sort = nil,
  }
  lsp_opts = lsp_opts and vim.tbl_extend('keep', lsp_opts, lsp_defaults) or lsp_defaults

  -- options for this wrapper function
  local wrapper_defaults = {
    path = '',
  }
  wrapper_opts = wrapper_opts and vim.tbl_extend('keep', wrapper_opts, wrapper_defaults) or wrapper_defaults

  table.insert(lsp_opts, 1, vim.api.nvim_buf_get_name(0))

  if debug then
    utils.debug_tbl(lsp_opts, 'LSP Options')
  end

  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.tag.list',
    arguments = lsp_opts,
  }, function(err, result, _, _)
    if debug then
      utils.debug_tbl(err, 'LSP Error Message')
      utils.debug_tbl(result, 'LSP Result')
    end

    if not err then
      return result
    end
  end)
end

-- telescope picker
zk.find_notes = function(handler)
  if handler == 'telescope' then
    local pickers = require 'telescope.pickers'
    local finders = require 'telescope.finders'
    local conf = require('telescope.config').values

    pickers.new({}, {
      prompt_title = 'Find notes',
      finder = finders.new_oneshot_job({
        'zk',
        'list',
        '-q',
        '-P',
        '--format',
        '{{ abs-path }}\t{{ title }}',
      }, {}),
      sorter = conf.generic_sorter {},
      previewer = conf.file_previewer {},
    }):find()
  end
end

-- creates or edits existing daily note
zk.daily = function()
  if config.daily_dir then
    return nil
  else
    vim.notify('Please setup a directory for your daily notes in the `daily_dir` config option in zk.setup()', 'error')
  end
end

-- jump to the next link
zk.next_link = function()
  vim.diagnostic.goto_next {
    severity = vim.diagnostic.severity.HINT,
  }
end

-- jump to the previous link
zk.prev_link = function()
  vim.diagnostic.goto_prev {
    severity = vim.diagnostic.severity.HINT,
  }
end

return zk
