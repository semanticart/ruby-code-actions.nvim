local mock = require('luassert.mock')
local ruby_code_actions = require('ruby-code-actions')

local insert_frozen_string_literal_generator =
    ruby_code_actions.generators.insert_frozen_string_literal_generator
local autocorrect_with_rubocop_generator =
    ruby_code_actions.generators.autocorrect_with_rubocop_generator

local strings = ruby_code_actions.strings

local non_selection_context = {
    bufname = "my-bufname",
    bufnr = 1,
    content = {"puts \"starting\"", "", "puts \"hello world\""},
    range = {col = 1, end_col = 1, end_row = 1, row = 1},
    row = 1
}

local visual_selection_context = {
    bufname = "my-bufname",
    bufnr = 1,
    content = {"puts \"starting\"", "", "puts \"hello world\""},
    range = {col = 1, end_col = 1, end_row = 2, row = 1},
    row = 1
}

local choice_by_title = function(choices, title)
    for _, action in ipairs(choices) do
        if action.title == title then return action end
    end
    return nil
end

describe("insert_frozen_string_literal_generator", function()
    it(
        "returns nothing if the first line of the context is the frozen string literal comment",
        function()
            local context = {
                content = {
                    strings.frozen_string_literal_comment, "",
                    "puts 'hello world'"
                }
            }
            assert.is_nil(insert_frozen_string_literal_generator(context))

        end)

    it(
        "returns an action if the first line of the context is not the frozen string literal comment",
        function()
            local context = {content = {"puts 'hello world'"}}

            local choices = insert_frozen_string_literal_generator(context)

            assert.is_table(choice_by_title(choices,
                                            strings.frozen_string_literal))
        end)

    it("inserts the frozen string literal comment when the action is called",
       function()
        local api = mock(vim.api, true)

        local first_line = "puts 'hello world'"

        local context = {content = {first_line}, bufnr = 9}

        local choices = insert_frozen_string_literal_generator(context)
        local action = choice_by_title(choices,
                                       "🥶Add frozen string literal comment").action

        action()

        assert.stub(api.nvim_buf_set_lines).was_called_with(9, 0, 1, false, {
            strings.frozen_string_literal_comment, "", first_line
        })

        mock.revert(api)
    end)

    it("works if the action title is overridden", function()
        local api = mock(vim.api, true)

        local first_line = "puts 'hello world'"

        local new_title = "brrrr..."
        require('ruby-code-actions').strings.frozen_string_literal = new_title

        local context = {content = {first_line}, bufnr = 9}

        local choices = insert_frozen_string_literal_generator(context)
        local action = choice_by_title(choices, new_title).action

        action()

        assert.stub(api.nvim_buf_set_lines).was_called_with(9, 0, 1, false, {
            strings.frozen_string_literal_comment, "", first_line
        })

        mock.revert(api)

    end)
end)

describe("autocorrect_with_rubocop_generator", function()
    describe("unsafely correcting a file", function()
        local title = strings.unsafe_autocorrect_with_rubocop

        it("is an available action when no lines are selected", function()
            local choices = autocorrect_with_rubocop_generator(
                                non_selection_context)

            assert.is_table(choice_by_title(choices, title))
        end)

        it("is not an available action when lines are selected", function()
            local choices = autocorrect_with_rubocop_generator(
                                visual_selection_context)

            assert.is_nil(choice_by_title(choices, title))
        end)

        it(
            "invokes rubocop to unsafely autocorrect and re-open the current buffer when the action is called",
            function()
                local api = mock(vim.api, true)
                local overrideables =
                    mock(ruby_code_actions.overrideables, true)

                local choices = autocorrect_with_rubocop_generator(
                                    non_selection_context)
                local action = choice_by_title(choices, title).action
                action()

                assert.stub(overrideables.system).was_called_with(
                    "rubocop -A my-bufname")
                assert.stub(api.nvim_command).was_called_with("edit")

                mock.revert(api)
                mock.revert(overrideables)
            end)
    end)

    describe("safely correcting a file", function()
        local title = strings.safe_autocorrect_with_rubocop

        it("is an available action when no lines are selected", function()
            local choices = autocorrect_with_rubocop_generator(
                                non_selection_context)

            assert.is_table(choice_by_title(choices, title))
        end)

        it("is not an available action when lines are selected", function()
            local choices = autocorrect_with_rubocop_generator(
                                visual_selection_context)

            assert.is_nil(choice_by_title(choices, title))
        end)

        it(
            "invokes rubocop to safely autocorrect and re-open the current buffer when the action is called",
            function()
                local api = mock(vim.api, true)
                local overrideables =
                    mock(ruby_code_actions.overrideables, true)

                local choices = autocorrect_with_rubocop_generator(
                                    non_selection_context)
                local action = choice_by_title(choices, title).action
                action()

                assert.stub(overrideables.system).was_called_with(
                    "rubocop -a my-bufname")
                assert.stub(api.nvim_command).was_called_with("edit")

                mock.revert(api)
                mock.revert(overrideables)
            end)
    end)

    describe("autocorrecting line(s)", function()
        it(
            "calls rubocop to autocorrect the current line and replace it when the action is called with no selection",
            function()
                local title = "🤖Autocorrect line with Rubocop"

                local api = mock(vim.api, true)
                local overrideables =
                    mock(ruby_code_actions.overrideables, true)
                overrideables.readfile.returns("puts \"starting\"")
                overrideables.tempname.returns("temp-file-name")
                overrideables.readfile.returns({"puts 'starting'"})

                local choices = autocorrect_with_rubocop_generator(
                                    non_selection_context)

                local action = choice_by_title(choices, title).action
                action()

                assert.stub(api.nvim_buf_set_lines).was_called_with(1, 0, 1,
                                                                    false, {
                    "puts 'starting'"
                })
                assert.stub(overrideables.reindent).was_called_with(1, 1)

                mock.revert(api)
                mock.revert(overrideables)
            end)
        it(
            "calls rubocop to autocorrect selected lines and replace them when the action is called with a selection",
            function()
                local title = "🤖Autocorrect lines with Rubocop"

                local cmd = mock(vim.cmd, false)
                local api = mock(vim.api, true)
                local overrideables =
                    mock(ruby_code_actions.overrideables, true)
                overrideables.readfile.returns({
                    "puts \"starting\"", "", "puts \"hello world\""
                })
                overrideables.tempname.returns("temp-file-name")
                overrideables.readfile.returns({
                    "puts 'starting'", "", "puts 'hello world'"
                })

                local choices = autocorrect_with_rubocop_generator(
                                    visual_selection_context)

                local action = choice_by_title(choices, title).action
                action()

                assert.stub(api.nvim_buf_set_lines).was_called_with(1, 0, 2,
                                                                    false, {
                    "puts 'starting'", "", "puts 'hello world'"
                })

                assert.stub(overrideables.reindent).was_called_with(1, 3)

                mock.revert(cmd)
                mock.revert(api)
                mock.revert(overrideables)
            end)
    end)
end)
