float radius = 100.0;
float time = 0;
float offsetX;
float offsetY;
void setup()
{
  size(900,600);
  offsetX = width/2.0;
  offsetY = height/2.0;
  background(0);
  frameRate(60);
}

float tangent(float angle, float x, float r)
{
  float tanx = tan(angle);
  return r*cos(angle)*(tanx + 1/tanx ) -x/tanx;
}

void draw ()
{
  background(0);
  float t =  abs(sin(time + 0.5*PI));
  int n = floor(500.0*t);
  radius = t*2000.0;
  for(int i = 0; i < n ; i++ )
  {
    float per = float(i)/n;
    
    float angle = 2*PI*per;
    
    stroke(255);
    strokeWeight(2);
    
    line(0, tangent(angle, -offsetX,radius) + offsetY, offsetX + offsetX, tangent(angle, offsetX,radius) + offsetY);
    
  }
  time += 0.01;
  
}