import ddf.minim.*;
import java.util.*;

public class AudioManager {
  Minim minim;
  Map<Integer, AudioPlayer> tracks = new HashMap<>();
  int current = 0, next = -1;
  final float fadeDuration = 1000; //ms
  float crossStart;
  boolean isCross = false;

  public AudioManager(PApplet parent) {
    minim = new Minim(parent);
    // load tracks here
    tracks.put(0, minim.loadFile("music/449938__x3nus__space-syndrome.mp3"));
    tracks.put(1, minim.loadFile("music/luckylittleraven__spacejamloop1of3.mp3"));
    tracks.put(2, minim.loadFile("music/luckylittleraven__spacejamloop2of3.mp3"));
    tracks.put(3, minim.loadFile("music/luckylittleraven__spacejamloop3of3.mp3"));
    tracks.put(4, minim.loadFile("music/436196__robbostar__space-station-ambiance-with-chords.mp3"));
  }

  public void update() {
    if (isCross) crossfadeStep();
    else checkAdvance();
  }

  public void playTrack(int idx) {
    stopAll();
    current = idx;
    AudioPlayer t = tracks.get(current);
    t.rewind();
    t.setGain(0);
    t.play();
  }

  public void checkAdvance() {
    AudioPlayer t = tracks.get(current);
    if (t.position() > t.length() - fadeDur) beginCrossfade();
  }

  public void beginCrossfade() {
    do { next = (int)random(1, tracks.size()); }
    while (next == current);
    AudioPlayer n = tracks.get(next);
    n.rewind();  n.setGain(-80);  n.play();
    crossStart = millis();
    isCross = true;
  }

  public void crossfadeStep() {
    float t = (millis() - crossStart) / fadeDur;
    t = constrain(t, 0, 1);
    float o = cos(t*HALF_PI), i = sin(t*HALF_PI);
    float gO = (o>0 ? 20*log(o)/log(10) : -80),
          gI = (i>0 ? 20*log(i)/log(10) : -80);
    tracks.get(current).setGain(gO);
    tracks.get(next   ).setGain(gI);
    if (t >= 1) {
      tracks.get(current).pause();
      current = next;
      isCross = false;
    }
  }

  public void stopAll() {
    for (AudioPlayer p : tracks.values()) p.pause();
  }

  public void shutdown() {
    for (AudioPlayer p : tracks.values()) p.close();
    minim.stop();
  }
}
