function Linemode:btime_and_size()
  local t = math.floor(self._file.cha.mtime or 0)
  local time = (t == 0) and "-" or os.date("%Y-%m-%d %H:%M", t)

  local s = self._file:size()
  local size = s and ya.readable_size(s) or "-"

  return string.format("%8s %16s", size, time)
end
