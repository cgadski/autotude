UPDATE players_wide
SET handle_key = (
    SELECT vh.handle_key FROM vapor_handle vh
    WHERE vh.vapor_key = players_wide.vapor_key
);
