local state = require("better-tabs.state")

local M = {}

function M.info()
    local win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local st = state.get_state(win)
    if not st or #st.buffers == 0 then
        print("BetterTabs: no buffers registered in this window")
        return
    end

    local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
    print("BetterTabs window buffers (index = " .. st.index .. "):")
    for i, b in ipairs(st.buffers) do
        local name = vim.api.nvim_buf_get_name(b)
        local marker = (b == current_buf) and " [CURRENT]" or ""
        local index_marker = (i == st.index) and " [INDEX]" or ""
        print(string.format("  %d: %s%s%s", i, name ~= "" and name or "[No Name]", marker, index_marker))
    end

    local expected_buf = st.buffers[st.index]
    if expected_buf ~= current_buf then
        print("⚠️  SYNC ISSUE: Index points to different buffer than current!")
    else
        print("✅ Index and current buffer are in sync")
    end
end

function M.close_buffer()
    local win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local st = state.get_state(win)

    if not st or #st.buffers == 0 then
        print("BetterTabs: no buffers to close in this window")
        return
    end

    local current_index = nil
    for i, b in ipairs(st.buffers) do
        if b == current_buf then
            current_index = i
            break
        end
    end

    if not current_index then
        print("BetterTabs: current buffer not found in window's buffer list")
        return
    end

    local had_multiple_buffers = #st.buffers > 1

    state.remove_buffer(win, current_buf)

    st = state.get_state(win)

    if st and #st.buffers > 0 then
        local new_index = math.min(current_index, #st.buffers)
        if new_index == 0 then new_index = 1 end
        local new_buf = st.buffers[new_index]

        if vim.api.nvim_buf_is_valid(new_buf) then
            vim.api.nvim_win_set_buf(win, new_buf)
        end
    else
        local empty_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(empty_buf, "[Empty]")
        vim.api.nvim_win_set_buf(win, empty_buf)
        state.add_buffer(win, empty_buf)
    end

    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(current_buf) then return end

        local buffer_owned = false
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            local win_state = state.get_state(w)
            if win_state then
                for _, b in ipairs(win_state.buffers) do
                    if b == current_buf then
                        buffer_owned = true
                        break
                    end
                end
            end
            if buffer_owned then break end
        end

        if not buffer_owned then
            local buf_name = vim.api.nvim_buf_get_name(current_buf)
            if buf_name ~= "" and not buf_name:match("%[Scratch%]$") and not buf_name:match("%[No Name%]$") then
                vim.api.nvim_buf_delete(current_buf, { force = true })
            end
        end
    end)
end

function M.close()
    local win = vim.api.nvim_get_current_win()
    local st = state.get_state(win)
    if not st then
        print("BetterTabs: nothing to clean up in this window")
        return
    end

    for _, buf in ipairs(st.buffers) do
        state.remove_buffer(win, buf)
    end

    require("better-tabs.winbar").refresh(win)

    print("BetterTabs: cleared buffer ownership for this window")
end

function M.close_others()
    local win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()
    local st = state.get_state(win)

    if not st or #st.buffers == 0 then
        print("BetterTabs: no buffers in this window")
        return
    end

    for _, buf in ipairs(st.buffers) do
        if buf ~= current_buf then
            state.remove_buffer(win, buf)
        end
    end

    require("better-tabs.winbar").refresh(win)

    print("BetterTabs: closed other buffers in this window")
end

function M.debug_removed()
    local count = 0
    for key, _ in pairs(state.removed_buffers) do
        count = count + 1
        print("  " .. key)
    end
    print("BetterTabs: tracking " .. count .. " removed buffer-window pairs")
end

function M.debug_all()
    local wins = vim.api.nvim_list_wins()
    for _, win in ipairs(wins) do
        local st = state.get_state(win)
        local current_buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(current_buf)

        print("Window " .. win .. " (current: " .. (buf_name ~= "" and buf_name or "[No Name]") .. "):")
        if st and #st.buffers > 0 then
            for i, b in ipairs(st.buffers) do
                local name = vim.api.nvim_buf_get_name(b)
                local marker = (b == current_buf) and " [CURRENT]" or ""
                print(string.format("  %d: %s%s", i, name ~= "" and name or "[No Name]", marker))
            end
        else
            print("  (no buffers)")
        end
        print("")
    end
end

return M
