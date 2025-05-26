class Star {
  float x, y, z;
  float speed = 10;

  Star() {
    reset();
  }

  void reset() {
    //NOTE: stopped stars from spawning within a 50x50 plane about 
    //the jet because they'll spawn behind it and it looks like
    //stars are closer than the jet
    
    //x = random(-width, width);
    //y = random(-height, height);
    if (random(1) < 0.5){
      x = random(-width, -50);
    } else {
      x = random(50, width);
    }
    if (random(1) < 0.5){
      y = random(-height, -50);
    } else {
      y = random(50, height);
    }
    z = random(200, 2000); // Start far in front
  }

  void update() {
    z -= speed;
    if (z < 1) {
      reset(); // Recycle star
    }
  }

  void display() {
    pushMatrix();
    translate(width/2, height/2, 0); // Camera center
    float sx = x * (800 / z);
    float sy = y * (800 / z);
    float r = map(z, 0, 2000, 5, 0); // Closer stars appear bigger
    noStroke();
    fill(255);
    ellipse(sx, sy, r, r);
    popMatrix();
  }
}
