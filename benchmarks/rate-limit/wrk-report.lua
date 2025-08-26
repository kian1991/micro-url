
local status_count = {}

response = function(status, headers, body)
  status_count[status] = (status_count[status] or 0) + 1
end

done = function(summary, latency, requests)
  local total = summary.requests
  io.write("\n=== Status Code Summary ===\n")
  for code, count in pairs(status_count) do
    local pct = (count / total) * 100
    io.write(string.format("%3d => %d (%.2f%%)\n", code, count, pct))
  end
  io.write(string.format("Total requests: %d\n", total))
end