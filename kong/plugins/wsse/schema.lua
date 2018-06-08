local utils = require "kong.tools.utils"

local function check_user(anonymous)
  if anonymous == nil or utils.is_valid_uuid(anonymous) then
    return true
  end

  return false, "the anonymous user must be nil or a valid uuid"
end

return {
  no_consumer = true,
  fields = {
    anonymous = {type = "string", default = nil, func = check_user},
    timeframe_validation_treshhold_in_minutes = { type = "number", default = 5 }
  }
}