Node[] nodes;
float d = 0.8;
int max = 20;

void setup()
{
  size(900,600);
  background(0);
  frameRate(60);
  float centerX = width/2.0;
  float centerY = height/2.0;

  nodes = new Node[max];
  
  for(int i = 0; i < max; i++)
  {
    float per = float(i)/max;
    float angle = per*2*PI;
    
    nodes[i] = new Node(centerX + cos(angle)*d*width, centerY + sin(angle)*d*width );
    
  }
}

void draw()
{
  background(0);
  for(int i = 0; i < nodes.length; i++)
  {
      for(int j = i; j < nodes.length; j++)
      {
        stroke(255);
        strokeWeight(abs(2*sin(millis()/5000.0)) + 10);
        line(nodes[i].x, nodes[i].y, nodes[j].x, nodes[j].y);
      }
      
      fill(255);
      rect(nodes[i].x, nodes[i].y,10,10);
      
  }
}

class Node
{
  float x = 0.0;
  float y=  0.0;
  
  Node(float x, float y)
  {
    this.x = x;
    this.y = y;
  }
}