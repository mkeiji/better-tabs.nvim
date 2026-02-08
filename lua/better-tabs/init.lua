local M = {}

local state = require("better-tabs.state")
local nav = require("better-tabs.navigation")
local autocmds = require("better-tabs.autocmds")
local vsplit = require("better-tabs.vsplit")
local commands = require("better-tabs.commands")
local winbar = require("better-tabs.winbar")

local has_telescope, _ = pcall(require, "telescope")

function M.setup()
    state.init_current_window()
    autocmds.setup()
    winbar.setup_autocmds()

    if has_telescope then
        local telescope = require("better-tabs.telescope")
        telescope.setup()

        vim.api.nvim_create_user_command(
            "BetterTabsTelescopeBuffers",
            function(opts)
                telescope.buffers(opts)
            end,
            { desc = "BetterTabs: telescope buffers by window" }
        )
    end

    -- User commands
    -- -------------

    -- navigation
    vim.api.nvim_create_user_command(
        "BetterTabsNextBuffer",
        nav.next,
        { desc = "BetterTabs: next buffer" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsPrevBuffer",
        nav.prev,
        { desc = "BetterTabs: prev buffer" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsMoveNext",
        nav.move_to_next,
        { desc = "BetterTabs: move current buffer to next window" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsMovePrev",
        nav.move_to_prev,
        { desc = "BetterTabs: move current buffer to previous window" }
    )

    -- other commands
    vim.api.nvim_create_user_command(
        "BetterVSplit",
        function() vsplit.better_vsplit() end,
        { desc = "BetterTabs: vertical split with buffer ownership" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsClose",
        commands.close,
        { desc = "BetterTabs: remove all buffer ownership from current window" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsCloseBuffer",
        commands.close_buffer,
        { desc = "BetterTabs: close current buffer from window" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsCloseOthers",
        commands.close_others,
        { desc = "BetterTabs: close other buffers from current window" }
    )

    -- for dev
    vim.api.nvim_create_user_command(
        "BetterTabsInfo",
        commands.info,
        { desc = "BetterTabs: show buffers owned by the current window" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsDebug",
        commands.debug_removed,
        { desc = "BetterTabs: show removed buffer tracking" }
    )

    vim.api.nvim_create_user_command(
        "BetterTabsAll",
        commands.debug_all,
        { desc = "BetterTabs: show all windows buffer info" }
    )
end

return M
