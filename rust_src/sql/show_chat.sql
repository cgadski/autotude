SELECT
    CASE
        WHEN game_start_time != '' THEN
            strftime('%Y-%m-%d %H:%M',
                datetime(game_start_time, '+' || (in_game_tick / 30.0) || ' seconds')
            )
        ELSE
            'tick:' || printf('%08d', in_game_tick)
    END || ' >' || printf('%-20s', 
        CASE 
            WHEN current_nick = 'Unknown_4294967295' THEN 'SERVER'
            ELSE current_nick
        END
    ) || '[' || team || ']: ' || message as chat_line
FROM chat_messages
ORDER BY game_start_time, in_game_tick;
