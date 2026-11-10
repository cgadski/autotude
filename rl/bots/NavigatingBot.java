package bots;

import botserver.BotFlags;
import em.altitude.game.AltitudeGame;
import em.altitude.game.bot.NavigatingIntelligence;
import em.altitude.game.server.config.BotConfig;

/**
 * The stock game AI (em.altitude.game.bot.NavigatingIntelligence, already
 * compiled into the Altitude jar on the classpath), adapted to the bot
 * server's (AltitudeGame, BotFlags) constructor. Behavior is unmodified;
 * MEDIUM is the difficulty the game uses for its default bots.
 */
public class NavigatingBot extends NavigatingIntelligence {
    public NavigatingBot(AltitudeGame game, BotFlags flags) {
        super(game, BotConfig.BotDifficulty.MEDIUM, 0);
    }
}
