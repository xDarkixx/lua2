-- BULDACITY TIER-3 JOB QUEUE
local computer=require("computer")
local M={queue={},history={},max=100}
function M.enqueue(job)
  if type(job)~="table" or not job.destination or not job.action then return false,"INVALID_JOB" end
  job.id=job.id or string.format("JOB-%d",math.floor(computer.uptime()*1000));job.created=job.created or computer.uptime();job.state="QUEUED"
  M.queue[#M.queue+1]=job
  if #M.queue>M.max then table.remove(M.queue,1) end
  return true,job.id
end
function M.next()
  local job=table.remove(M.queue,1)
  if job then job.state="DISPATCHING";M.history[#M.history+1]=job end
  return job
end
function M.complete(id,ok,reason)
  for i=#M.history,1,-1 do if M.history[i].id==id then M.history[i].state=ok and "DONE" or "FAILED";M.history[i].reason=reason;M.history[i].finished=computer.uptime();return true end end
  return false
end
function M.pending() return #M.queue end
function M.historyList() return M.history end
return M
