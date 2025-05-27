class Jet {
  PShape model;
  PVector center;
  PVector bboxDim = new PVector(100, 15, 80);
  PVector boxMin;
  PVector boxMax;
  int collisionSphereRadius = 100;
  int zOffset = 20;

  AudioPlayer explosionSound, fireSound;
  
  ArrayList<Projectile> projectiles = new ArrayList<Projectile>();
  
  //For explosion effect
  ArrayList<Particle> explosionParticles = new ArrayList<Particle>();
  boolean exploded = false;

  float pitch = 0;
  float yaw = 0;

  Jet(float scaleFactor, PVector centerPosition) {
    model = loadShape("3d_models/Jet_Lowpoly.obj");
    model.scale(scaleFactor);

    center = centerPosition.copy();
    boxMin = PVector.sub(center, bboxDim);
    boxMax = PVector.add(center, bboxDim);
    
    explosionSound = minim.loadFile("soundFX/317750__jalastram__sfx_explosion_01.mp3");
    fireSound = minim.loadFile("soundFX/404796__owlstorm__retro-video-game-sfx-laser.mp3");
  }

  void updateOrientation(int xRaw, int yRaw) {
    float mappedPitch = map(yRaw, 0, 1023, -PI/4, PI/4);
    pitch = lerp(pitch, mappedPitch, 0.1);

    float mappedYaw = map(xRaw, 0, 1023, -PI/4, PI/4);
    yaw = lerp(yaw, mappedYaw, 0.1);
  }

  /*Updates projectiles and/or jet explosion particles. Returns false if
  the jet has finished exploding (and therefore there is nothing
  left to update). Otherwise, returns true if that jet hasn't exloded or
  is currently exploding.*/
  Boolean updateParticles() {
    if (exploded) {
      for (Particle p : explosionParticles) {
        p.update();
      }
      // When all particles are dead, end game
      if (explosionParticles.size() > 0 && explosionParticles.get(0).isDead()) {
        exploded = false; // get jet ready for respawn
        explosionSound.rewind();
        return false;
      }
    } else{ //update projectiles
      for (int i = projectiles.size()-1; i >= 0; i--) {
        Projectile p = projectiles.get(i);
        p.update();
        p.display();
        if (p.isOffscreen()) {
          projectiles.remove(i);
        }
      }
    }
    return true;
  }

  void fire() {
    if (soundIndicator) {
      fireSound.rewind();
      fireSound.play();
    }
    projectiles.add(new Projectile(pitch, yaw));
  }
  
  void explode() {
    if (!exploded) {
      if (soundIndicator) {
        explosionSound.rewind();
        explosionSound.play();
      }
      explosionParticles.clear();
      for (int i = 0; i < 50; i++) {
        color bright = color(0,random(200,255),255);    // bright cyan(ish)
        color dark = color(0,50,100);                       // deep teal-blue
        explosionParticles.add(new Particle(new PVector(), bright, dark));
      }
    }
    exploded = true;
  }

  void display(boolean debugVis) {
    if (exploded) {
      for (Particle p : explosionParticles) {
        p.display();
      }
    } else {
      pushMatrix();
      translate(center.x, center.y, center.z);
      rotateX(PI);
      rotateX(-pitch);
      rotateY(yaw);
      shape(model);
      
      if (debugVis) {
        stroke(0, 0, 255);
        noFill();
        translate(0, 0, -zOffset);
        box(bboxDim.x*2, bboxDim.y*2, bboxDim.z*2);
      }
      popMatrix();
    }
  }

  PVector getCenter() {
    return center.copy();
  }

  PVector getBoxMin() {
    return boxMin.copy();
  }

  PVector getBoxMax() {
    return boxMax.copy();
  }

  int getZOffset() {
    return zOffset;
  }
  
  float getPitch() {
    return pitch;
  }

  float getYaw() {
    return yaw;
  }

  ArrayList<Projectile> getProjectiles() {
    return projectiles;
  }
  
  void setCenter(PVector newCenter) {
    this.center = newCenter.copy();
    boxMin = PVector.sub(center, bboxDim);
    boxMax = PVector.add(center, bboxDim);
  }

}
