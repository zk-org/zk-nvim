local is_installed, lspconfig = pcall(require, 'lspconfig')

if not is_installed then error('lspconfig needs to be installed.') end

local configs = require'lspconfig/configs'

local zk_config = {
    bin = 'zk',
    extensions = {
        telescope = false,
    },
    -- How to open notes (vsplit, edit, etc...)
    open_mode = 'edit',

    log_file = '/tmp/zk-lsp.log',
}

local M = {}

M.setup = function(opts)
    zk_config = vim.tbl_deep_extend('force', zk_config, opts or {})

    if not vim.fn.executable(zk_config.bin) then error(zk_config.bin .. ' is not executable.') end

    vim.api.nvim_command("command! -nargs=0 ZkIndex :lua require'lspconfig'.zk.index()")
    vim.api.nvim_command("command! -nargs=? ZkNew :lua require'lspconfig'.zk.new(<args>)")

    -- Initialize the zk language server
    configs.zk = {
      default_config = {
        cmd = {zk_config.bin, 'lsp', '--log', zk_config.log_file};
        filetypes = {'markdown'};
        root_dir = lspconfig.util.root_pattern('.zk');
        settings = {
        };
      };
    }

    -- Index the notebook of the current note.
    configs.zk.index = function()
      vim.lsp.buf.execute_command({
        command = "zk.index",
        arguments = {vim.api.nvim_buf_get_name(0)},
      })
    end

    -- Create a new note in the current notebook.
    configs.zk.new = function(...)
      vim.lsp.buf_request(0, 'workspace/executeCommand',
        {
            command = "zk.new",
            arguments = {
                vim.api.nvim_buf_get_name(0),
                ...
            },
        },
        function(_, _, result)
          if not (result and result.path) then return end
          vim.cmd(configs.zk.settings.open_mode .. " " .. result.path)
        end
      )
    end

    lspconfig.zk.setup({
      on_attach = function(client, bufnr)
        -- Key mappings
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local keymap_opts = { noremap=true, silent=false }
        buf_set_keymap("i", "<S-tab>", "<cmd>lua vim.lsp.buf.completion()<CR>", keymap_opts)
        -- Follow a Markdown link with <CR>.
        buf_set_keymap("n", "<CR>", "<cmd>lua vim.lsp.buf.definition()<CR>", keymap_opts)
        -- Preview a note with K when the cursor is on a link.
        buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)
        -- Create a new note using the current visual selection for the note title. This will replace the selection with a link to the note.
        buf_set_keymap("v", "<CR>", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", keymap_opts)
        -- Reindex the notebook. Usually the language server does this automatically, so it's not often needed.
        buf_set_keymap("n", "<leader>ki", ":ZkIndex<CR>", keymap_opts)
        -- Create a new note after prompting for a title.
        buf_set_keymap("n", "<leader>kn", ":ZkNew {title = vim.fn.input('Title: ')}<CR>", keymap_opts)
        -- Create a new daily note in my `log/` notebook directory.
        buf_set_keymap("n", "<leader>kl", ":ZkNew {dir = 'log'}<CR>", keymap_opts)
        -- Find the backlinks for the note linked under the cursor.
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', keymap_opts)

        -- Open up Zk LSP log
        buf_set_keymap('n', 'ko', '<cmd>' .. zk_config.open_mode .. ' /tmp/zk-lsp.log<cr>', keymap_opts)
      end
    })
end

return M
