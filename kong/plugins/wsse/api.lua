local crud = require "kong.api.crud_helpers"

return {
    ["/consumers/:username_or_id/wsse_key/"] = {
        before = function(self, dao_factory, helpers)
            crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
            self.params.consumer_id = self.consumer.id
        end,

        POST = function(self, dao_factory, helpers)
            crud.post(self.params, dao_factory.wsse_keys)
        end,

        PUT = function(self, dao_factory, helpers)
            crud.put(self.params, dao_factory.wsse_keys)
        end
    },
    ["/consumers/:username_or_id/wsse_key/:credential_username_or_id"] = {
        before = function(self, dao_factory, helpers)
            crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
            self.params.consumer_id = self.consumer.id

            local credentials, err = crud.find_by_id_or_field(
                dao_factory.wsse_keys,
                { consumer_id = self.params.consumer_id },
                ngx.unescape_uri(self.params.credential_username_or_id),
                "key"
            )

            if err then
                return helpers.yield_error(err)
            elseif next(credentials) == nil then
                return helpers.responses.send_HTTP_NOT_FOUND()
            end
            self.params.credential_username_or_id = nil

            self.wsse_key = credentials[1]
        end,

        GET = function(self, dao_factory, helpers)
            local wsse = {}
            wsse.id = self.wsse_key.id
            wsse.consumer_id = self.wsse_key.consumer_id
            wsse.key = self.wsse_key.key
            wsse.strict_timeframe_validation = self.wsse_key.strict_timeframe_validation

            return helpers.responses.send_HTTP_OK(wsse)
        end,

        DELETE = function(self, dao_factory, helpers)
            crud.delete(self.wsse_key, dao_factory.wsse_keys)
        end
    }
}