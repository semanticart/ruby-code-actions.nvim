.PHONY: test
test:
	nvim --headless -u lua/spec/ruby-code-actions/minimal_init.vim -c "lua require('plenary.test_harness').test_directory_command('lua/spec/ruby-code-actions')"
