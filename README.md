# ruby-code-actions.nvim

Ruby code actions for [null-ls](https://github.com/jose-elias-alvarez/null-ls.nvim) in neovim.

## Usage

Require in your favorite package manager and then specify as a source. e.g. in [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'jose-elias-alvarez/null-ls.nvim',
    requires = {
        {'nvim-lua/plenary.nvim'},
        {"semanticart/ruby-code-actions.nvim"}
    },
    config = function()
        local null_ls = require("null-ls")
        local ruby_code_actions = require("ruby-code-actions")
        local sources = {
            -- require any built-ins you want
            null_ls.builtins.formatting.rubocop,
            null_ls.builtins.diagnostics.rubocop,
            -- ...
            -- now require any ruby-code-actions you want
            ruby_code_actions.insert_frozen_string_literal
        }
        null_ls.setup({sources = sources})
    end
}
```

## Currently implemented

- `insert_frozen_string_literal` for insertion of the [frozen string literal directive](https://docs.ruby-lang.org/en/3.0/doc/syntax/comments_rdoc.html#label-frozen_string_literal+Directive)

## Contributing

This is mostly an experiment on my part but I'll consider contributions. If you want to do some development, be aware that you can run existing [plenary](https://github.com/nvim-lua/plenary.nvim) specs with `make`.

## Further reading

- https://blog.semanticart.com/2021/12/31/null-ls-nvim-custom-code-actions/
