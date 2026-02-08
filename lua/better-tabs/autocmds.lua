local M = {}
local state = require("better-tabs.state")

function M.setup()
    -- Main augroup
    local augroup = vim.api.nvim_create_augroup("BetterTabs", { clear = true })

    -------------------------
    -- 1️⃣ Disable native tabline
    -------------------------
    vim.api.nvim_create_autocmd("User", {
        callback = function()
            vim.opt.showtabline = 0
        end,
    })

    -------------------------
    -- 1️⃣ Add buffers on BufEnter and sync index
    -------------------------
    vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,

        callback = function(args)
            local win = vim.api.nvim_get_current_win()
            local buf = args.buf

            if state.moved_buffers[buf] then
                return
            end

            if vim.bo[buf].buftype ~= "" then return end

            state.add_buffer(win, buf)

            local st = state.get_state(win)
            if st then
                for i, b in ipairs(st.buffers) do
                    if b == buf then
                        st.index = i
                        vim.api.nvim_win_set_var(win, "better_tabs", st)
                        break
                    end
                end
            end
        end,
    })

    -------------------------
    -- 2️⃣ Remove buffer ownership on BufWipeout
    -------------------------
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = augroup,
        callback = function(args)
            local buf = args.buf
            for _, w in ipairs(vim.api.nvim_list_wins()) do
                state.remove_buffer(w, buf)
            end
        end,
    })

    -------------------------
    -- 3️⃣ Auto-claim buffers on edit if not owned
    -------------------------
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("BetterTabsClaim", { clear = true }),
        callback = function(args)
            local buf = args.buf

            if state.moved_buffers[buf] then return end

            if vim.bo[buf].buftype ~= "" then return end

            for _, w in ipairs(vim.api.nvim_list_wins()) do
                local st = state.get_state(w)
                if st then
                    for _, b in ipairs(st.buffers) do
                        if b == buf then return end
                    end
                end
            end

            local win = vim.api.nvim_get_current_win()
            state.add_buffer(win, buf)
        end,
    })

    -------------------------
    -- 4️⃣ Auto-cleanup when window is closed
    -------------------------
    vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        callback = function(args)
            local win_id = tonumber(args.file)
            if not win_id then return end

            local st = state.get_state(win_id)
            if not st then return end

            vim.schedule(function()
                for _, buf in ipairs(st.buffers) do
                    if vim.api.nvim_buf_is_valid(buf) then
                        local buffer_owned = false
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            if win ~= win_id then
                                local win_state = state.get_state(win)
                                if win_state then
                                    for _, b in ipairs(win_state.buffers) do
                                        if b == buf then
                                            buffer_owned = true
                                            break
                                        end
                                    end
                                end
                                if buffer_owned then break end
                            end
                        end

                        if not buffer_owned then
                            local buf_name = vim.api.nvim_buf_get_name(buf)
                            if buf_name ~= "" and not buf_name:match("%[Scratch%]$") and not buf_name:match("%[No Name%]$") then
                                vim.api.nvim_buf_delete(buf, { force = true })
                            end
                        end
                    end
                end
            end)
        end,
    })
end

return M
