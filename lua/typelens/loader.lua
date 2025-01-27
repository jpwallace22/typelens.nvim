local DEFAULT_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@class LoaderOpts
---@field frames? string[] Array of spinner frame characters
---@field message? string Message to display alongside spinner

---@class Loader
---@field frames string[] Array of spinner frame characters
---@field message string Message to display alongside spinner
---@field _win integer|nil Window handle
---@field _buf integer|nil Buffer handle
---@field _timer uv.uv_timer_t|nil Timer handle
local Loader = {
	frames = DEFAULT_FRAMES,
	message = "Running...",
	_win = nil,
	_buf = nil,
	_timer = nil,
}

---Creates a new Loader instance
---@param opts? LoaderOpts
---@return Loader
function Loader:new(opts)
	opts = opts or {}

	if opts.frames and #opts.frames == 0 then
		opts.frames = DEFAULT_FRAMES
	end

	local instance = vim.tbl_deep_extend("force", {}, self, opts)
	setmetatable(instance, { __index = self })
	return instance
end

---Starts the loading animation
function Loader:start()
	---@param frame integer
	---@return string
	local text = function(frame)
		return self.frames[frame] .. " " .. self.message
	end

	self._buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, { text(1) })

	---@type integer
	local height = vim.o.lines
	---@type integer
	local bottom_offset = 1

	if vim.o.laststatus > 0 then
		bottom_offset = bottom_offset + 1
	end
	bottom_offset = bottom_offset + vim.o.cmdheight

	---@type integer
	local width = vim.fn.strdisplaywidth(text(1))

	self._win = vim.api.nvim_open_win(self._buf, false, {
		relative = "editor",
		width = width,
		height = 1,
		col = 1,
		row = height - bottom_offset,
		anchor = "SW",
		style = "minimal",
	})

	vim.wo[self._win].winblend = 0
	vim.wo[self._win].winhighlight = "Normal:None"

	---@type integer
	local current_frame = 1

	self._timer = vim.loop.new_timer()
	self._timer:start(0, 80, function()
		vim.schedule(function()
			if self._buf and vim.api.nvim_buf_is_valid(self._buf) then
				current_frame = (current_frame % #self.frames) + 1
				vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, { text(current_frame) })
			end
		end)
	end)
end

---Stops the loading animation and cleans up resources
function Loader:stop()
	if self._timer then
		self._timer:stop()
		self._timer:close()
		self._timer = nil
	end

	vim.schedule(function()
		if self._win and vim.api.nvim_win_is_valid(self._win) then
			vim.api.nvim_win_close(self._win, true)
			self._win = nil
		end
		if self._buf and vim.api.nvim_buf_is_valid(self._buf) then
			vim.api.nvim_buf_delete(self._buf, { force = true })
			self._buf = nil
		end
	end)
end

return Loader
