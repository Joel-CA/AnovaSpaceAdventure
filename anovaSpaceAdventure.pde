import processing.serial.*;
import javax.swing.*;
import ddf.minim.*;

Serial port;
String selectedPort;
boolean serialInitialized = false;
boolean ignoreSerialInput = true;

// audio
Minim minim;
HashMap<Integer, AudioPlayer> musicLib;
AudioPlayer menuSelect, menuScroll;
int currentTrack = 1;
int nextTrack = -1;
float fadeDuration = 1000; //ms
float crossfadeStartTime = -1;
boolean isCrossfading = false;

int prevWidth, prevHeight; // for keeping track of window resizes

PFont pixelFont;

final boolean DEBUG_LOG = false;

String val;
int x, y, btn;

Jet jet;

ArrayList<Star> stars = new ArrayList<Star>();
final int numStars = 150;

ArrayList<Asteroid> asteroids = new ArrayList<Asteroid>();
final int numAstroids = 10;

int gameState;
int menuStartTime = 0;
int lastSelectionChangeTime = 0;
int warmUp = 800; // ms delay at startup before menu listens to any input
int selectionCooldown = 500; // ms delay between menu selection changes

//settings
boolean musicIndicator = true;
boolean soundIndicator = true;
boolean volumesIndicator = false;
int highScore = 0;

String prefsFile = "save.txt";

void setup() {
  
  /*Get Arduino COM port*/
  JFrame frame = new JFrame();
  frame.setAlwaysOnTop(true);
  frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
  frame.setUndecorated(true);
  frame.setVisible(true);
  
  // 1) Let the user pick a port from the list:
  String[] ports = Serial.list();
  if (ports.length == 0) {
    JOptionPane.showMessageDialog(frame,
      "No serial ports were detected.\nPlease connect your device and restart.",
      "Error",
      JOptionPane.ERROR_MESSAGE
    );
    exit();
    return;
  }

  // showInputDialog with a dropdown of all ports:
  selectedPort = (String)JOptionPane.showInputDialog(
    frame,
    "Select a serial port:",
    "Port Selection",
    JOptionPane.QUESTION_MESSAGE,
    null,
    ports,
    ports[ports.length-1] //default port (last port 'cause that's what mine was set to)
  );

  // if they pressed Cancel or closed the dialog, quit
  if (selectedPort == null) {
    frame.dispose();
    exit();
    return;
  }
  frame.dispose();
  
  /*Start Processing Application*/
  size(800, 600, P3D);
  surface.setTitle("ANOVA Space Adventures");
  surface.setResizable(true);
  surface.setLocation(100, 100);
  frameRate(30);
  noSmooth();
  
  // 3) Try to open the port they picked:
  try {
    port = new Serial(this, selectedPort, 115200);
    port.bufferUntil('\n');
    if (DEBUG_LOG) {
      println("Connected on " + selectedPort);
    }
  } 
  catch (Exception e) {
    JOptionPane.showMessageDialog(null,
      "Failed to open port ''" + selectedPort + "''.\n" +
      "Please check device connection and re-open application.",
      "Port Error",
      JOptionPane.ERROR_MESSAGE
    );
    exit();
  }
  
  pixelFont = loadFont("fonts/PressStart2P-Regular-16.vlw");
  textFont(pixelFont);
  
  minim = new Minim(this);
  musicLib = new HashMap<Integer, AudioPlayer>();
  
  /* load music */
  musicLib.put(0, minim.loadFile("music/449938__x3nus__space-syndrome.mp3"));
  musicLib.put(1, minim.loadFile("music/luckylittleraven__spacejamloop1of3.mp3"));
  musicLib.put(2, minim.loadFile("music/luckylittleraven__spacejamloop2of3.mp3"));
  musicLib.put(3, minim.loadFile("music/luckylittleraven__spacejamloop3of3.mp3"));
  musicLib.put(4, minim.loadFile("music/436196__robbostar__space-station-ambiance-with-chords.mp3"));

  /* load soundFX */
  menuSelect = minim.loadFile("soundFX/150222__pumodi__menu-select.mp3");
  menuScroll = minim.loadFile("soundFX/341024__aceofspadesproduc100__blip-2.mp3");

  jet = new Jet(20, new PVector(width/2, height/2, 0));
  prevWidth = width;
  prevHeight = height;

  for (int i = 0; i < numStars; i++) {
    stars.add(new Star());
  }

  for (int i = 0; i < numAstroids; i++) {
    asteroids.add(new Asteroid());
  }
  
  menuStartTime = millis();
  gameState = 0; // main menu
  btn = -1;
}

void draw() {
  if (width != prevWidth || height != prevHeight) {
    onWindowResize();
    prevWidth = width;
    prevHeight = height;
  }
  
  background(0);
  lights();
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 0, -1);
  pointLight(255, 255, 255, width/2, height/2, 200);

  // Draw stars (background)
  for (Star s : stars) {
    s.update();
    s.display();
  }
  
  if (gameState == 0) { // main menu
    mainMenu();
  } else if (gameState == 1) { // game start
    mainGameLoop();
  } else if (gameState == 2) { // settings
    settingsMenu();
  } else if (gameState == 3) { // credits
    credits();
  } else if (gameState == 4) { // gameOver
    gameOver();
  }
  
}

int mainMenuSelection = 0;   // 0 = PLAY, 1 = SETTINGS, 2 = QUIT
int totalMainMenuOptions = 4;

void mainMenu() {
  // play menu music
  AudioPlayer mainTheme = musicLib.get(0);
  if (musicIndicator) {
    if (!mainTheme.isPlaying()) {
      mainTheme.play();
    }
  }
  
  // Map yRaw input to selection change
  int now = millis();
  boolean menuReady = (now - menuStartTime >= warmUp); // 1-second warm-up
  
  if (now - lastSelectionChangeTime > selectionCooldown && menuReady) {
    ignoreSerialInput = false;  // allow input to start affecting the UI
    if (y < 400) {           // move up
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      mainMenuSelection = (mainMenuSelection - 1 + totalMainMenuOptions) 
                          % totalMainMenuOptions;
      lastSelectionChangeTime = now;
    } 
    else if (y > 600) {      // move down
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      mainMenuSelection = (mainMenuSelection + 1) 
                          % totalMainMenuOptions;
      lastSelectionChangeTime = now;
    }
  }

  // Handle selection (e.g. btn == 0 = select)
  if (btn == 0 && menuReady) {
    if (soundIndicator) {
      menuSelect.rewind();
      menuSelect.play();
    }
    if (mainMenuSelection == 0) {
      if (DEBUG_LOG){
        println("Play selected");
      }
      gameState = 1;
      
      /*set game music*/
      if (musicIndicator) {
        mainTheme.pause();
        currentTrack = 1;
        AudioPlayer player = musicLib.get(currentTrack);
        player.rewind();
        player.setGain(0); // full volume
        player.play(); //play track 1
      }
      
    } else if (mainMenuSelection == 1) {
      if (DEBUG_LOG){
        println("Settings selected");
      }
      menuStartTime = millis();
      gameState = 2;
    } else if (mainMenuSelection == 2) {
      if (DEBUG_LOG){
        println("Credits selected");
      }
      menuStartTime = millis();
      gameState = 3;
    } else if (mainMenuSelection == 3) {
      stopMinim();
      exit();
    }
  }

  // Render title
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("ANOVA SPACE ADVENTURE", width / 2, height / 4);

  float buttonW = 200;
  float buttonH = 60;
  float playY = height / 2;
  float settingsY = height / 2 + 50;
  float creditsY = height / 2 + 100;
  float exitY = height / 2 + 150;

  drawButton(width / 2 - buttonW / 2, playY, buttonW, buttonH, "PLAY", mainMenuSelection == 0);
  drawButton(width / 2 - buttonW / 2, settingsY, buttonW, buttonH, "SETTINGS", mainMenuSelection == 1);
  drawButton(width / 2 - buttonW / 2, creditsY, buttonW, buttonH, "CREDITS", mainMenuSelection == 2);
  drawButton(width / 2 - buttonW / 2, exitY, buttonW, buttonH, "EXIT", mainMenuSelection == 3);
}

int settingsMenuSelection = 0;
int totalSettingsMenuOptions = 4;

void settingsMenu() {
  AudioPlayer mainTheme = musicLib.get(0);
  if (musicIndicator) {
    if (!mainTheme.isPlaying()) {
      mainTheme.play();
    }
  } else {
    mainTheme.pause();
  }
  
  int now = millis();
  boolean menuReady = (now - menuStartTime >= warmUp); // 1-second warm-up
  
  if (now - lastSelectionChangeTime > selectionCooldown && menuReady) {
    if (y < 400) {           // move up
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      settingsMenuSelection = (settingsMenuSelection - 1 + totalSettingsMenuOptions) 
                          % totalSettingsMenuOptions;
      lastSelectionChangeTime = now;
    } 
    else if (y > 600) {      // move down
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      settingsMenuSelection = (settingsMenuSelection + 1) 
                          % totalSettingsMenuOptions;
      lastSelectionChangeTime = now;
    }
  }

  // Handle selection (e.g. btn == 0 = select)
  if (btn == 0 && now - lastSelectionChangeTime > selectionCooldown && menuReady) {
    if (soundIndicator) {
      menuSelect.rewind();
      menuSelect.play();
    }
    if (settingsMenuSelection == 0) {
      if (DEBUG_LOG) {
        println("Music selected");
      }
      musicIndicator = !musicIndicator;
    } else if (settingsMenuSelection == 1) {
      if (DEBUG_LOG) {
        println("SoundFX selected");
      }
      soundIndicator = !soundIndicator;
    } else if (settingsMenuSelection == 2) {
      if (DEBUG_LOG) {
        println("Bounding Volumes selected");
      }
      volumesIndicator = !volumesIndicator;
    } else if (settingsMenuSelection == 3) {
      if (DEBUG_LOG) {
        println("Back button selected");
      }
      menuStartTime = millis();
      gameState = 0;
    }
    lastSelectionChangeTime = now;
    btn = -1;
  }

  // Render title
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("SETTINGS", width / 2, height / 4);

  float buttonW = 200;
  float buttonH = 60;
  float musicY = height / 2;
  float soundY = height / 2 + 50;
  float boundingVolumesY = height / 2 + 100;
  float backY = height / 2 + 150;
  
  String music = musicIndicator ? "on" : "off";
  String sound = soundIndicator ? "on" : "off";
  String volumes = volumesIndicator ? "on" : "off";
  
  drawButton(width / 2 - buttonW / 2, musicY, buttonW, buttonH, "MUSIC: " + music, settingsMenuSelection == 0);
  drawButton(width / 2 - buttonW / 2, soundY, buttonW, buttonH, "SOUND FX: " + sound, settingsMenuSelection == 1);
  drawButton(width / 2 - buttonW / 2, boundingVolumesY, buttonW, buttonH, "BOUNDING VOLUMES: " + volumes, settingsMenuSelection == 2);
  drawButton(width / 2 - buttonW / 2, backY, buttonW, buttonH, "BACK", settingsMenuSelection == 3);
}

void mainGameLoop() {
  if (musicIndicator) {
    // check if the current track has finished
    AudioPlayer current = musicLib.get(currentTrack);
    // If current track is near end, begin crossfade
    if (!isCrossfading && current.position() > current.length() - fadeDuration) {
      startCrossfade();
    }
  
    // Handle crossfading logic
    if (isCrossfading) {
      float elapsed = millis() - crossfadeStartTime;
      float progress = constrain(elapsed / fadeDuration, 0, 1);
      //float eased = fadeCurveExponential(progress);
      
      // constant-power weights
      float ampOut = cos(progress * HALF_PI);
      float ampIn  = sin(progress   * HALF_PI);
      
      // convert to dB
      float gainOutDB = (ampOut > 0 ? 20 * log(ampOut) / log(10) : -80);
      float gainInDB  = (ampIn  > 0 ? 20 * log(ampIn)  / log(10) : -80);
  
      // Fade out current
      AudioPlayer cur = musicLib.get(currentTrack);
      //float curGain = lerp(0, -80, progress);
      cur.setGain(gainOutDB);
      
      AudioPlayer nxt = musicLib.get(nextTrack);
      nxt.setGain(gainInDB);
      
      if (progress >= 1) {
        cur.pause();
        cur.rewind();
        currentTrack = nextTrack;
        isCrossfading = false;
      }
    }
  }
  
  // Draw and update jet
  jet.updateOrientation(x, y);
  jet.display(volumesIndicator);

  if (btn == 0) {
    jet.fire();
    btn = -1;
  }

  Boolean jetDestroyed = !jet.updateParticles();
  
  if (jetDestroyed) {
    //Game End
    if (DEBUG_LOG)  {
      println("GAME OVER.");
    }
    for (int i = 1; i <= 3; i++){
      AudioPlayer p = musicLib.get(i);
      p.pause();
    }
    menuStartTime = millis();
    if (musicIndicator) {
      AudioPlayer gameOverTrack = musicLib.get(4);
      gameOverTrack.rewind();
      gameOverTrack.play();
    }
    gameState = 4; // Game Over
  }

  // Update and render asteroids
  for (int i = asteroids.size() - 1; i >= 0; i--) {
    Asteroid a = asteroids.get(i);
    a.update();
    a.display();

    PVector jetCenter = jet.getCenter();
    PVector asteroidWorldPos = PVector.add(jetCenter, a.pos);
    
    boolean colliding = sphereIntersectsBox(
      asteroidWorldPos, 
      a.collisionSphereRadius, 
      jet.getBoxMin(), 
      jet.getBoxMax()
    );

    if (colliding) {
      if (DEBUG_LOG) {
        println("Jet Hit by Asteroid!");
      }
      a.explode();
      jet.explode();
      stroke(255, 0, 0);
    } else {
      stroke(0, 255, 0);
    }

    if (volumesIndicator) {
      a.drawBoundingSphere();
      line(jetCenter.x, jetCenter.y, jetCenter.z,
           asteroidWorldPos.x, asteroidWorldPos.y, asteroidWorldPos.z);
    }

    for (Projectile p : jet.getProjectiles()) {
      if (a.checkCollision(p)) {
        a.explode();
        break;
      }
    }

    if (a.isOffscreen()) {
      a.reset();
    }
  }
}

void gameReset() {
  //reset all asteroids
  for (Asteroid a : asteroids) {
    a.reset();
  }
  if (DEBUG_LOG){
    println("Aesteroids Reset!");
  }
  //reset all projectiles
  jet.projectiles.clear();
}

int gameOverMenuSelection = 0;
int totalGameOverMenuOptions = 2;

void gameOver() {
  // Map yRaw input to selection change
  int now = millis();
  boolean menuReady = (now - menuStartTime >= warmUp); // 1-second warm-up
  
  if (now - lastSelectionChangeTime > selectionCooldown && menuReady) {
    if (y < 400) {           // move up
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      gameOverMenuSelection = (gameOverMenuSelection - 1 + totalGameOverMenuOptions) 
                          % totalGameOverMenuOptions;
      lastSelectionChangeTime = now;
    } 
    else if (y > 600) {      // move down
      if (soundIndicator) {
        menuScroll.rewind();
        menuScroll.play();
      }
      gameOverMenuSelection = (gameOverMenuSelection + 1) 
                          % totalGameOverMenuOptions;
      lastSelectionChangeTime = now;
    }
  }

  // Handle selection (e.g. btn == 0 = select)
  if (btn == 0 && menuReady) {
    if (soundIndicator) {
      menuSelect.rewind();
      menuSelect.play();
    }
    if (musicIndicator) {
      musicLib.get(4).pause();
    }
    if (gameOverMenuSelection == 0) {
      if (DEBUG_LOG){
        println("Respawn selected");
      }
      //Ready for respawn
      gameReset();
      gameState = 1;
      if (musicIndicator) {
        currentTrack = 1;
        AudioPlayer p = musicLib.get(currentTrack);
        p.rewind();
        p.setGain(0);
        p.play(); //play track 1
      }
    } else if (gameOverMenuSelection == 1) {
      if (DEBUG_LOG){
        println("Main Menu selected");
      }
      menuStartTime = millis();
      gameState = 0;
    }
  }

  // Render title
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("GAME OVER", width / 2, height / 4);

  float buttonW = 200;
  float buttonH = 60;
  float respawnY = height / 2;
  float mainMenuY = height / 2 + 100;

  drawButton(width / 2 - buttonW / 2, respawnY, buttonW, buttonH, "RESPAWN", gameOverMenuSelection == 0);
  drawButton(width / 2 - buttonW / 2, mainMenuY, buttonW, buttonH, "MAIN MENU", gameOverMenuSelection == 1);
}

void credits() {
  if (musicIndicator) {
    AudioPlayer mainTheme = musicLib.get(0);
    if (!mainTheme.isPlaying()) {
      mainTheme.play();
    }
  }
  
  int now = millis();
  boolean menuReady = (now - menuStartTime >= warmUp); // 1-second warm-up

  // Handle selection (e.g. btn == 0 = select)
  if (btn == 0 && (now - lastSelectionChangeTime > selectionCooldown) && menuReady) {
    if (soundIndicator) {
      menuSelect.rewind();
      menuSelect.play();
    }
    if (DEBUG_LOG) {
      println("Back button selected");
    }
    menuStartTime = millis();
    gameState = 0;
    btn = -1;
  }

  // Render title
  textAlign(CENTER, TOP);
  fill(255);
  
  // Base settings for body text
  textSize(16);
  float lineHeight = 19;
  float y = height / 10;

  // Helper to render lines centered
  String[] creditsLines = {
    "CREDITS",
    "",
    "ANOVA SPACE ADVENTURE",
    "Original game by Joel Castro",
    "",
    "3D MODELS",
    "Courtesy of Sketchfab",
    "8 Low Poly Asteroids by Everios96",
    "Courtesy of Turbosquid",
    "Jet low-poly by funbug3d",
    "",
    "MUSIC & SOUNDFX",
    "Courtesy of Freesound.org",
    "\"Space Jam Loop [1, 2, & 3]\",",
    "by LuckyLittleRaven",
    "\"Space Syndrome\", by X3nus",
    "\"Space Station Ambiance (With Chords)\",",
    "by RobboStar",
    "SFX_Explosion_01 by jalastram",
    "explosion_asteroid [1 & 2] by runningmind",
    "\"Menu Select\" by pumodi",
    "\"Blip 2\" by AceOfSpadesProductions",
    "\"Laser\" by Ashe Kirk @ Owlish Media",
    "",
    "© 2025 by Berkeley ANova with <3"
  };

  for (String line : creditsLines) {
    text(line, width / 2, y);
    y += lineHeight;
  }

  float buttonW = 150;
  float buttonH = 25;
  float backY = y + 0;
  
  drawButton(width / 2 - buttonW / 2, backY, buttonW, buttonH, "BACK", true);
}

void drawButton(float x, float y, float w, float h, String label, boolean selected) {
  fill(selected ? color(150, 0, 0) : color(255));
  textSize(selected ? 26 : 24);
  text(label, x + w / 2, y + h / 2);
}

boolean sphereIntersectsBox(PVector sphereCenter, float radius, PVector boxMin, PVector boxMax) {
  float sqDist = 0;

  for (int i = 0; i < 3; i++) {
    float v = sphereCenter.array()[i];
    float min = boxMin.array()[i];
    float max = boxMax.array()[i];

    if (v < min) sqDist += (min - v) * (min - v);
    else if (v > max) sqDist += (v - max) * (v - max);
  }

  return sqDist <= radius * radius;
}

void onWindowResize() {
  //recenter jet (and hit box) to new window size
  jet.setCenter(new PVector(width/2, height/2, jet.getCenter().z));
}

int malformedSerialCount = 0;
final int malformedSerialLimit = 10;
void serialEvent(Serial port) {
  int now = millis();
  boolean menuReady = (now - menuStartTime >= warmUp); // buffer

  val = port.readStringUntil('\n');
  if (val != null) {
    val = trim(val);
    String[] parts = split(val, ',');

    if (parts.length == 3) {
      try {
        x = int(parts[0]);
        y = int(parts[1]);
        btn = int(parts[2]);

        // Reset the malformed counter if we get valid input
        malformedSerialCount = 0;

        if (DEBUG_LOG) {
          println("x: " + x + ", y: " + y + ", btn: " + btn);
        }
      } catch (Exception e) {
        malformedSerialCount++;
        if (malformedSerialCount >= malformedSerialLimit && menuReady) {
          throwSerialFormatError(val);
        }
      }
    } else {
      malformedSerialCount++;
      if (malformedSerialCount >= malformedSerialLimit && menuReady) {
        throwSerialFormatError(val);
      }
    }
  }
}

void throwSerialFormatError(String badVal) {
  JOptionPane.showMessageDialog(null,
    "Malformatted Serial input received at port '" + selectedPort + "'.\n\n" +
    "Expected: 'x,y,btn' (e.g. '512,511,1'), but got: '" + badVal + "'.\n\n" +
    "Check your Arduino code or wiring.",
    "Serial Format Error",
    JOptionPane.ERROR_MESSAGE
  );
  exit();
}

void startCrossfade() {
  // Pick new track that isn't the current one
  do {
    nextTrack = (int) random(1, 4);
  } while (nextTrack == currentTrack);

  AudioPlayer next = musicLib.get(nextTrack);
  next.rewind();
  next.setGain(-80);
  next.play();

  crossfadeStartTime = millis();
  isCrossfading = true;
}

void stopMinim() {
  for (AudioPlayer p : musicLib.values()) {
      p.close();
    }
    minim.stop();
}

// Load preferences from file if it exists
void loadPreferences() {
  File file = new File(dataPath(prefsFile));
  if (file.exists()) {
    String[] lines = loadStrings(prefsFile);
    if (lines.length >= 4) {
      musicIndicator = Boolean.parseBoolean(lines[0]);
      soundIndicator = Boolean.parseBoolean(lines[1]);
      volumesIndicator = Boolean.parseBoolean(lines[2]);
      highScore = Integer.parseInt(lines[3]);
      if (DEBUG_LOG) {
        println("Preferences loaded.");
      }
    } else {
      if (DEBUG_LOG) {
        println("Preferences file is incomplete. Using default values.");
      }
      savePreferences();
    }
  } else {
    if (DEBUG_LOG){
      println("No preferences file found. Using default values.");
    }
    savePreferences();  // Create file with default values
  }
}

// Save preferences to file
void savePreferences() {
  String[] lines = {
    String.valueOf(musicIndicator),
    String.valueOf(soundIndicator),
    String.valueOf(volumesIndicator),
    String.valueOf(highScore)
  };
  saveStrings(prefsFile, lines);
  if (DEBUG_LOG){
    println("Preferences saved.");
  }
}

void restartApp() {
  try {
    String pathToJar = sketchPath("anovaSpaceAdventure.jar");
    println("Restarting application from: " + pathToJar);
    
    ProcessBuilder pb = new ProcessBuilder("java", "-jar", pathToJar);
    pb.start();
    
    stopMinim();
    exit();  // Exit current instance
  } catch (IOException e) {
    e.printStackTrace();
  }
}
