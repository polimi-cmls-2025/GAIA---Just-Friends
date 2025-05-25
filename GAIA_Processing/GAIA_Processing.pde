import oscP5.*;
import netP5.*;

OscP5 oscP5;

float temp = 0.5;   // Colour
float hum = 0.5;    // Lifespan
float light = 0.5;  // Acceleration

ParticleSystem ps;
int Nparticles = 500;

void setup(){
  size(1280, 720, P2D);
  oscP5 = new OscP5(this, 57130, OscP5.UDP);

  ps = new ParticleSystem();
  for(int i = 0; i < Nparticles; i++){
    ps.addParticle();
  }
  background(0);
}

void draw(){
  blendMode(ADD);
  background(0);
  ps.followEnv(light, hum, temp);
  ps.draw();
}

// OSC reception from Arduino
void oscEvent(OscMessage msg) {
  println("MSG ARRIVED:");
  println("address: " + msg.addrPattern());
  println("typetag: " + msg.typetag());

  try {
    if (msg.checkAddrPattern("/sensors/temp") && msg.checkTypetag("i")) {
      temp = constrain(map(msg.get(0).intValue(), 2500.0, 3000.0, 0.0, 1.0), 0.0, 1.0);
    }

    if (msg.checkAddrPattern("/sensors/humi") && msg.checkTypetag("i")) {
      hum = constrain(map(msg.get(0).intValue(), 5000.0, 8000.0, 0.0, 1.0), 0.0, 1.0);
    }

    if (msg.checkAddrPattern("/sensors/rldr") && msg.checkTypetag("i")) {
      light = msg.get(0).intValue() / 4095.0;
    }
    println("New values:");
    println("temp: " + temp + ", hum: " + hum + ", light: " + light);
  } catch(Exception e) {
    println("Errore in OSC parsing: " + e.getMessage());
  }
}
