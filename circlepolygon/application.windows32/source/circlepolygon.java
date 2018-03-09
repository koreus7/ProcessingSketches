import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class circlepolygon extends PApplet {

float radius = 100.0f;
float time = 0;
float offsetX;
float offsetY;
public void setup()
{
  
  offsetX = width/2.0f;
  offsetY = height/2.0f;
  background(0);
  frameRate(60);
}

public float tangent(float angle, float x, float r)
{
  float tanx = tan(angle);
  return r*cos(angle)*(tanx + 1/tanx ) -x/tanx;
}

public void draw ()
{
  background(0);
  float t = abs(sin(time + 0.5f*PI));
  int n = floor(500.0f*t);
  radius = t*2000.0f;
  for(int i = 0; i < n ; i++ )
  {
    float per = PApplet.parseFloat(i)/n;
    
    float angle = 2*PI*per;
    
    stroke(255);
    strokeWeight(2);
    
    line(0, tangent(angle, -offsetX,radius) + offsetY, offsetX + offsetX, tangent(angle, offsetX,radius) + offsetY);
    
  }
  time += 0.01f;
  
}
  public void settings() {  size(900,600); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "circlepolygon" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
