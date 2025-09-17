-- 戦いの記録。


-- name_formatter
            -- name_formatter = function(buf)
            --    -- local function fetch_and_update(bufnr)
            --    --    local id = vim.fn.fnamemodify(bufnr.name, ':t:r')
            --    --    require('zk.api').list(nil, {
            --    --       select = { 'id', 'title' },
            --    --       ids = { id },
            --    --    }, function(err, res)
            --    --       if not err and res and res[1] then
            --    --          -- 一時的に buf へ変数として保持しておく
            --    --          vim.api.nvim_buf_set_var(bufnr.number, 'zk_title', res[1].title or id)
            --    --          -- bufferline 再描画
            --    --          vim.schedule(function() require('bufferline.ui').refresh() end)
            --    --       end
            --    --    end)
            --    --    -- return vim.b.zk_title
            --    --    return id
            --    -- end
            --    -- if buf.name:match('%.md$') then
            --    --    -- -- バッファ変数にタイトルがあればそれを表示
            --    --    -- local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.number, 'zk_title')
            --    --    -- if ok and zk_title then
            --    --    --    return zk_title
            --    --    -- else
            --    --    --    -- なければ basename を表示しつつ非同期で取得開始
            --    --    --    fetch_and_update(buf)
            --    --    --    return vim.fn.fnamemodify(buf.name, ':t:r')
            --    --    -- end
            --    --    return fetch_and_update(buf)
            --    -- end
            --    local id = vim.fn.fnamemodify(buf.name, ':t:r')
            --
            --    -- すでにキャッシュされている場合はそれを返す
            --    print('called')
            --    local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
            --    if ok then return zk_title end
            --
            --    -- 非同期でタイトル取得
            --    require('zk.api').list(nil, {
            --       select = { 'id', 'absPath', 'title' },
            --    }, function(err, res)
            --       if not err and res then
            --          for _, note in ipairs(res) do
            --             if note.absPath == buf.path then
            --                vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', note.title or note.id)
            --                vim.schedule(function()
            --                   require('bufferline.ui').refresh()
            --                   local ok2, zk_title2 = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
            --                   -- if ok2 then vim.notify('buf.path: ' .. buf.path .. '\n' .. 'zk_title: ' .. zk_title2, vim.log.levels.INFO) end
            --                end)
            --                -- print(vim.inspect(note))
            --                return
            --             end
            --          end
            --       else
            --          print('zk list error')
            --       end
            --    end)
            --
            --    -- 最初は basename を返しておく
            --    return id
            -- end,

            -- name_formatter = function(buf)
            --    local id = vim.fn.fnamemodify(buf.name, ':t:r')
            --    local result = nil
            --    local done = false
            --
            --    -- zk list を非同期で呼び出すが、vim.wait で完了を待つ
            --    require('zk.api').list(nil, { select = { 'id', 'absPath', 'title' } }, function(err, res)
            --       if not err and res then
            --          for _, note in ipairs(res) do
            --             if note.absPath == buf.path then
            --                result = note.title or note.id
            --                vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', result)
            --                break
            --             end
            --          end
            --       end
            --       done = true
            --    end)
            --
            --    -- 最大1秒待機（完了前なら basename を返す）
            --    vim.wait(1000, function() return done end)
            --
            --    -- 結果があれば返す、なければ basename
            --    return result or id
            -- end,

            -- name_formatter = function(buf)
            --    local id = vim.fn.fnamemodify(buf.name, ':t:r')
            --    local result = nil
            --
            --    -- bash 経由で zk list を同期実行
            --    -- local cmd = string.format('zk list --format json "%s"', buf.path)
            --    local cmd = string.format('zk list --format json "%s" | jq -r ".[] | del(.body, .rawContent)"', buf.path)
            --    -- local cmd = string.format('zk list --format json "%s" | jq -r ".[]"', buf.path)
            --    local ok, output = pcall(vim.fn.system, cmd)
            --    print(vim.inspect(output))
            --
            --    if ok and output and output ~= '' then
            --       local decoded = vim.fn.json_decode(output)
            --       if decoded then
            --          for _, note in ipairs(decoded) do
            --             if note.absPath == buf.path then
            --                result = note.title or note.id
            --                -- キャッシュしておく
            --                pcall(vim.api.nvim_buf_set_var, buf.bufnr, 'zk_title', result)
            --                break
            --             end
            --          end
            --       end
            --    end
            --
            --    return result or id
            -- end,

            -- ---@param buf table
            -- name_formatter = function(buf)
            --    -- Return vim.b.zk_title if exists
            --    local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
            --    if ok then return zk_title end
            --
            --    -- Get title
            --    require('zk.api').list(nil, {
            --       select = { 'id', 'absPath', 'title', 'filenameStem', 'metadata' },
            --    }, function(err, notes)
            --       if not err and notes then
            --          for _, note in ipairs(notes) do
            --             if note.absPath == buf.path then
            --                -- vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', note.title or note.filenameStem or note.id)
            --                local title = note.metadata and note.metadata.author or note.title or note.filenameStem or note.id
            --                vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', title)
            --                vim.schedule(function()
            --                   require('bufferline.ui').refresh()
            --                   ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
            --                end)
            --                return
            --             end
            --          end
            --       end
            --    end)
            --
            --    -- Return basename at first
            --    local basename = vim.fn.fnamemodify(buf.name, ':t:r')
            --    return basename
            -- end,

            -- ---@param buf table
            -- name_formatter = function(buf)
            --    -- Return vim.b.zk_title if exists
            --    local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
            --    if ok then return zk_title end
            --
            --    refresh_title(buf)
            --
            --    -- Return basename at first
            --    local basename = vim.fn.fnamemodify(buf.name, ':t:r')
            --    return basename
            -- end,
            --
            name_formatter = function(buf)
               -- まずはzk_titleが既にあるかチェック
               local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, 'zk_title')
               if ok and zk_title then return zk_title end

               -- zk_titleがない場合、バックグラウンドで非同期更新をトリガー
               vim.schedule(function()
                  update_zk_list(function()
                     if refresh_title(buf) then require('bufferline.ui').refresh() end
                  end)
               end)

               -- とりあえずベースネームを返す（非同期処理完了後に更新される）
               return vim.fn.fnamemodify(buf.name, ':t:r')
            end,


-- functions in `config = function() end,` section for lazy.nvim
      -- function refresh_title(buf)
      --    -- Parse title
      --    -- if vim.b.zk_title == nil then
      --    if vim.g.zk_list then
      --       for _, note in ipairs(vim.g.zk_list) do
      --          if note.absPath == buf.path then
      --             local title = note.metadata and note.metadata.author or note.title or note.filenameStem or note.id
      --             vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', title)
      --             vim.schedule(function() require('bufferline.ui').refresh() end)
      --             break
      --          end
      --       end
      --    end
      --    -- end
      -- end
      -- vim.api.nvim_create_autocmd('BufWritePre', {
      --    pattern = '*.md', -- 対象ファイル
      --    callback = function()
      --       print('autocmd')
      --       local bufnr = vim.api.nvim_get_current_buf()
      --       local path = vim.api.nvim_buf_get_name(bufnr)
      --       local buf = { bufnr = bufnr, path = path }
      --       vim.b[bufnr].zk_title = nil
      --       -- if vim.b.zk_title ~= nil then vim.b.zk_title = nil end
      --       require('zk.api').list(nil, {
      --          select = { 'id', 'absPath', 'title', 'filenameStem', 'metadata' },
      --       }, function(err, notes)
      --          if not err then
      --             vim.g.zk_list = notes
      --             refresh_title(buf)
      --             print('autocmd, refreshed')
      --          else
      --             print('error')
      --          end
      --       end)
      --    end,
      -- })
      -- グローバルな状態管理
      local zk_state = {
         loading = false,
         last_update = 0,
         update_interval = 1000, -- 1秒間隔でアップデートを制限
      }

      function refresh_title(buf, callback)
         -- Parse title
         if vim.g.zk_list then
            for _, note in ipairs(vim.g.zk_list) do
               if note.absPath == buf.path then
                  local title = note.metadata and note.metadata.author or note.title or note.filenameStem or note.id
                  vim.api.nvim_buf_set_var(buf.bufnr, 'zk_title', title)

                  -- コールバックがあれば実行
                  if callback then vim.schedule(callback) end
                  return true
               end
            end
         end
         return false
      end

      -- zk_listを非同期で更新する関数
      function update_zk_list(callback)
         -- 既に読み込み中の場合は待機
         if zk_state.loading then
            vim.wait(5000, function() return not zk_state.loading end, 50)
            if callback then callback() end
            return
         end

         -- 頻繁な更新を防ぐ
         local now = vim.loop.now()
         if now - zk_state.last_update < zk_state.update_interval then
            if callback then callback() end
            return
         end

         zk_state.loading = true

         require('zk.api').list(nil, {
            select = { 'id', 'absPath', 'title', 'filenameStem', 'metadata' },
         }, function(err, notes)
            zk_state.loading = false
            zk_state.last_update = vim.loop.now()

            if not err and notes then
               vim.g.zk_list = notes
               print('zk_list updated')
            else
               print('zk_list update error:', err)
            end

            if callback then vim.schedule(callback) end
         end)
      end

      -- BufWritePreのautocmd
      vim.api.nvim_create_autocmd('BufWritePost', {
         pattern = '*.md',
         callback = function()
            print('autocmd triggered')
            local bufnr = vim.api.nvim_get_current_buf()
            local path = vim.api.nvim_buf_get_name(bufnr)
            local buf = { bufnr = bufnr, path = path }

            -- 既存のタイトルをクリア
            vim.b[bufnr].zk_title = nil

            -- zk_listを更新してからタイトルを更新
            update_zk_list(function()
               refresh_title(buf, function()
                  require('bufferline.ui').refresh()
                  print('autocmd completed: bufferline refreshed')
               end)
            end)
         end,
      })
   end,
