local M = {}

function M.available()
  return pcall(require, "snacks")
end

-- 共通プレビュー（setup の preview オプションで差し替え可能）
local function preview(ctx)
  local item = ctx.item
  if item.is_folder or not item.file then
    return nil
  end
  local custom = require("nb.config").options.preview
  if custom then
    return custom(ctx)
  end
  return require("snacks").picker.preview.file(ctx)
end

function M.select(opts)
  local actions = {}
  local keys = {}
  for lhs, fn in pairs(opts.actions or {}) do
    local name = "nb_action_" .. lhs
    actions[name] = function(picker)
      local item = picker:current()
      picker:close()
      if item then
        fn(item)
      end
    end
    keys[lhs] = { name, mode = { "n", "i" } }
  end

  require("snacks").picker({
    title = opts.title,
    items = opts.items,
    format = function(item)
      return { { opts.format(item) } }
    end,
    preview = opts.preview and preview or nil,
    confirm = function(picker, item)
      picker:close()
      if item then
        opts.confirm(item)
      end
    end,
    actions = actions,
    win = { input = { keys = keys } },
  })
end

function M.grep(opts)
  require("snacks").picker.grep({ dirs = { opts.dir } })
end

return M
