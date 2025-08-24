-------------------------------------------------------------------------------
-- COMPONENT.LUA
--
-- Base interface for an org-roam ui component.
-------------------------------------------------------------------------------

local islist = require("org-roam.core.utils.table").islist

---@alias org-roam.core.ui.ComponentFunction
---| fun():org-roam.core.ui.Line[]

---@alias org-roam.core.ui.LazyHighlightFunction
---| fun(buf:integer, ns_id:integer, ranges:{[1]:integer, [2]:integer}[])

---@alias org-roam.core.ui.Line
---| string #raw line without any highlights
---| {lazy:true, global?:boolean, text:string, hl:org-roam.core.ui.LazyHighlightFunction}
---| org-roam.core.ui.LineSegment[] #list of line segments with or without highlights

---@alias org-roam.core.ui.LineSegment
---| {type:`group`, segments:org-roam.core.ui.LineSegment[]}
---| {type:`text`, text:string}
---| {type:`hl`, text:string, group:string}
---| {type:`action`, lhs:string, rhs:function, global:boolean|nil}

---@class org-roam.core.ui.Component
---@field private __namespace integer
---@field private __render org-roam.core.ui.ComponentFunction
local M = {}
M.__index = M

---Creates a new org-roam ui component.
---@param render org-roam.core.ui.ComponentFunction
---@return org-roam.core.ui.Component
function M:new(render)
    local instance = {}
    setmetatable(instance, M)

    instance.__render = render

    return instance
end

---Renders the contents of the component, returning an object representing the
---results.
---
---If successful, `ok` is true and `lines` contains the lines rendered.
---If unsuccessful, `ok` is false and `error` contains an error message.
---@return {ok:true, lines:org-roam.core.ui.Line[]}|{ok:false, error:string}
function M:render()
    ---@type boolean, string|org-roam.core.ui.Line[]
    local ok, ret = pcall(self.__render)

    if ok then
        ---@cast ret -string
        return {
            ok = ok,
            lines = ret or {},
        }
    else
        ---@cast ret -table
        local error = vim.inspect(ret)
        return { ok = ok, error = error }
    end
end

---Produces a line segment for plain text.
---@param text string
---@return org-roam.core.ui.LineSegment
function M.text(text)
    return { type = "text", text = text }
end

---Produces a line segment for some text with a highlight.
---@param text string
---@param group string
---@return org-roam.core.ui.LineSegment
function M.hl(text, group)
    return { type = "hl", text = text, group = group }
end

---Produces a line segment for plain text.
---@param lhs string
---@param rhs function
---@param opts? {global?:boolean}
---@return org-roam.core.ui.LineSegment
function M.action(lhs, rhs, opts)
    opts = opts or {}
    return { type = "action", lhs = lhs, rhs = rhs, global = opts.global }
end

---Produces a group of line segments.
---@param ... org-roam.core.ui.LineSegment|org-roam.core.ui.LineSegment[]
---@return org-roam.core.ui.LineSegment
function M.group(...)
    ---@type org-roam.core.ui.LineSegment[]
    local segments = {}
    for _, seg in ipairs({ ... }) do
        if not islist(seg) then
            ---@cast seg org-roam.core.ui.LineSegment
            table.insert(segments, seg)
        else
            ---@cast seg org-roam.core.ui.LineSegment[]
            for _, segg in ipairs(seg) do
                table.insert(segments, segg)
            end
        end
    end
    return { type = "group", segments = segments }
end

---Produce a line that is lazy in highlighting, using the provided function.
---Ranges contain starting & ending lines and are zero-based and end-exclusive.
---
---NOTE: If more than one consecutive line is marked lazy with the same
---      function, then the function will be called once with an ending line
---      representing the full range.
---
---NOTE: If `global` is true, then all lazy ranges will be provided exactly
---      one time to this function instead of individual lazy ranges.
---@param text string #entire line of text
---@param f org-roam.core.ui.LazyHighlightFunction
---@param opts? {global?:boolean}
---@return org-roam.core.ui.Line
function M.lazy(text, f, opts)
    opts = opts or {}
    return {
        lazy = true,
        global = opts.global,
        text = text,
        hl = f,
    }
end

return M
