-- NOTE: In practice, these are only a convenience for mocking, but you _could_
-- provide your own implementations
local overrideables = {}

overrideables.tempname = function()
    return vim.api.nvim_call_function("tempname", {})
end

overrideables.writefile = function(lines, filename)
    return vim.api.nvim_call_function("writefile", {lines, filename})
end

overrideables.readfile = function(filename)
    return vim.api.nvim_call_function("readfile", {filename})
end

overrideables.system = function(cmd)
    return vim.api.nvim_call_function("system", {cmd})
end

overrideables.reindent = function(start_line, end_line)
    vim.api.nvim_command(
        "execute \"normal! " .. start_line .. "G=" .. end_line .. "G\"")
end

local helpers = {}

helpers.single_line = function(context)
    return context.range.row == context.range.end_row
end

helpers.visual_selection = function(context)
    return (context.range.row ~= context.range.end_row) or
               (context.range.col ~= context.range.end_col)
end

-- NB: as the name implies, this is lines of a selection, and does not account
-- for start/end columns. I've tried writing a function using the start/end
-- cols from `context.range` but found them unreliable. Should replace with
-- https://github.com/neovim/neovim/pull/13896 when merged or use something
-- based on
-- https://github.com/theHamsta/nvim-treesitter/blob/a5f2970d7af947c066fb65aef2220335008242b7/lua/nvim-treesitter/incremental_selection.lua#L22-L30
helpers.selected_lines = function(context)
    local lines = {}
    for i = context.range.row, context.range.end_row do
        table.insert(lines, context.content[i])
    end
    return lines
end

-- given a command with the placeholder __FILE__, write the selected_lines to a
-- tempname and invoke the command, substituting __FILE__ with the tempname
-- path
helpers.process_selected_lines_as_tempname =
    function(command, context)
        local tempname = overrideables.tempname()
        overrideables.writefile(helpers.selected_lines(context), tempname)
        overrideables.system(command:gsub("__FILE__", tempname))
        return overrideables.readfile(tempname)
    end

local insert_frozen_string_literal_generator = function(context)
    local frozen_string_literal_comment = "# frozen_string_literal: true"
    local first_line = context.content[1]

    if first_line ~= frozen_string_literal_comment then
        return {
            {
                title = "🥶Add frozen string literal comment",
                action = function()
                    local lines = {
                        frozen_string_literal_comment, "", first_line
                    }

                    vim.api
                        .nvim_buf_set_lines(context.bufnr, 0, 1, false, lines)
                end
            }
        }
    end
end

local autocorrect_with_rubocop_generator = function(context)
    local actions = {}

    if not helpers.visual_selection(context) then
        local autocorrect_file = function(mode, context)
            overrideables.system("rubocop -" .. mode .. " " .. context.bufname)
            vim.api.nvim_command("edit")
        end

        table.insert(actions, {
            title = "🤖Safe Autocorrect with Rubocop",
            action = function() autocorrect_file("a", context) end
        })
        table.insert(actions, {
            title = "🤖Unsafe Autocorrect with Rubocop",
            action = function() autocorrect_file("A", context) end
        })
    end

    local plural = helpers.single_line(context) and "" or "s"

    table.insert(actions, {
        title = "🤖Autocorrect line" .. plural .. " with Rubocop",
        action = function()
            result = helpers.process_selected_lines_as_tempname(
                         "rubocop -a __FILE__", context)
            vim.api.nvim_buf_set_lines(context.bufnr, context.row - 1,
                                       context.range.end_row, false, result)

            -- re-indent changed lines since they've likely lossed their
            -- indention context
            overrideables.reindent(context.row,
                                   context.row + table.getn(result) - 1)
        end
    })

    return actions
end

local null_ls = require("null-ls")

local make_code_action = function(fun)
    return {
        method = null_ls.methods.CODE_ACTION,
        filetypes = {"ruby"},
        generator = {fn = fun}
    }
end

return {
    generators = {
        autocorrect_with_rubocop_generator = autocorrect_with_rubocop_generator,
        insert_frozen_string_literal_generator = insert_frozen_string_literal_generator
    },
    overrideables = overrideables,
    autocorrect_with_rubocop = make_code_action(
        autocorrect_with_rubocop_generator),
    insert_frozen_string_literal = make_code_action(
        insert_frozen_string_literal_generator)
}
