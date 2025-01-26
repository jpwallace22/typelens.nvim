# TypeLens

A Neovim plugin for quick and easy TypeScript type checking directly within the editor. TypeLens uses TypeScript's compiler with an npx executable and provides feedback in the quickfix window.

## Features

- 🔍 Display errors in either quickfix or [Trouble](https://github.com/folke/trouble.nvim)
- 🔄 Non-blocking asynchronous execution
- 🎨 Clean error output formatting

## Requirements

- Neovim >= 0.8.0
- Node.js and TypeScript installed in your project
- (Optional) [Trouble](https://github.com/folke/trouble.nvim) for enhanced error display

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jpwallace22/typelens.nvim",
  dependencies = {
    "folke/trouble.nvim", -- optional but recommended
  },
  opts = {
    -- your configuration
  }
}
```

## Configuration

TypeLens comes with sensible defaults but can be customized to your needs:

```lua
{
  "jpwallace22/typelens",
  opts = {
    display_output = "trouble", 
    auto_open = true,          
    tsc_command = {
      "npx",
      "tsc",
      "--noEmit",
	  },
    keys = {
      check_types = "<leader>ck",
    },
  }
}
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `display_output` | string | `"trouble"` | Where to display errors. Options: `"trouble"` or `"quickfix"` |
| `tsc_command` | table | `"npx tsc --noEmit"` | Command to run TypeScript compiler |
| `auto_open` | boolean | `true` | Automatically open output window when errors are found |
| `keys.check_types` | string | `"<leader>ck"` | Keymap to trigger type checking |

## Usage

TypeLens provides the following ways to check your TypeScript types:

1. Using the command:
   ```vim
   :TypeLens
   ```

2. Using the default keymap (unless changed):
   ```
   <leader>ck
   ```

## Error Display

Errors can be displayed in two formats:

1. **Trouble** (default): A beautiful error display with syntax highlighting and structured navigation
2. **Quickfix**: Traditional Vim quickfix window

## API

For those wanting to integrate TypeLens into their workflow programmatically:

```lua
-- Run type checking
require("typelens").check_types()

-- Access configuration
require("typelens.config").values
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Acknowledgments

- [Trouble](https://github.com/folke/trouble.nvim) for the excellent error display interface
- Neovim community for inspiration and support
