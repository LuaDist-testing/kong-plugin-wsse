return {
    {
        name = "2018-03-01-130000_init_wssekeys",
        up = [[
              CREATE TABLE IF NOT EXISTS wsse_keys(
                id uuid,
                consumer_id uuid REFERENCES consumers (id) ON DELETE CASCADE,
                key text UNIQUE,
                secret text,
                PRIMARY KEY (id)
              );
              CREATE INDEX wssekeys_key_idx ON wsse_keys(key);
              CREATE INDEX wssekeys_consumer_idx ON wsse_keys(consumer_id);
            ]],
        down = [[
              DROP TABLE wsse_keys;
            ]]
    },
    {
        name = "2018-03-09-162200_add_strict_timeframe_validation_defaults",
        up = [[
               ALTER TABLE wsse_keys ADD COLUMN strict_timeframe_validation boolean DEFAULT TRUE;
            ]],
        down = [[
              ALTER TABLE wsse_keys DROP COLUMN strict_timeframe_validation;
            ]]
    }
}