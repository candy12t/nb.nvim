local M = {}

function M.available()
  return pcall(require, "fzf-lua")
end

-- Neovim 形式のキー表記を fzf 形式に変換（"<C-d>" → "ctrl-d", "<M-x>" → "alt-x"）
local function to_fzf_key(lhs)
  local mod, key = lhs:match("^<([CcMmAa])%-(.+)>$")
  if not mod then
    return lhs:lower()
  end
  local prefix = mod:lower() == "c" and "ctrl-" or "alt-"
  return prefix .. key:lower()
end

-- 各行を "<index>\t<表示文字列>" にし、index だけ fzf の表示から隠して item に戻す
local function item_of(items, entry)
  local idx = entry and tonumber(entry:match("^(%d+)\t"))
  return idx and items[idx]
end

-- item.file をプレビューする previewer
local function file_previewer(items)
  local Previewer = require("fzf-lua.previewer.builtin").buffer_or_file:extend()
  function Previewer:parse_entry(entry_str)
    local item = item_of(items, entry_str)
    if not item or item.is_folder or not item.file then
      return {}
    end
    return { path = item.file }
  end
  return Previewer
end

function M.select(opts)
  local items = opts.items
  local lines = {}
  for i, item in ipairs(items) do
    -- 表示文字列に改行やタブが混ざると行の対応が崩れるので空白に置換
    lines[i] = i .. "\t" .. (opts.format(item):gsub("[\t\n]", " "))
  end

  local function wrap(fn)
    return function(selected)
      local item = item_of(items, selected and selected[1])
      if item then
        fn(item)
      end
    end
  end

  local actions = { ["enter"] = wrap(opts.confirm) }
  for lhs, fn in pairs(opts.actions or {}) do
    actions[to_fzf_key(lhs)] = wrap(fn)
  end

  require("fzf-lua").fzf_exec(lines, {
    winopts = { title = " " .. opts.title .. " " },
    fzf_opts = {
      ["--delimiter"] = "\t",
      ["--with-nth"] = "2..",
      ["--no-multi"] = true,
    },
    previewer = opts.preview and file_previewer(items) or nil,
    actions = actions,
  })
end

function M.grep(opts)
  require("fzf-lua").live_grep({ cwd = opts.dir })
end

return M
