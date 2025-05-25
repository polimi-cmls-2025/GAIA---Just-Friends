class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;
  float forceScale = 1;
  int particleHue = 255;
  float bornRate = 255;
  float particleAccumulator = 0.0;
  final int MAX_PARTICLES = 10000;

  ParticleSystem() {
    this.particles = new ArrayList<Particle>();
    this.origin = new PVector(width / 2, height / 2);
  }

  void addParticle() {
    if (particles.size() < MAX_PARTICLES) {
      PVector randomPos = new PVector(random(width), random(height));
      this.particles.add(new Particle(randomPos, 10, random(0, 255)));
    }
  }

  void followEnv(float colour, float lifespan, float speed) {
    particleHue = (int)((1.0 - colour) * 255);                 // temp → colore
    bornRate = constrain(lifespan, 0, 1);              // umidità → rate
    forceScale = pow(1000, speed) - 1;                 // temp → forza
  }

  void draw() {
    Particle p;
    float small_force = 0.05;
    PVector random_force = new PVector(0, 0);

    // New particles generation (controlled by bornRate)
    particleAccumulator += map(bornRate, 0, 1, 0.02, 10.0);
    while (particleAccumulator >= 0.5) {
      this.addParticle();
      particleAccumulator -= 0.5;
    }

    // Update and particles drawing
    for (int i = particles.size() - 1; i >= 0; i--) {
      p = particles.get(i);
      random_force.x = forceScale * random(-small_force, small_force);
      random_force.y = forceScale * random(-small_force, small_force);
      p.applyForce(random_force);
      p.update();
      p.draw(particleHue);
      p.lifespan -= 1.5;
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}
