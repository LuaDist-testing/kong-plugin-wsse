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
    }
}