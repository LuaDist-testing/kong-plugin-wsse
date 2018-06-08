local helpers = require "spec.helpers"
local cjson = require "cjson"
local Wsse = require "kong.plugins.wsse.wsse_lib"
local TestHelper = require "spec.test_helper"

local function get_response_body(response)
  local body = assert.res_status(201, response)
  return cjson.decode(body)
end

local function setup_test_env()
  helpers.dao:truncate_tables()

  local service = get_response_body(TestHelper.setup_service())
  local route = get_response_body(TestHelper.setup_route_for_service(service.id))
  local plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, 'wsse'))
  local consumer = get_response_body(TestHelper.setup_consumer('TestUser'))

  return service, route, plugin, consumer
end

describe("Plugin: wsse (access)", function()

  local service
  local route
  local plugin
  local consumer

  before_each(function()
    service, route, plugin, consumer = setup_test_env()
  end)

  setup(function()
    helpers.start_kong({ custom_plugins = 'wsse' })
  end)

  teardown(function()
    helpers.stop_kong(nil)
  end)

  describe("Admin API", function()
    it("registered the plugin globally", function()
      local res = assert(helpers.admin_client():send {
        method = "GET",
        path = "/plugins/" .. plugin.id,
      })
      local body = assert.res_status(200, res)
      local json = cjson.decode(body)

      assert.is_table(json)
      assert.is_not.falsy(json.enabled)
    end)

    it("registered the plugin for the api", function()
      local res = assert(helpers.admin_client():send {
        method = "GET",
        path = "/plugins/" ..plugin.id,
      })
      local body = assert.res_status(200, res)
      local json = cjson.decode(body)
      assert.is_equal(api_id, json.api_id)
    end)

    it("DELETE removes wsse_key", function()

      assert(helpers.admin_client():send {
        method = "POST",
        path = "/consumers/" .. consumer.id .. "/wsse_key",
        body = {
          key = 'test1234',
          secret = 'test1234'
        },
        headers = {
          ["Content-Type"] = "application/json"
        }
      })

      local res = assert(helpers.admin_client():send {
        method = "DELETE",
        path = "/consumers/" .. consumer.id .. "/wsse_key/test1234"
      })

      assert.res_status(204, res)
    end)

    it("returns with proper wsse key without secret when wsse key exists", function ()
      assert(helpers.admin_client():send {
        method = "POST",
        path = "/consumers/" .. consumer.id .. "/wsse_key/",
        body = {
          key = 'test2',
          secret = 'test2',
          strict_timeframe_validation = false
        },
        headers = {
          ["Content-Type"] = "application/json"
        }
      })

      local res_get = assert(helpers.admin_client():send {
        method = "GET",
        path = "/consumers/" .. consumer.id .. "/wsse_key/test2",
      })

      local body = assert.res_status(200, res_get)
      local wsse_get = cjson.decode(body)
      assert.is_equal('test2', wsse_get.key)
      assert.is_nil(wsse_get.secret)
    end)

    it("reponds with status code 404 when wsse key does not exist", function ()
      local res_get = assert(helpers.admin_client():send {
        method = "GET",
        path = "/consumers/" .. consumer.id .. "/wsse_key/non_existing_key",
      })

      assert.res_status(404, res_get)
    end)
  end)

  describe("authentication", function()
    context("when no anonymous consumer was configured", function()

      it("should reject request with HTTP 401 if X-WSSE header is not present", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com"
          }
        })
  
        local body = assert.res_status(401, res)
        assert.is_equal('{"message":"WSSE authentication header is missing."}', body)
      end)
  
      it("should reject request with HTTP 401 if X-WSSE header is malformed", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = "some wsse header string"
          }
        })
  
        local body = assert.res_status(401, res)
        assert.is_equal('{"message":"The Username field is missing from WSSE authentication header."}', body)
      end)
  
      it("should proxy the request to the upstream on successful auth", function()
        local header = Wsse.generate_header("test", "test")
  
        assert(helpers.admin_client():send {
          method = "POST",
          path = "/consumers/" .. consumer.id .. "/wsse_key/",
          body = {
            key = 'test',
            secret = 'test'
          },
          headers = {
            ["Content-Type"] = "application/json"
          }
        })
  
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = header
          }
        })
  
        assert.res_status(200, res)
      end)
  
      it("should reject the request with HTTP 401 when WSSE key could not be found", function()
        assert(helpers.admin_client():send {
          method = "PUT",
          path = "/consumers/" .. consumer.id .. "/wsse_key/",
          body = {
            key = 'test001'
          },
          headers = {
            ["Content-Type"] = "application/json"
          }
        })
  
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = 'UsernameToken Username="test003", PasswordDigest="ODM3MmJiN2U2OTA2ZDhjMDlkYWExY2ZlNDYxODBjYTFmYTU0Y2I0Mg==", Nonce="4603fcf8f0fb2ea03a41ff007ea70d25", Created="2018-02-27T09:46:22Z"'
          }
        })
  
        assert.res_status(401, res)
      end)
  
      context("when timeframe validation fails", function()
        it("should proxy the request to the upstream if strict validation was disabled", function ()
          local header = Wsse.generate_header("test2", "test2", "2017-02-27T09:46:22Z")
    
          assert(helpers.admin_client():send {
            method = "POST",
            path = "/consumers/" .. consumer.id .. "/wsse_key/",
            body = {
              key = 'test2',
              secret = 'test2',
              strict_timeframe_validation = false
            },
            headers = {
              ["Content-Type"] = "application/json"
            }
          })
    
          local res = assert(helpers.proxy_client():send {
            method = "GET",
            path = "/request",
            headers = {
              ["Host"] = "test1.com",
              ["X-WSSE"] = header
            }
          })
    
          assert.res_status(200, res)
        end)

        it("should reject the request with HTTP 401 when strict validation is on", function ()
          local header = Wsse.generate_header("test2", "test2", "2017-02-27T09:46:22Z")
    
          assert(helpers.admin_client():send {
            method = "POST",
            path = "/consumers/" .. consumer.id .. "/wsse_key/",
            body = {
              key = 'test2',
              secret = 'test2'
            },
            headers = {
              ["Content-Type"] = "application/json"
            }
          })
    
          local res = assert(helpers.proxy_client():send {
            method = "GET",
            path = "/request",
            headers = {
              ["Host"] = "test1.com",
              ["X-WSSE"] = header
            }
          })
    
          assert.res_status(401, res)
        end)
      end)

    end)

    describe("With anonymous user enabled", function()
      local service, route, anonymous, plugin, consumer

      before_each(function()
        helpers.dao:truncate_tables()

        service = get_response_body(TestHelper.setup_service())
        route = get_response_body(TestHelper.setup_route_for_service(service.id))

        anonymous = get_response_body(TestHelper.setup_consumer('anonymous'))
        plugin = get_response_body(TestHelper.setup_plugin_for_service(service.id, 'wsse', {["anonymous"] = anonymous.id}))
        
        consumer = get_response_body(TestHelper.setup_consumer('TestUser'))
      end)

      it("should proxy request with anonymous user if X-WSSE header is not present", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com"
          }
        })
  
        local response = assert.res_status(200, res)
        local body = cjson.decode(response)
        assert.is_equal("anonymous", body.headers["x-consumer-username"])
      end)

      it("should proxy the request with anonymous user if X-WSSE header is malformed", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = "some wsse header string"
          }
        })
  
        local response = assert.res_status(200, res)
        local body = cjson.decode(response)
        assert.is_equal("anonymous", body.headers["x-consumer-username"])
      end)

      it("should proxy the request to the upstream on successful auth", function()
        local header = Wsse.generate_header("test", "test")
  
        assert(helpers.admin_client():send {
          method = "POST",
          path = "/consumers/" .. consumer.id .. "/wsse_key/",
          body = {
            key = 'test',
            secret = 'test'
          },
          headers = {
            ["Content-Type"] = "application/json"
          }
        })
  
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = header
          }
        })
  
        local response = assert.res_status(200, res)
        local body = cjson.decode(response)
        assert.is_equal("TestUser", body.headers["x-consumer-username"])
      end)

      it("should proxy the request with anonymous user when WSSE key could not be found", function()
        local res = assert(helpers.proxy_client():send {
          method = "GET",
          path = "/request",
          headers = {
            ["Host"] = "test1.com",
            ["X-WSSE"] = 'UsernameToken Username="non-existing", PasswordDigest="ODM3MmJiN2U2OTA2ZDhjMDlkYWExY2ZlNDYxODBjYTFmYTU0Y2I0Mg==", Nonce="4603fcf8f0fb2ea03a41ff007ea70d25", Created="2018-02-27T09:46:22Z"'
          }
        })
  
        local response = assert.res_status(200, res)
        local body = cjson.decode(response)
        assert.is_equal("anonymous", body.headers["x-consumer-username"])
      end)

      context("when timeframe is invalid", function()
        it("should proxy the request to the upstream if strict validation was disabled", function ()
          local header = Wsse.generate_header("test2", "test2", "2017-02-27T09:46:22Z")
    
          assert(helpers.admin_client():send {
            method = "POST",
            path = "/consumers/" .. consumer.id .. "/wsse_key/",
            body = {
              key = 'test2',
              secret = 'test2',
              strict_timeframe_validation = false
            },
            headers = {
              ["Content-Type"] = "application/json"
            }
          })
    
          local res = assert(helpers.proxy_client():send {
            method = "GET",
            path = "/request",
            headers = {
              ["Host"] = "test1.com",
              ["X-WSSE"] = header
            }
          })
    
          local response = assert.res_status(200, res)
          local body = cjson.decode(response)
          assert.is_equal("TestUser", body.headers["x-consumer-username"])
        end)

        it("should proxy the request with anonymous when strict validation is on", function ()
          local header = Wsse.generate_header("test2", "test2", "2017-02-27T09:46:22Z")
    
          assert(helpers.admin_client():send {
            method = "POST",
            path = "/consumers/" .. consumer.id .. "/wsse_key/",
            body = {
              key = 'test2',
              secret = 'test2'
            },
            headers = {
              ["Content-Type"] = "application/json"
            }
          })
    
          local res = assert(helpers.proxy_client():send {
            method = "GET",
            path = "/request",
            headers = {
              ["Host"] = "test1.com",
              ["X-WSSE"] = header
            }
          })
    
          local response = assert.res_status(200, res)
          local body = cjson.decode(response)
          assert.is_equal("anonymous", body.headers["x-consumer-username"])
        end)
      end)
    end)
  end)

end)
