local state               = require("better-tabs.state")

local M                   = {}

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------

local LEFT_PADDING        = "  "
local RIGHT_PADDING       = "  "
local SEP                 = "│"

local OVERFLOW_LEFT_ICON  = "‹"
local OVERFLOW_RIGHT_ICON = "›"

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

    vim.api.nvim_set_hl(0, "BetterTabsOverflow", {
        fg = comment.fg or fg,
        bg = bg,
        italic = true,
    })

    vim.api.nvim_set_hl(0, "BetterTabsOverflowCount", {
        fg = comment.fg or fg,
        bg = bg,
        bold = true,
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
-- Render helpers
----------------------------------------------------------------------

local function render_buffer(buf, is_active)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    if name == "" then return nil end

    local hl = is_active
        and "%#BetterTabsActive#"
        or "%#BetterTabsInactive#"

    local parts = { hl .. name .. "%*" }

    local diags = format_diagnostics(buf)
    if diags ~= "" then
        table.insert(parts, hl .. diags .. "%*")
    end

    if vim.bo[buf].modified then
        table.insert(parts, " %#BetterTabsModified#[+]%*")
    end

    local text = table.concat(parts, "")
    local width = vim.fn.strdisplaywidth(name .. diags .. (vim.bo[buf].modified and " [+]" or ""))

    return {
        text  = text,
        width = width,
    }
end

----------------------------------------------------------------------
-- Winbar rendering
----------------------------------------------------------------------

function M.render_winbar(win)
    local st = state.get_state(win)
    if not st or #st.buffers == 0 then
        return ""
    end

    local win_width = vim.api.nvim_win_get_width(win)
    local items = {}

    for i, buf in ipairs(st.buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
            local item = render_buffer(buf, i == st.index)
            if item then
                item.index = i
                table.insert(items, item)
            end
        end
    end

    if #items == 0 then
        return ""
    end

    local sepw     = vim.fn.strdisplaywidth(" " .. SEP .. " ")
    local overflow = vim.fn.strdisplaywidth(" ‹ +99 ")

    -- reserve space for overflow on both sides
    local used     =
        vim.fn.strdisplaywidth(LEFT_PADDING .. RIGHT_PADDING) + 2 +
        items[st.index].width +
        overflow * 2

    local start    = st.index
    local finish   = st.index

    -- Expand around active buffer
    while true do
        local added = false

        if start > 1 and used + sepw + items[start - 1].width <= win_width then
            start = start - 1
            used = used + sepw + items[start].width
            added = true
        end

        if finish < #items and used + sepw + items[finish + 1].width <= win_width then
            finish = finish + 1
            used = used + sepw + items[finish].width
            added = true
        end

        if not added then
            break
        end
    end

    local hidden_left  = start - 1
    local hidden_right = #items - finish

    local parts        = {}
    table.insert(parts, LEFT_PADDING)

    -- Left overflow
    if hidden_left > 0 then
        table.insert(
            parts,
            string.format(
                "%%#BetterTabsOverflow# %s %%*%%#BetterTabsOverflowCount#+%d%%* ",
                OVERFLOW_LEFT_ICON,
                hidden_left
            )
        )
    end

    for i = start, finish do
        if i > start then
            table.insert(parts, "%#BetterTabsSeparator# " .. SEP .. " %*")
        end
        table.insert(parts, " " .. items[i].text .. " ")
    end

    -- Right overflow
    if hidden_right > 0 then
        table.insert(
            parts,
            string.format(
                " %%#BetterTabsOverflowCount#+%d%%* %%#BetterTabsOverflow#%s %%*",
                hidden_right,
                OVERFLOW_RIGHT_ICON
            )
        )
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
