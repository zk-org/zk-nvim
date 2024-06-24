local config = require("zk.config")

local M = {}

local _client

local lsp_get_clients
if vim.fn.has("nvim-0.10") == 1 then
  lsp_get_clients = vim.lsp.get_clients
else
  lsp_get_clients = vim.lsp.get_active_clients
end

---Tries to find a client by name
function M.external_client()
  local client_name = config.options.lsp.config.name
  if not client_name then
    client_name = "zk"
  end

  local active_clients = lsp_get_clients({ name = client_name })

  if #active_clients == 0 then
    return
  end

  if #active_clients > 1 then
    vim.notify("Multiple Zk LSP client instances found.", vim.log.levels.WARN, { title = "Zk-nvim" })
  end

  return active_clients[1]
end

---Attaches the given buffer.
---@param bufnr integer
function M.buf_add(bufnr)
  bufnr = bufnr or 0

  vim.lsp.buf_attach_client(bufnr, M.client().id)
end

---Stops the LSP client managed by this plugin
function M.stop()
  M.client().stop()
end

---Gets the LSP client managed by this plugin
---If there is no client, it will try to find an external one or starts a new one.
function M.client()
  if _client ~= nil then
    return _client
  end

  local client = M.external_client()
  if client ~= nil then
    _client = client
    return client
  end

  local client_id, err = vim.lsp.start_client(config.options.lsp.config)
  if client_id ~= nil then
    client = vim.lsp.get_client_by_id(client_id)
    ---@cast client -nil
    _client = client
    return client
  else
    error("Failed to start Zk LSP client: " .. err)
  end
end

return M
