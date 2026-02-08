local state = require("better-tabs.state")
local winbar = require("better-tabs.winbar")

local M = {}

function M.better_vsplit()
    local old_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    local old_state = state.get_state(old_win)
    local target_buf = nil

    if old_state and #old_state.buffers > 1 then
        for i, b in ipairs(old_state.buffers) do
            if b ~= buf then
                target_buf = b
                break
            end
        end
    end

    local has_fallback = target_buf and vim.api.nvim_buf_is_valid(target_buf)

    if not has_fallback then
        vim.cmd("browse vsplit")
        local new_win = vim.api.nvim_get_current_win()
        local new_buf = vim.api.nvim_get_current_buf()

        vim.api.nvim_win_set_var(new_win, "better_tabs", { buffers = { new_buf }, index = 1 })

        winbar.refresh(old_win)
        winbar.refresh(new_win)
        return
    end

    state.remove_buffer(old_win, buf)

    vim.cmd("vsplit")
    local new_win = vim.api.nvim_get_current_win()

    state.init_current_window()

    vim.api.nvim_win_set_buf(old_win, target_buf)

    winbar.refresh(old_win)
    winbar.refresh(new_win)
end

return M