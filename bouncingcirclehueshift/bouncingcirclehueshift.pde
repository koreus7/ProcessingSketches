PVector pos;
PVector vel;

void setup(){
  colorMode(HSB,100);
  size(500, 500);
  background(0);
  pos = new PVector(random(0,width), random(0,height));
  //float unifVel = 0.01;
  //vel = new PVector(unifVel, -unifVel);
  //vel = new PVector(0.01, 0.02);
  //vel = new PVector(0.01, 0.04);
  //vel = new PVector(0.005, 0.04);
  noiseDetail(3,1.0);
  vel = new PVector(PI*0.005, TAU*0.005);
  frameRate(240);
}

public PVector futurePos() {
  float futureX = pos.x + vel.x*200.0;
  float futureY = pos.y + vel.y*200.0;
  return new PVector(futureX, futureY);
}

void draw() {
  float elapsed = millis();
  noStroke();
  int hue = floor(abs(sin(elapsed/100000.0))*100.0);
  fill(color(hue,50,100));
  ellipse(pos.x,pos.y,10,10);
  fill(color(hue,50,80));
  ellipse(width -pos.x,pos.y,10,10);
  
  
  if(futurePos().x < 0 || futurePos().x > width)
  {
    if(futurePos().x < 0)
    {
      pos.x = 0;
    }
    else
    {
      pos.x = width;
    }
    vel.x = -vel.x;
  }
  if(futurePos().y < 0 || futurePos().y > height)
  {
    if(futurePos().y < 0)
    {
      pos.y = 0;
    }
    else
    {
      pos.y = height;
    }
    vel.y = -vel.y;
  }
  
  pos = futurePos();
}