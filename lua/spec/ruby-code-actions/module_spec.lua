local mock = require('luassert.mock')
local ruby_code_actions = require('ruby-code-actions')

local insert_frozen_string_literal_generator =
    ruby_code_actions.generators.insert_frozen_string_literal_generator;

local frozen_string_literal_comment = "# frozen_string_literal: true"

describe("insert_frozen_string_literal_generator", function()
    it(
        "returns nothing if the first line of the context is the frozen string literal comment",
        function()
            local context = {
                content = {
                    frozen_string_literal_comment, "", "puts 'hello world'"
                }
            }
            assert.is_nil(insert_frozen_string_literal_generator(context))

        end)

    it(
        "returns an action if the first line of the context is not the frozen string literal comment",
        function()
            local context = {content = {"puts 'hello world'"}}

            local results = insert_frozen_string_literal_generator(context)

            assert.equals(1, table.getn(results))
            assert.equals("🥶Add frozen string literal comment",
                          results[1].title)

        end)

    it("inserts the frozen string literal comment when the action is called",
       function()
        local api = mock(vim.api, true)

        first_line = "puts 'hello world'"

        local context = {content = {first_line}, bufnr = 9}

        local action = insert_frozen_string_literal_generator(context)[1].action

        action()

        assert.stub(api.nvim_buf_set_lines).was_called_with(9, 0, 1, false, {
            frozen_string_literal_comment, "", first_line
        })
    end)
end)
