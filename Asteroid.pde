class Asteroid {
  PVector pos = new PVector(0, 0, 0);
  float speed = 5;
  int collisionSphereRadius = 50;
  PShape model;
  
  //For explosion effect
  ArrayList<Particle> explosionParticles = new ArrayList<Particle>();
  boolean exploded = false;


  Asteroid() {
    reset();
  }
  
  void explode() {
    if (!exploded) {
      explosionParticles.clear();
      for (int i = 0; i < 50; i++) {
        color bright = color(255, random(50, 100), 0);     // bright orange/yellow
        color dark = color(50, 0, 0);                       // deep red/black
        explosionParticles.add(new Particle(pos, bright, dark));
      }
    }
    exploded = true;
  }

  
  void reset() {
    pos.x = random(-400, 400);
    pos.y = random(-300, 300);
    pos.z = -random(1000, 4000); // Start far in front
    
    // Randomly load one of the asteroid models
    int choice = int(random(1, 6)); // assumes "rock_001.obj", "rock_002.obj", etc.
    //choice = 1;
    //make sure that individual .obj rocks are centered properly for hitbox (some aren't as I found out the hard way)
    //1-4 are pretty centered, idk about all the rest, some certainly are not.
    model = loadShape("3d_models/rock_00" + choice + ".obj");
    model.scale(15); // Adjust scale to fit your scene
  }

  void update() {
    if (gameState != 1) { //if not in game loop
      reset();
    }
    if (exploded) {
      for (Particle p : explosionParticles) {
        p.update();
      }
      // When all particles are dead, reset
      if (explosionParticles.size() > 0 && explosionParticles.get(0).isDead()) {
        exploded = false;
        reset();
      }
    } else { //keep floating toward ship
      PVector forward = getForwardVector(jet.getPitch(), jet.getYaw());
      pos.sub(PVector.mult(forward, speed));
    }
  }

  void display() {
    if (exploded) {
      for (Particle p : explosionParticles) {
        p.display();
      }
    } else {
      pushMatrix();
      translate(width/2, height/2, 0); // Camera center
      translate(pos.x, pos.y, pos.z);
      rotateX(frameCount * 0.01); // Slow spin for realism
      rotateY(frameCount * 0.01);
      shape(model);
      popMatrix();
    }
  }
  
  void drawBoundingSphere() {
    pushMatrix();
    translate(width/2, height/2, 0);
    translate(pos.x, pos.y, pos.z);
  
    noFill();
    //stroke(255, 0, 0);  // Red sphere; now set by main script
    sphereDetail(12);
    sphere(collisionSphereRadius); // Match radius used in checkCollision()
  
    popMatrix();
  }
  
  boolean isOffscreen() {
    return (pos.z > 500 || abs(pos.x) > 2000 || abs(pos.y) > 2000);
  }
  
  //check if this.Astroid is within collisionSphereRadius distance from projectile p 
  boolean checkCollision(Projectile p) {
    // Simple 3D bounding sphere collision (tune threshold)
    PVector dist = PVector.sub(pos, p.pos);
    return dist.mag() < collisionSphereRadius;
  }
  
  public PVector getForwardVector(float pitch, float yaw) {
  float x = sin(yaw) * cos(pitch);
  float y = -sin(pitch);
  float z = -cos(yaw) * cos(pitch);
  return new PVector(x, y, z).normalize(); // Unit vector
  }
}
