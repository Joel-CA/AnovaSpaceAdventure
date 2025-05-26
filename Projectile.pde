class Projectile {
  PVector pos;
  PVector vel;

  Projectile(float pitch, float yaw) {
    pos = new PVector(0, 0, 0); // Local to ship center in world space

    float speed = 10;

    // Compute velocity in world coordinates
    float vx = speed * sin(yaw);
    float vy = -speed * sin(pitch);
    float vz = -speed * cos(pitch) * cos(yaw);

    vel = new PVector(vx, vy, vz);
  }

  void update() {
    pos.add(vel);
  }

  void display() {
    pushMatrix();
    translate(width/2, height/2, 0); // Move origin to camera center
    translate(pos.x, pos.y, pos.z); // Correct placement in 3D
    fill(255, 0, 0);
    noStroke();
    sphere(5);
    popMatrix();
  }

  boolean isOffscreen() {
    return (pos.z < -1000 || pos.z > 100 || abs(pos.x) > 2000 || abs(pos.y) > 2000);
  }
}
