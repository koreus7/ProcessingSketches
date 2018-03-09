PShader blur;
PFont font;

void setup() {
  size(displayWidth, displayHeight, P2D);
  // Shaders files must be in the "data" folder to load correctly
  blur = loadShader("myshader.glsl");
  blur.set("width", (float)width);
  blur.set("height",(float)height);
  blur.set("phase", (float)0.525);
  blur.set("frequency", (float)0.66625);
  //font = loadFont("HiraKakuStd-W8-48.vlw");
  //font = loadFont("Arial-Black-48.vlw");
  font = loadFont("IowanOldStyle-Titling-48.vlw");
  textFont(font,62);
  textAlign(CENTER);
  stroke(0, 102, 153);
  rectMode(CENTER);
}

boolean sketchFullScreen() {
  return true;
}

void draw() {
  background(0);
//  
//  float phase = (float)mouseX/width;
//  blur.set("phase", phase);
//  text(String.valueOf(phase),100,100);
//  
//  
//  float frequency = (float)mouseY/height;
//  blur.set("frequency", frequency);
//  text(String.valueOf(frequency),100,130);
//  
//  
//  textFont(font,24);
//  float frequencyMod = (float)mouseX/width;
//  blur.set("frequencyMod", frequencyMod);
//  text(String.valueOf(frequencyMod),300,130);
//  
  textFont(font,62);  
  text("Dreams", width/2,height/2);
  text("08 03 17", width/2,height/2 + 100);

  blur.set("time",(float)millis()/1800.0);
  filter(blur);
}
