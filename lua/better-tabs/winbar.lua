local state         = require("better-tabs.state")

local M             = {}

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------

local LEFT_PADDING  = "  "
local RIGHT_PADDING = "  "
local SEP           = "│"

----------------------------------------------------------------------
-- Highlights
----------------------------------------------------------------------

local function setup_highlights()
    local normal  = vim.api.nvim_get_hl(0, { name = "Normal" })
    local signcol = vim.api.nvim_get_hl(0, { name = "SignColumn" })
    local comment = vim.api.nvim_get_hl(0, { name = "Comment" })
    local vsplit  = vim.api.nvim_get_hl(0, { name = "VertSplit" })

    local bg      = signcol.bg or normal.bg
    local fg      = normal.fg

    vim.api.nvim_set_hl(0, "WinBar", { fg = fg, bg = bg })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = fg, bg = bg })

    vim.api.nvim_set_hl(0, "BetterTabsActive", {
        fg = fg,
        bg = bg,
        bold = true,
        underline = true,
    })

    vim.api.nvim_set_hl(0, "BetterTabsInactive", {
        fg = comment.fg or fg,
        bg = bg,
    })

    vim.api.nvim_set_hl(0, "BetterTabsModified", {
        fg = "#e5c07b",
        bg = bg,
    })

    vim.api.nvim_set_hl(0, "BetterTabsSeparator", {
        fg = comment.fg or fg,
        bg = bg,
    })

    vim.api.nvim_set_hl(0, "BetterTabsBorder", {
        fg = vsplit.fg or comment.fg or fg,
        bg = bg,
    })
end

----------------------------------------------------------------------
-- Diagnostics helpers
----------------------------------------------------------------------

local function get_diagnostics(bufnr)
    local counts = { errors = 0, warnings = 0 }

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return counts
    end

    local ok, diags = pcall(vim.diagnostic.get, bufnr)
    if not ok or not diags then
        return counts
    end

    for _, d in ipairs(diags) do
        if d.severity == vim.diagnostic.severity.ERROR then
            counts.errors = counts.errors + 1
        elseif d.severity == vim.diagnostic.severity.WARN then
            counts.warnings = counts.warnings + 1
        end
    end

    return counts
end

local function format_diagnostics(bufnr)
    local c = get_diagnostics(bufnr)
    local parts = {}

    if c.errors > 0 then table.insert(parts, c.errors .. "e") end
    if c.warnings > 0 then table.insert(parts, c.warnings .. "w") end

    if #parts > 0 then
        return " [" .. table.concat(parts, "/") .. "]"
    end

    return ""
end

----------------------------------------------------------------------
-- Winbar rendering
----------------------------------------------------------------------

function M.render_winbar(win)
    local st = state.get_state(win)
    if not st or #st.buffers == 0 then
        return ""
    end

    local parts = {}

    -- Left padding
    table.insert(parts, LEFT_PADDING)

    local first = true
    for i, buf in ipairs(st.buffers) do
        if not vim.api.nvim_buf_is_valid(buf) then
            goto continue
        end

        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname == "" then
            goto continue
        end

        local name = vim.fn.fnamemodify(bufname, ":t")
        local modified = vim.bo[buf].modified
        local diags = format_diagnostics(buf)

        if not first then
            table.insert(parts, "%#BetterTabsSeparator# " .. SEP .. " %*")
        end
        first = false

        local hl = (i == st.index)
            and "%#BetterTabsActive#"
            or "%#BetterTabsInactive#"

        table.insert(parts, " ")

        table.insert(parts, hl .. name .. "%*")

        if diags ~= "" then
            table.insert(parts, hl .. diags .. "%*")
        end

        if modified then
            table.insert(parts, " ")
            table.insert(parts, "%#BetterTabsModified#[+]%*")
        end

        table.insert(parts, " ")

        ::continue::
    end

    table.insert(parts, RIGHT_PADDING)

    table.insert(parts, "%#BetterTabsBorder# %*")

    return table.concat(parts, "")
end

----------------------------------------------------------------------
-- Refresh helpers
----------------------------------------------------------------------

function M.refresh(win)
    win = win or vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(win) then
        return
    end

    vim.api.nvim_win_set_option(win, "winbar", M.render_winbar(win))
end

----------------------------------------------------------------------
-- Autocmds
----------------------------------------------------------------------

function M.setup_autocmds()
    local augroup = vim.api.nvim_create_augroup("BetterTabsWinbar", { clear = true })

    vim.api.nvim_create_autocmd(
        { "BufEnter", "BufAdd", "BufWipeout", "WinEnter" },
        {
            group = augroup,
            callback = function(args)
                M.refresh(args.win)
            end,
        }
    )

    vim.api.nvim_create_autocmd(
        { "BufModifiedSet", "BufWritePost" },
        {
            group = augroup,
            callback = function()
                M.refresh(vim.api.nvim_get_current_win())
            end,
        }
    )

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = augroup,
        callback = function()
            for _, w in ipairs(vim.api.nvim_list_wins()) do
                M.refresh(w)
            end
        end,
    })

    vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
            for _, w in ipairs(vim.api.nvim_list_wins()) do
                M.refresh(w)
            end
        end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = augroup,
        callback = setup_highlights,
    })
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------

function M.setup()
    setup_highlights()
    M.setup_autocmds()
end

return M
