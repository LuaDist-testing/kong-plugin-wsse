local constants = require "kong.constants"
local plugin_handler = require "kong.plugins.wsse.handler"
local ConsumerDb = require "kong.plugins.wsse.consumer_db"
local Wsse = require "kong.plugins.wsse.wsse_lib"

describe("wsse plugin", function()
  local old_ngx = _G.ngx
  local mock_config= {
    anonymous = 'anonym123',
    timeframe_validation_treshhold_in_minutes = 5
  }
  local handler

  local anonymous_consumer = {
    id = 'anonym123',
    custom_id = '',
    username = 'anonymous'
  }

  local test_consumer = {
    id = 'test123',
    custom_id = '',
    username = 'test'
  }

  ConsumerDb.find_by_id = function(consumer_id, anonymous)
    if consumer_id == 'anonym123' then
      return anonymous_consumer
    else
      return test_consumer
    end
  end

  local test_wsse_key = {
    id = 1,
    consumer_id = 'test123',
    key = "test",
    secret = "test",
    strict_timeframe_validation = true
  }

  Wsse.authenticate = function()
    return test_wsse_key
  end

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
      exit = function(...) end,
      var = {
        request_id = 123
      }
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

    it("set consumer specific request headers when authentication was successful", function()
      ngx.req.set_header("X-WSSE", "wsse header string")
      handler:access(mock_config)
      assert.are.equal('test123', ngx.req.get_headers()[constants.HEADERS.CONSUMER_ID])
      assert.are.equal('', ngx.req.get_headers()[constants.HEADERS.CONSUMER_CUSTOM_ID])
      assert.are.equal('test', ngx.req.get_headers()[constants.HEADERS.CONSUMER_USERNAME])
    end)

    it("set consumer specific ngx context variables when authentication was successful", function()
      ngx.req.set_header("X-WSSE", "wsse header string")
      handler:access(mock_config)
      assert.are.equal(test_consumer, ngx.ctx.authenticated_consumer)
      assert.are.equal(test_wsse_key, ngx.ctx.authenticated_credential)
    end)

    it("set anonymous consumer on ngx context and not set credentials when X-WSSE header was not found", function()
      handler:access(mock_config)
      assert.are.equal(anonymous_consumer, ngx.ctx.authenticated_consumer)
      assert.are.equal(nil, ngx.ctx.authenticated_credential)
    end)

  end)

end)
