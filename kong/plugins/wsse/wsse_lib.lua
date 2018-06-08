local base64 = require "base64"
local sha1 = require "sha1"
local uuid = require "uuid"
local TimeframeValidator = require "kong.plugins.wsse.timeframe_validator"

local Wsse = {}

local function check_required_params(wsse_params)
    if wsse_params["username"] == nil then
        error({msg = "The Username field is missing from WSSE authenticaion header."})
    end
    if wsse_params["password_digest"] == nil then
        error({msg = "The PasswordDigest field is missing from WSSE authenticaion header."})
    end
    if wsse_params["nonce"] == nil then
        error({msg = "The Nonce field is missing from WSSE authenticaion header."})
    end
    if wsse_params["created"] == nil then
        error({msg = "The Created field is missing from WSSE authenticaion header."})
    end
end

local function parse_field(header_string, field_name)
    field_name_case_insensitive = field_name:gsub("(.)", function(letter)
        return string.format("[%s%s]", letter:lower(), letter:upper())
    end)

    return string.match(header_string, '[, ]' .. field_name_case_insensitive .. '%s*=%s*"(.-)"')
end

local function parse_header(header_string)
    if (header_string == "") then
        error({msg = "WSSE authenticaion header is empty."})
    end

    local wsse_params = {
        username = parse_field(header_string, 'Username'),
        password_digest = parse_field(header_string, 'PasswordDigest'),
        nonce = parse_field(header_string, 'Nonce'),
        created = parse_field(header_string, 'Created')
    }

    return wsse_params
end

local function generate_password_digest(nonce, created, secret)
    return base64.encode(sha1(nonce .. created .. secret))
end

local function validate_credentials(wsse_params, secret)
    local nonce = wsse_params['nonce']
    local created = wsse_params['created']
    local digest = generate_password_digest(nonce, created, secret)

    if (digest ~= wsse_params['password_digest']) then
        error({msg = "Credentials are invalid."})
    end
end

function Wsse:new(key_db, timeframe_validation_treshhold_in_minutes)
    self.__index = self
    local self = setmetatable({}, self)
    local timeframe_validation_treshhold_in_seconds = timeframe_validation_treshhold_in_minutes * 60 or 300

    self.key_db = key_db
    self.timeframe_validator = TimeframeValidator(timeframe_validation_treshhold_in_seconds)

    return self
end

function Wsse:authenticate(header_string)
    local secret
    local strict_timeframe_validation
    local wsse_params = parse_header(header_string)

    check_required_params(wsse_params)
    local status, err = pcall(function()
        local wsse_key = self.key_db.find_by_username(wsse_params['username'])
        strict_timeframe_validation = wsse_key['strict_timeframe_validation']
        secret = wsse_key['secret']
    end)
    if not status then
        error({msg = "Credentials are invalid."})
    end
    validate_credentials(wsse_params, secret)
    self.timeframe_validator:validate(wsse_params.created, strict_timeframe_validation)
end

function Wsse.generate_header(username, secret, created, nonce)
    if username == nil or secret == nil then
        error({msg = "Username and secret are required."})
    end

    created = created or os.date("!%Y-%m-%dT%TZ")
    nonce = nonce or uuid()
    local digest = generate_password_digest(nonce,created, secret)

    return string.format('UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s"', username, digest, nonce, created)
end

return Wsse