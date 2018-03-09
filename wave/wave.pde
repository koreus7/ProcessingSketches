ArrayList<Node> nodes;
float time = 0.0;

void setup()
{
    size(940, 540);
    background(0);
    colorMode(HSB,1.0);
    frameRate(30);
     nodes = new ArrayList<Node>();
    for(int i = 0; i < 30; i++)
    {
       for(int j = 0; j < 30; j++)
       {
         float x = (i/30.0)*width;
         float y = (j/30.0)*height;
         
         nodes.add( new Node(x,y));
       }
    }
}

void draw()
{
    for(Node n : nodes)
    {
      n.hue = sin(n.x + time);
      n.draw();
    }
    
    time += millis()/100000.0;
}

class Node
{
  float x = 0.0;
  float y = 0.0;
  
  float hue;
  
  Node(float x, float y)
  {
    this.x = x;
    this.y = y;
    
    hue = random(0.0,1.0);
  }
  void draw()
  {
    fill(hue,0.5,1.0);
    ellipse(this.x,this.y,30*hue,30*hue);
  }
  
}