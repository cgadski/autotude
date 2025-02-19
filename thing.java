package botclient;

import botclient.config.BotClientConfig;
import botclient.config.BotClientMode;
import em.altitude.game.AltitudeGame;
import em.altitude.game.IBotController;
import em.altitude.game.IProtobufListener;
import em.altitude.game.bot.NavigatingIntelligence;
import em.altitude.game.model.Team;
import em.altitude.game.options.AltitudeOptions;
import em.altitude.game.protos.Update;
import em.altitude.game.server.config.BotConfig;
import em.altitude.game.server.config.SpectateMode;
import em.altitude.game.util.AltitudeDirectoryManager;
import em.common.compatability.OsHelper;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.invoke.MethodHandles;
import java.time.Instant;
import java.util.UUID;
import java.util.zip.GZIPOutputStream;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import vapor.client.LoginRequestListener;
import vapor.client.VaporClient;
import vapor.client.game.GameServer;
import vapor.client.serverlist.ServerListClientListener;
import vapor.protocol.auth.IpBlocked;
import vapor.protocol.auth.LoginRequest;
import vapor.protocol.auth.LoginResponse;
import vapor.protocol.serverlist.ServerListResponse;

enum ClientState {
    START,
    WAIT_FOR_VAPOR,
    WAIT_FOR_LOGIN,
    LOGGED_IN,
    REQUEST_LISTING,
    WAIT_FOR_LISTING,
    IN_GAME,
}

public class BotClient
    implements
        IBotController,
        IProtobufListener,
        LoginRequestListener,
        ServerListClientListener {

    Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

    AltitudeGame game;
    AltitudeDirectoryManager directoryManager;
    BotClientConfig config;

    FileOutputStream listingOut;
    GZIPOutputStream recording;

    BotClient(
        AltitudeDirectoryManager directoryManager,
        BotClientConfig config
    ) throws Exception {
        this.config = config;

        AltitudeOptions options = new AltitudeOptions();
        options.getInternalOptions().setBotClient(true);

        this.directoryManager = directoryManager;
        game = new AltitudeGame(options, directoryManager);
        game
            .getConfig()
            .setAltitudeIntelligence(
                new NavigatingIntelligence(
                    game,
                    BotConfig.BotDifficulty.EXPERT,
                    -1
                )
            );
        game
            .getOptions()
            .getGeneralOptions()
            .setSpectateMode(SpectateMode.CHASE_OBJECTIVE);
        game.getOptions().getNetworkOptions().setPort(config.port);
        game.setBotController(this);

        if (this.config.mode == BotClientMode.GET_LISTINGS) {
            listingOut = new FileOutputStream(
                new File(directoryManager.getRootDirectory(), "listings"),
                true
            );
        }

        FakeGLFrame frame = new FakeGLFrame(game);
        frame.start();
    }

    ClientState state = ClientState.START;
    int cooldown = 0;

    void enterState(ClientState state) {
        this.state = state;
        cooldown = 0;
    }

    void enterState(ClientState state, int cooldown) {
        this.state = state;
        this.cooldown = cooldown;
    }

    public void update() {
        if (cooldown > 0) {
            cooldown--;
            return;
        }

        switch (state) {
            case START:
                game.getProtobufWriter().registerListener(this);
                enterState(ClientState.WAIT_FOR_VAPOR);
                break;
            case WAIT_FOR_VAPOR:
                if (game.getVaporClient() != null) {
                    login();
                    enterState(ClientState.WAIT_FOR_LOGIN);
                }
                break;
            case WAIT_FOR_LOGIN:
                break;
            case LOGGED_IN:
                LOG.info("Logged in.");
                enterState(ClientState.REQUEST_LISTING);
                break;
            case REQUEST_LISTING:
                LOG.info("Refreshing server list.");
                game.getVaporClient().getServerListHandler().addListener(this);
                game
                    .getVaporClient()
                    .getServerListHandler()
                    .retrieveNewServerList(VaporClient.GAME_ID);
                if (config.mode == BotClientMode.GET_LISTINGS) {
                    enterState(ClientState.REQUEST_LISTING, 30 * 60);
                } else {
                    enterState(ClientState.WAIT_FOR_LISTING);
                }
                break;
            case WAIT_FOR_LISTING:
                break;
            case IN_GAME:
                break;
        }
    }

    public void shutdown() {
        if (listingOut != null) {
            try {
                listingOut.close();
            } catch (IOException ignored) {}
        }
    }

    public void beforeRespawn() {
        Team team = game.getGameMode().getAllowedTeams().get(1);
        game.getSceneManager().getPlayerScene().setSelectedTeam(team);
    }

    public boolean tryRespawn() {
        return false;
    }

    public void login() {
        LoginRequest loginRequest = new LoginRequest(
            OsHelper.OS,
            game.getDistributor(),
            game.isUpnpConfigurationSuccessful()
        );
        loginRequest.setUsername(config.accountName);
        loginRequest.setPasswordClearText(config.accountPassword);

        try {
            game.getVaporClient().login(loginRequest, this);
        } catch (IOException e) {
            throw new RuntimeException("Could not log in: " + e);
        }
    }

    public void loginResponse(LoginResponse loginResponse) {
        enterState(ClientState.LOGGED_IN);
    }

    public void onLoginProgressStatusChanged(String string) {
        LOG.info(string);
    }

    public void ipBlocked(IpBlocked ipBlocked) {}

    public void onServerList(ServerListResponse response) {
        if (response.isError()) {
            throw new RuntimeException(
                "Could not retrieve server list: " + response
            );
        }
    }

    public void onServerListGameServerUpdated(GameServer gameServer) {
        if (
            config.mode == BotClientMode.SPECTATE &&
            state == ClientState.WAIT_FOR_LISTING
        ) {
            if (gameServer.getServerName().equals(config.server)) {
                game
                    .getSceneManager()
                    .startJoinServer(gameServer, config.password);
                enterState(ClientState.IN_GAME);
                return;
            }
        }

        if (config.mode == BotClientMode.GET_LISTINGS) {
            JSONObject object = new JSONObject();
            object.put("time", Instant.now().toEpochMilli());
            object.put("ip", gameServer.getIp());
            object.put("name", gameServer.getServerName());
            object.put("map", gameServer.getMapName());
            object.put("players", gameServer.getNumberOfPlayers());
            object.put("pwRequired", gameServer.isPasswordRequired());
            object.put("minLevel", gameServer.getMinLevel());
            object.put("maxLevel", gameServer.getMaxLevel());
            object.put("version", gameServer.getVersion());
            object.put("hardcore", gameServer.isHardcore());
            object.put("ping", gameServer.getPing());
            try {
                listingOut.write(object.toString().getBytes());
                listingOut.write("\n".getBytes());
                listingOut.flush();
            } catch (IOException e) {
                throw new RuntimeException("Could not write listing: " + e);
            }
        }
    }

    public void onLoad() {
        if (!config.record) {
            return;
        }

        // open recording file
        UUID stub = UUID.randomUUID();
        String name = stub + ".pb";

        try {
            FileOutputStream file = new FileOutputStream(
                directoryManager
                    .getRecordingDirectory()
                    .toPath()
                    .resolve(name)
                    .toFile()
            );
            this.recording = new GZIPOutputStream(file);
            LOG.info("Starting new recording: {}", name);
        } catch (IOException e) {
            LOG.error("Could not open recording file: {}", e.getMessage());
            this.recording = null;
        }
    }

    public void onUnload() {
        try {
            if (this.recording != null) {
                this.recording.close();
            }
        } catch (IOException ignored) {}

        this.recording = null;
    }

    public void onUpdate(Update update) {
        try {
            update.writeDelimitedTo(recording);
            recording.flush();
        } catch (IOException e) {
            LOG.error("Could not write to replay file: {}", String.valueOf(e));
        }
    }
}
