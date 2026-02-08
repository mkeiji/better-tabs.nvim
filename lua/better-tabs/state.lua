local M = {}
local VAR = "better_tabs"

M.moved_buffers = {}
M.removed_buffers = {}

local function get_state(win)
    local ok, state = pcall(vim.api.nvim_win_get_var, win, VAR)
    if ok then return state end
    return nil
end

local function set_state(win, state)
    vim.api.nvim_win_set_var(win, VAR, state)
end

function M.add_moved(buf)
    M.moved_buffers[buf] = true
end

function M.clear_moved(buf)
    M.moved_buffers[buf] = nil
end

function M.init_current_window()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    set_state(win, { buffers = { buf }, index = 1 })
end

function M.add_buffer(win, buf)
    local key = tostring(win) .. ":" .. tostring(buf)
    if M.removed_buffers[key] then
        return
    end

    local current_state = get_state(win)
    local current_buf = vim.api.nvim_get_current_buf()

    if current_state and current_buf == buf then
        local existing_index = nil
        for i, b in ipairs(current_state.buffers) do
            if b == buf then
                existing_index = i
                break
            end
        end

        if not existing_index and current_state.index > 0 and current_state.index <= #current_state.buffers then
            local current_buf_at_index = current_state.buffers[current_state.index]
            local buf_name = vim.api.nvim_buf_get_name(current_buf_at_index)
            if buf_name == "" or buf_name:match("%[Scratch%]$") or buf_name:match("%[No Name%]$") then
                current_state.buffers[current_state.index] = buf
                set_state(win, current_state)
                return
            end
        end
    end

    local state = get_state(win) or { buffers = {}, index = 1 }
    for _, b in ipairs(state.buffers) do
        if b == buf then return end
    end
    table.insert(state.buffers, buf)

    if vim.api.nvim_get_current_buf() == buf then
        state.index = #state.buffers
    end

    set_state(win, state)
end

function M.add_buffer_only(win, buf)
    local key = tostring(win) .. ":" .. tostring(buf)
    if M.removed_buffers[key] then
        return
    end

    local st = get_state(win)
    if not st then
        st = { buffers = {}, index = 1 }
    end

    for _, b in ipairs(st.buffers) do
        if b == buf then return end
    end

    table.insert(st.buffers, buf)
    set_state(win, st)
end

function M.remove_buffer(win, buf)
    local state = get_state(win)
    if not state then return end
    for i, b in ipairs(state.buffers) do
        if b == buf then
            table.remove(state.buffers, i)
            state.index = math.min(state.index, #state.buffers)
            set_state(win, state)

            local key = tostring(win) .. ":" .. tostring(buf)
            M.removed_buffers[key] = true

            vim.defer_fn(function()
                M.removed_buffers[key] = nil
            end, 1000)
            return
        end
    end
end

function M.get_state(win)
    return get_state(win)
end

return M
