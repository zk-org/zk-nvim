local config = require("zk.config")

local client_id = nil

local M = {}

---Starts an LSP client if necessary
function M.start()
  if not client_id then
    client_id = vim.lsp.start_client(config.options.lsp.config)
  end
end

---Starts an LSP client if necessary, and attaches the given buffer.
---@param bufnr number
function M.buf_add(bufnr)
  bufnr = bufnr or 0
  M.start()
  vim.lsp.buf_attach_client(bufnr, client_id)
end

---Stops the LSP client managed by this plugin
function M.stop()
  local client = M.client()
  if client then
    client.stop()
  end
  client_id = nil
end

---Gets the LSP client managed by this plugin, might be nil
function M.client()
  return vim.lsp.get_client_by_id(client_id)
end

return M
