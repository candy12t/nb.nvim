local M = {}

-- picker オプションの値 → バックエンドのモジュール名
local backends = {
  ["snacks"] = "nb.picker.snacks",
  ["fzf-lua"] = "nb.picker.fzf_lua",
}

-- 設定されたバックエンドを解決する（未インストール・不正な値なら nil, エラーメッセージ）
function M.resolve()
  local name = require("nb.config").options.picker
  local mod = backends[name]
  if not mod then
    return nil, "unknown picker: " .. tostring(name) .. ' (use "snacks" or "fzf-lua")'
  end
  local backend = require(mod)
  if not backend.available() then
    return nil, "picker backend not installed: " .. name
  end
  return backend
end

-- 設定されたバックエンドを取得（解決できなければ通知して nil）
function M.backend()
  local backend, err = M.resolve()
  if not backend then
    vim.notify("nb: " .. err, vim.log.levels.ERROR)
  end
  return backend
end

-- アイテムを選択する
-- opts = {
--   title   = string,
--   items   = table[],
--   format  = function(item): string,
--   preview = boolean,                       -- item.file をプレビューする
--   confirm = function(item),                -- picker を閉じた後に呼ばれる
--   actions = { [lhs] = function(item) },    -- 例: ["<C-d>"]。picker を閉じた後に呼ばれる
-- }
function M.select(opts)
  local backend = M.backend()
  if backend then
    backend.select(opts)
  end
end

-- dir 以下の内容を live grep する
function M.grep(opts)
  local backend = M.backend()
  if backend then
    backend.grep(opts)
  end
end

return M
