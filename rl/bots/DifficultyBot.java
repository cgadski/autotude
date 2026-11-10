package bots;

import java.util.Arrays;
import java.util.List;

import botserver.BotFlags;
import em.altitude.game.AltitudeGame;
import em.altitude.game.bot.AltitudeIntelligence;
import em.altitude.game.bot.NavigatingIntelligence;
import em.altitude.game.experience.model.PlaneConfiguration;
import em.altitude.game.plane.Plane;
import em.altitude.game.server.config.BotConfig;

/**
 * NavigatingIntelligence whose difficulty is chosen by the bandits
 * sampler. The stock class bakes the difficulty into its constructor, and
 * the bot server creates the intelligence only once per run, so this
 * wrapper keeps an inner stock intelligence and rebuilds it whenever the
 * sampled difficulty changes (i.e. at episode boundaries), then mirrors
 * its controls onto the plane.
 */
public class DifficultyBot extends AltitudeIntelligence {
    private static final List<String> DIFFICULTIES = Arrays.asList("EASY", "MEDIUM", "HARD", "EXPERT");

    private final BotFlags flags;
    private NavigatingIntelligence inner;

    public DifficultyBot(AltitudeGame game, BotFlags flags) {
        super(game);
        this.flags = flags;
    }

    @Override
    public PlaneConfiguration getPlaneConfiguration() {
        return getGame().getConfig().getPlaneConfig();
    }

    @Override
    public void think() {
        BotConfig.BotDifficulty difficulty = BotConfig.BotDifficulty.valueOf(
                flags.getChoice("difficulty", DIFFICULTIES));
        if (inner == null || inner.getDifficulty() != difficulty) {
            inner = new NavigatingIntelligence(getGame(), difficulty, 0);
        }
        inner.update(getMyPlane());
        for (Plane.Controls control : Plane.Controls.values()) {
            setControl(control, inner.isControlPressed(control));
        }
    }
}
