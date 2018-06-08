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
    }
}