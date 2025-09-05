local config = require("zk.config")

local client_id = nil

local M = {}

---Tries to find a client by name
function M.external_client()
  local client_name = config.options.lsp.config.name
  if not client_name then
    client_name = "zk"
  end

  local active_clients = {}
  active_clients = vim.lsp.get_clients({ name = client_name })

  if next(active_clients) == nil then
    return
  end

  -- return first lsp server that is actually in use
  for _, v in ipairs(active_clients) do
    if next(v.attached_buffers) ~= nil then
      return v.id
    end
  end
end

function M.start()
  if not client_id then
    client_id = M.external_client()
  end

  if not client_id then
    local id = vim.lsp.start(config.options.lsp.config)
    if id then
      client_id = id
    end
  end
end

---Starts an LSP client if necessary, and attaches the given buffer.
---@param bufnr number
function M.buf_add(bufnr)
  bufnr = bufnr or 0
  M.start()

  if client_id then
    vim.lsp.buf_attach_client(bufnr, client_id)
  end
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
  if client_id then
    return vim.lsp.get_client_by_id(client_id)
  else
    print("Error: No client attached.")
    return
  end
end

return M
