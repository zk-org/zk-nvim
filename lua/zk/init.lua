local zk = {}

local function lsp_buf_request(bufnr, cmd, args, cb)
  vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
    command = "zk." .. cmd,
    arguments = {
      vim.api.nvim_buf_get_name(bufnr),
      args,
    },
  }, function(err, res)
    assert(not err, tostring(err))
    if res then
      cb(res)
    end
  end)
end

function zk.list(args, cb)
  lsp_buf_request(0, "list", args, cb)
end

zk.tag = {}

function zk.tag.list(args, cb)
  lsp_buf_request(0, "tag.list", args, cb)
end

return zk
