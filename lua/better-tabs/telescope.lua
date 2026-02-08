local state = require("better-tabs.state")
local M = {}

function M.buffers(opts)
    opts = opts or {}
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local make_entry = require("telescope.make_entry")

    local results = {}
    local display = {}

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local win_state = state.get_state(win)
        if win_state then
            for _, buf in ipairs(win_state.buffers) do
                if vim.api.nvim_buf_is_valid(buf) then
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name ~= "" then
                        local exists = false
                        for _, r in ipairs(results) do
                            if r.buf == buf then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(results, {
                                buf = buf,
                                bufnr = buf,
                                filename = buf_name,
                                winnr = win,
                            })
                            table.insert(display, string.format("%s (win %d)", vim.fn.fnamemodify(buf_name, ":t"), win))
                        end
                    end
                end
            end
        end
    end

    pickers.new(opts, {
        prompt_title = "Better-Tabs Buffers",
        finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = vim.fn.fnamemodify(entry.filename, ":t") .. " (win " .. entry.winnr .. ")",
                    ordinal = entry.filename,
                    filename = entry.filename,
                }
            end,
        }),
        sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection and selection.value then
                    local entry = selection.value
                    vim.api.nvim_set_current_win(entry.winnr)
                    vim.api.nvim_win_set_buf(entry.winnr, entry.buf)
                end
            end)
            return true
        end,
    }):find()
end

function M.setup()
end

return M
