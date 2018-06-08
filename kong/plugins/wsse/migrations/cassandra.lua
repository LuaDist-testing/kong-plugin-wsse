return {
    {
        name = "2018-03-01-130000_init_wssekeys",
        up = [[
              CREATE TABLE IF NOT EXISTS wsse_keys(
                id uuid,
                consumer_id uuid,
                key text,
                secret text,
                PRIMARY KEY (id)
              );
              CREATE INDEX IF NOT EXISTS ON wsse_keys(key);
              CREATE INDEX IF NOT EXISTS wsse_key_consumer_id ON wsse_keys(consumer_id);
            ]],
        down = [[
              DROP TABLE wsse_keys;
            ]]
    },
    {
        name = "2018-03-09-132700_add_strict_timeframe_validation_column_to_wssekeys",
        up = [[
              ALTER TABLE wsse_keys ADD strict_timeframe_validation TYPE boolean ;
            ]],
        down = [[
              ALTER TABLE wsse_keys DROP strict_timeframe_validation;
            ]]
    },
    {
        name = "2018-03-09-162200_add_strict_timeframe_validation_defaults",
        up = function(_, _, dao)
            local rows, err = dao.wsse_keys:find_all()
            if err then
                return err
            end

            for _, row in ipairs(rows) do

                row.strict_timeframe_validation = true

                local _, err = dao.wsse_keys:update(row, row)
                if err then
                    return err
                end
            end
        end,
        down = function()
        end
    }
}