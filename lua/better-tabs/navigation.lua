local state = require("better-tabs.state")
local winbar = require("better-tabs.winbar")

local M = {}

local function goto_index(delta)
    local win = vim.api.nvim_get_current_win()
    local st = state.get_state(win)
    if not st or #st.buffers <= 1 then return end

    st.index = ((st.index - 1 + delta) % #st.buffers) + 1
    vim.api.nvim_set_current_buf(st.buffers[st.index])
    vim.api.nvim_win_set_var(win, "better_tabs", st)

    winbar.refresh(win)
end

function M.next()
    goto_index(1)
end

function M.prev()
    goto_index(-1)
end

local function get_next_window()
    local wins = vim.api.nvim_list_wins()
    local current_win = vim.api.nvim_get_current_win()
    local current_idx = 1
    for i, w in ipairs(wins) do
        if w == current_win then
            current_idx = i
            break
        end
    end
    local next_idx = ((current_idx) % #wins) + 1
    return wins[next_idx]
end

local function get_prev_window()
    local wins = vim.api.nvim_list_wins()
    local current_win = vim.api.nvim_get_current_win()
    local current_idx = 1
    for i, w in ipairs(wins) do
        if w == current_win then
            current_idx = i
            break
        end
    end
    local prev_idx = current_idx - 1
    if prev_idx < 1 then prev_idx = #wins end
    return wins[prev_idx]
end

function M.move_to_next()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local st = state.get_state(current_win)

    if not st then return end

    local found = false
    for _, b in ipairs(st.buffers) do
        if b == current_buf then
            found = true
            break
        end
    end
    if not found then return end

    local target_win = get_next_window()
    if not target_win or target_win == current_win then return end

    state.add_buffer_only(target_win, current_buf)

    state.remove_buffer(current_win, current_buf)

    winbar.refresh(target_win)

    st = state.get_state(current_win)
    if not st or #st.buffers == 0 then
        vim.api.nvim_win_close(current_win, false)
    else
        local new_index = math.min(st.index, #st.buffers)
        if new_index > 0 then
            local new_buf = st.buffers[new_index]
            if vim.api.nvim_buf_is_valid(new_buf) then
                vim.api.nvim_win_set_buf(current_win, new_buf)
            end
        end
        winbar.refresh(current_win)
    end

    print("BetterTabs: moved buffer to next window")
end

function M.move_to_prev()
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local st = state.get_state(current_win)

    if not st then return end

    local found = false
    for _, b in ipairs(st.buffers) do
        if b == current_buf then
            found = true
            break
        end
    end
    if not found then return end

    local target_win = get_prev_window()
    if not target_win or target_win == current_win then return end

    state.add_buffer_only(target_win, current_buf)

    state.remove_buffer(current_win, current_buf)

    winbar.refresh(target_win)

    st = state.get_state(current_win)
    if not st or #st.buffers == 0 then
        vim.api.nvim_win_close(current_win, false)
    else
        local new_index = math.min(st.index, #st.buffers)
        if new_index > 0 then
            local new_buf = st.buffers[new_index]
            if vim.api.nvim_buf_is_valid(new_buf) then
                vim.api.nvim_win_set_buf(current_win, new_buf)
            end
        end
        winbar.refresh(current_win)
    end

    print("BetterTabs: moved buffer to previous window")
end

return M
