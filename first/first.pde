float x = 0.0;
float y = 0.0;
float w = 800;
float h = 600;

void setup()
{ 
  size(800,600);
  background(0);
  frameRate(30);
}


void draw()
{
  fill(255,255);
  rect(x, y, w, h);
  
  if(random(0,1) > 0.5)
  {
    w*=0.9;
  }
  else
  {
    h*=0.9;
  }
  
}