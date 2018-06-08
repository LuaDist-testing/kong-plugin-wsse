local wsse_lib = require "kong.plugins.wsse.wsse_lib"
local KeyDb = require "kong.plugins.wsse.key_db"

describe("wsse lib", function()

    local key_db = {
        find_by_username = function(username)
            if username == nil then
                error("Username is required!")
            end

            if username == "test" then
                return "test"
            else
                error("Username could not be found!")
            end
         end
    }

    local wsse = wsse_lib:new(key_db, 5)
    local test_wsse_header = wsse_lib.generate_header('test', 'test')

    describe("#authenticate", function()

        it("raises error when WSSE header is an empty string", function()
            assert.has_error(function() wsse:authenticate("") end, "error")
        end)

        it("does not raise error when WSSE header is a valid wsse header string", function()
            assert.has_no.errors(function() wsse:authenticate(test_wsse_header) end)
        end)

        it("raises error when PasswordDigest is missing from WSSE header", function()
            partial_test_wsse_header = string.gsub(test_wsse_header, "PasswordDigest=\"[^,]+\",", "")
            assert.has_error(function() wsse:authenticate(partial_test_wsse_header) end)
        end)

        it("raises error when Username is missing from WSSE header", function()
            partial_test_wsse_header = string.gsub(test_wsse_header, "Username=\"[^,]+\",", "")
            assert.has_error(function() wsse:authenticate(partial_test_wsse_header) end)
        end)

        it("raises error when Nonce is missing from WSSE header", function()
            partial_test_wsse_header = string.gsub(test_wsse_header, "Nonce=\"[^,]+\",", "")
            assert.has_error(function() wsse:authenticate(partial_test_wsse_header) end)
        end)

        it("raises error when Created is missing from WSSE header", function()
            partial_test_wsse_header = string.gsub(test_wsse_header, "Created=\"[^,]+\"", "")
            assert.has_error(function() wsse:authenticate(partial_test_wsse_header) end)
        end)

        it("does not raise error when WSSE header parameters have random casing ", function()
            local header = string.gsub(test_wsse_header, "%w+=", {
                ["Username="] = "uSeRnAmE=",
                ["PasswordDigest="] = "passworddigest=",
                ["Nonce="] = "NONCE=",
                ["Created="] = "Created=",
            })

            assert.has_no.errors(function() wsse:authenticate(header) end)
        end)

        it("do not raise error when WSSE header parameters have extra spaces ", function()
            local header = string.gsub(test_wsse_header, "%w+=", {
                ["Username="] = "Username =",
                ["PasswordDigest="] = "PasswordDigest= ",
                ["Nonce="] = "Nonce=",
                ["Created="] = "Created = ",
            })

            assert.has_no.errors(function() wsse:authenticate(header) end)
        end)

        it("should raise error when API user could not be found", function ()
            assert.has.errors(function() wsse:authenticate('UsernameToken Username="non existing user", PasswordDigest="ODM3MmJiN2U2OTA2ZDhjMDlkYWExY2ZlNDYxODBjYTFmYTU0Y2I0Mg==", Nonce="4603fcf8f0fb2ea03a41ff007ea70d25", Created="2018-02-27T09:46:22Z"') end)
        end)

        it("should raise error when wrong secret was given", function ()
            assert.has.errors(function() wsse:authenticate('UsernameToken Username="test", PasswordDigest="almafa", Nonce="4603fcf8f0fb2ea03a41ff007ea70d25", Created="2018-02-27T09:46:22Z"') end, "Invalid credentials!")
        end)

        it("should raise error when timeframe is invalid", function ()
            assert.has.errors(function() wsse:authenticate('UsernameToken Username="test", PasswordDigest="ODM3MmJiN2U2OTA2ZDhjMDlkYWExY2ZlNDYxODBjYTFmYTU0Y2I0Mg==", Nonce="4603fcf8f0fb2ea03a41ff007ea70d25", Created="2018-02-27T09:46:22Z"') end, "timestamp is out of threshold")
        end)

    end)

    describe("#generate_header", function()

        it("raises error when no argument was given", function()
            assert.has_error(function() wsse_lib.generate_header() end, "Username and secret are required!")
        end)

        it("returns with a generated wsse header string when username, secret, created, and nonce was given", function()
            generated_wsse_header = wsse_lib.generate_header('test', 'test', '2018-03-01T09:15:38Z', '44ab5733c8d764bc2712c62f77abeeec')
            excepted_wsse_header = 'UsernameToken Username="test", PasswordDigest="NTY0MzllMzJlMzM3NTFiNzQ2ZWVkMGEzZDRjNGQwODZiM2U2ZWJlYQ==", Nonce="44ab5733c8d764bc2712c62f77abeeec", Created="2018-03-01T09:15:38Z"'
            assert.are.equal(excepted_wsse_header, generated_wsse_header)
        end)

    end)

end)
