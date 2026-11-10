package bots;

import botserver.BotFlags;
import botserver.ConfigurableIntelligence;
import em.altitude.game.AltitudeGame;
import em.altitude.game.plane.Plane;

/**
 * Example user bot: either uses no controls at all or always turns left,
 * depending on the "turnLeft" flag. Edit this class (or add new ones in
 * rl/bots/) and re-run ./run.sh to try different behavior.
 */
public class ExampleBot extends ConfigurableIntelligence {
    public ExampleBot(AltitudeGame game, BotFlags flags) {
        super(game, flags);
    }

    @Override
    public void think() {
        clearControls();
        if (flags.getBool("turnLeft")) {
            setControl(Plane.Controls.LEFT, true);
        } else {
		if (flags.getBool("turnRight")) {
		    setControl(Plane.Controls.RIGHT, true);
		}
	}
    }
}
