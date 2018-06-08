local plugin_handler = require "kong.plugins.wsse.handler"
local constants = require "kong.constants"

describe("wsse plugin", function()
  local old_ngx = _G.ngx
  local mock_config= {
    anonymous = {},
    timeframe_validation_treshhold_in_minutes = 5
  }
  local handler

  before_each(function()
    local ngx_req_headers = {}
    local stubbed_ngx = {
      req = {
        get_headers = function()
          return ngx_req_headers
        end,
        set_header = function(header_name, header_value)
          ngx_req_headers[header_name] = header_value
        end
        },
      ctx = {},
      header = {},
      log = function(...) end,
      say = function(...) end,
      exit = function(...) end
    }

    _G.ngx = stubbed_ngx
    stub(stubbed_ngx, "say")
    stub(stubbed_ngx, "exit")
    stub(stubbed_ngx, "log")

    handler = plugin_handler()
  end)

  after_each(function()
    _G.ngx = old_ngx
  end)

  describe("#access", function()

    it("set anonymous header to true when request not has wsse header", function()
      handler:access(mock_config)
      assert.are.equal(true, ngx.req.get_headers()[constants.HEADERS.ANONYMOUS])
    end)

    it("set anonymous header to nil when wsse header exists", function()
      ngx.req.set_header("X-WSSE", "some wsse header string")
      handler:access(mock_config)
      assert.are.equal(nil, ngx.req.get_headers()[constants.HEADERS.ANONYMOUS])
    end)

  end)

end)
