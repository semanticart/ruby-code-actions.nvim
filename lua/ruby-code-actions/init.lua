local null_ls = require("null-ls")

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

local insert_frozen_string_literal = {
    method = null_ls.methods.CODE_ACTION,
    filetypes = {"ruby"},
    generator = {fn = insert_frozen_string_literal_generator}
}

return {
    generators = {
        insert_frozen_string_literal_generator = insert_frozen_string_literal_generator
    },
    insert_frozen_string_literal = insert_frozen_string_literal
}
