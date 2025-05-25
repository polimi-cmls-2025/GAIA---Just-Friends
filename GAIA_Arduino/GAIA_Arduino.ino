#include <WiFiNINA.h>
#include <WiFiUdp.h>
#include <DHT.h>
#include <OSCMessage.h>

#define DHTPIN 2
#define DHTTYPE DHT22
#define RLDR_PIN A0

DHT dht(DHTPIN, DHTTYPE);
WiFiUDP Udp;

const char* ssidList[] = {"XXX"};
const char* passList[] = {"XXXXXXXXX"};
const int numNetworks = 1;

IPAddress remoteIP(192, 168, 123, 50);
unsigned int remotePort[] = {57120, 57130};

int temp = 0;
int humi = 0;
int rldr = 0;
int triggerBar = 0;
unsigned long durBar = random(5000, 15000);
int triggerNote = 0;
unsigned long durNote = random(1500, 3000);
unsigned long barStart = 0;
unsigned long noteStart = 0;
unsigned int note = random(0, 12);

void connectToWiFi() {
  for (int i = 0; i < numNetworks; i++) {
    int tries = 0;
    while (WiFi.status() != WL_CONNECTED && tries < 10) {
      WiFi.begin(ssidList[i], passList[i]);
      delay(1000);
      tries++;
    }
    if (WiFi.status() == WL_CONNECTED) return;
  }
}

void setup() {
  dht.begin();
  analogReadResolution(12);
  randomSeed(analogRead(A1));
  connectToWiFi();
  Udp.begin(8888);
  barStart = millis();
  noteStart = millis();
}

void loop() {
  unsigned long now = millis();

  // === Controllo se è ora di iniziare una nuova battuta ===
  if (now - barStart >= durBar) {
    triggerBar = 1;
    durBar = random(5000, 15000);  
    barStart = now;               
  } else {
    triggerBar = 0;
  }

  if (now - noteStart >= durNote) {
    triggerNote = 1;
    durNote = random(1500, 3000);  
    note = random(0, 12);
    noteStart = now;               
  } else {
    triggerNote = 0;
  }

  // === Lettura sensori ===
  temp = 100 * dht.readTemperature();
  humi = 100 * dht.readHumidity();
  rldr = analogRead(RLDR_PIN);

  // === Invio dati OSC ===
  // Supercollider
  sendOSC("/sensors/temp", temp, remotePort[0]);
  sendOSC("/sensors/humi", humi, remotePort[0]);
  sendOSC("/sensors/rldr", rldr, remotePort[0]);
  sendOSC("/trigger/tbar", triggerBar, remotePort[0]);
  sendOSC("/duratat/dbar", durBar, remotePort[0]);
  sendOSC("/trigger/tnot", triggerNote, remotePort[0]);
  sendOSC("/duratat/dnot", durNote, remotePort[0]);
  sendOSC("/musnote/note", note, remotePort[0]);
  
  // Processing
  sendOSC("/sensors/temp", temp, remotePort[1]);
  sendOSC("/sensors/humi", humi, remotePort[1]);
  sendOSC("/sensors/rldr", rldr, remotePort[1]);
  
  delay(200);
}

void sendOSC(const char* address, int value, unsigned int port) {
  OSCMessage msg(address);
  msg.add(value);
  Udp.beginPacket(remoteIP, port);
  msg.send(Udp);
  Udp.endPacket();
  msg.empty();
}
