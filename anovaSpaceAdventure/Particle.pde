class Particle {
  PVector pos;
  PVector vel;
  float lifespan = random(150, 255);
  
  color startColor;
  color endColor;
  
  Particle(PVector startPos, color startColor, color endColor) {
    pos = startPos.copy();
    vel = PVector.random3D();
    vel.mult(random(2,8));
    
    // Fiery colors (start = yellow/orange, end = dark red/black)
    this.startColor = startColor;
    this.endColor = endColor;
  }

  void update() {
    pos.add(vel);
    vel.mult(0.95);
    lifespan -= 4;
  }

  void display() {
    pushMatrix();
    translate(width/2, height/2, 0);
    translate(pos.x, pos.y, pos.z);
    
    noStroke();
    float t = constrain(lifespan / 255.0, 0, 1);  // Normalize [0, 1]
    color c = lerpColor(endColor, startColor, t); // Interpolate as it fades
    fill(c, lifespan);                            // Also fades alpha
    
    sphereDetail(6);
    sphere(5);
    popMatrix();
  }

  boolean isDead() {
    return lifespan <= 0;
  }
}
