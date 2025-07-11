local UTIL = {}


function UTIL.round(val, prec)
  local e = 10 ^ (prec or 0)
  return math.floor(val * e + 0.5) / e
end


function UTIL.random(min, max, prec, weight)
  min, max, prec, weight = min or 0, max or 1, prec or 0, weight or 1
  local n = 0

  for i = 0, weight - 1 do
    n = n + math.random() / weight
  end

  return UTIL.round(min + n * (max - min), prec)
end


function UTIL.randomRange(mag, prec, weight)
  return UTIL.random(-mag, mag, prec, weight)
end


function UTIL.sendNews(id, ...)
  local message = string.format(game.translate_string(id), ...)
  news_manager.send_tip(db.actor, message)
end


function UTIL.timePlus(ms)
  return time_global() + (ms or 0)
end


function UTIL.gtimePlus(ms)
  return game.time() + (ms or 0)
end


function UTIL.timeExpired(time)
  return time and time <= time_global() or false
end


function UTIL.gtimeExpired(time)
  return time and time <= game.time() or false
end


return UTIL
