local singletons = require "kong.singletons"
local Logger = require "logger"
local Object = require("classic")

local ConsumerDb = Object:extend()

local function load_consumer(consumer_id, anonymous)
  local result, err = singletons.dao.consumers:find { id = consumer_id }
  if not result then
    if anonymous and not err then
      err = 'anonymous consumer "' .. consumer_id .. '" not found'
    end
    return nil, err
  end
  return result
end

function ConsumerDb.find_by_id(consumer_id, anonymous)
  if consumer_id == nil then
    Logger.getInstance(ngx):logWarning({msg = "Consumer id is required."})
    error({msg = "Consumer id is required."})
  end

  local consumer_cache_key = singletons.dao.consumers:cache_key(consumer_id)
  local consumer, err = singletons.cache:get(consumer_cache_key, nil, load_consumer, consumer_id, anonymous)

  if err then
    Logger.getInstance(ngx):logError(err)
    error(err)
  end

  if consumer == nil then
    Logger.getInstance(ngx):logWarning({msg = "Consumer can not be found."})
    error({msg = "Consumer can not be found."})
  end

  return consumer
end

return ConsumerDb
