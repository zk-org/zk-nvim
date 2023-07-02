local exec = require("fzf-lua").fzf_exec
local builtin_previewer = require("fzf-lua.previewer.builtin")
local ansi_codes = require("fzf-lua").utils.ansi_codes
local actions = require("fzf-lua").actions

local M = {}

local delimiter = "\x01"

local fzf_lua_previewer = builtin_previewer.buffer_or_file:extend()

function fzf_lua_previewer:new(o, opts, fzf_win)
    fzf_lua_previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, fzf_lua_previewer)
    return self
end

function fzf_lua_previewer:parse_entry(entry)
    local path = entry:match("([^" .. delimiter .. "]+)")
    return { path = path, }
end

local function path_from_selected(selected)
    return vim.tbl_map(function(line)
        return string.match(line, "([^" .. delimiter .. "]+)")
    end, selected)
end

M.note_picker_list_api_selection = { "title", "absPath", "path" }

function M.show_note_picker(notes, options, cb)
    options = options or {}
    local notes_by_path = {}
    local fzf_opts = vim.tbl_extend("force", {
        prompt = options.title .. "> ",
        previewer = fzf_lua_previewer,
        fzf_opts = {
            ["--delimiter"] = delimiter,
            ["--tiebreak"] = "index",
            ["--with-nth"] = 2,
            ["--tabstop"] = 4,
        },
        -- we rely on `fzf-lua` to open notes in any other case than the default (pressing enter) 
        -- to take advantage of the plugin builtin actions like opening in a split
        actions = {
            ["default"] = function(selected, opts)
                local selected_notes = vim.tbl_map(function(line)
                    local path = string.match(line, "([^" .. delimiter .. "]+)")
                    return notes_by_path[path]
                end, selected)
                if options.multi_select then
                    cb(selected_notes)
                else
                    cb(selected_notes[1])
                end
            end,
            ["ctrl-s"] = function(selected, opts)
                local entries = path_from_selected(selected)
                actions.file_split(entries, opts)
            end,
            ["ctrl-v"] = function(selected, opts)
                local entries = path_from_selected(selected)
                actions.file_vsplit(entries, opts)
            end,
            ["ctrl-t"] = function(selected, opts)
                local entries = path_from_selected(selected)
                actions.file_tabedit(entries, opts)
            end,
        },
    }, options.fzf_lua or {})

    exec(function(fzf_cb)
        for _, note in ipairs(notes) do
            local title = note.title or note.path
            local entry = table.concat({ note.absPath, title }, delimiter)
            notes_by_path[note.absPath] = note
            fzf_cb(entry)
        end
        fzf_cb() --EOF
    end, fzf_opts)
end

function M.show_tag_picker(tags, options, cb)
    options = options or {}
    local tags_by_name = {}
    local fzf_opts = vim.tbl_extend("force", {
        prompt = options.title .. "> ",
        fzf_opts = {
            ["--delimiter"] = delimiter,
            ["--tiebreak"] = "index",
            ["--nth"] = 2,
            ["--exact"] = "",
            ["--tabstop"] = 4,
        },
        fn_selected = function(selected, _)
            -- for some reason, fzf lua returns an empty string as the first selected line. this was
            -- causing the tbl_map to generate a result zk-nvim can't resolve to open notes
            table.remove(selected, 1)
            local selected_tags = vim.tbl_map(function(line)
                local name = string.match(line, "%d+%s+" .. delimiter .. "(.+)")
                return tags_by_name[name]
            end, selected)
            if options.multi_select then
                cb(selected_tags)
            else
                cb(selected_tags[1])
            end
        end
    }, options.fzf_lua or {})

    exec(function(fzf_cb)
        for _, tag in ipairs(tags) do
            -- formatting the note count to have some color, and adding a bit of space
            local note_count = ansi_codes.bold(
                ansi_codes.magenta(
                    string.format("%-4d", tag.note_count)
                )
            )
            local entry = table.concat({
                note_count,
                tag.name
            }, delimiter)
            tags_by_name[tag.name] = tag
            fzf_cb(entry)
        end
        fzf_cb() --EOF
    end, fzf_opts)
end

return M
