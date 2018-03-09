ArrayList<Node> nodes;

float w = 940;
float h = 540;
float startSpeed = 0.5;
float max = 100.0;

void setup()
{
    size(940, 540);
    background(0);
    colorMode(HSB,1.0);
    nodes = new ArrayList<Node>();
    for(int i = 0; i < 100; i++)
    {
      nodes.add( new Node(random(0,w),random(0,h), startSpeed*random(-1.0,1.0), startSpeed*random(-1.0,1.0) ));
    }
}

void draw()
{
  for(Node n : nodes)
  {
    if(n.x + n.vx > w || n.x + n.vx < 0)
    {
      n.vx = -n.vx;
    }
    n.x +=n.vx*millis()/1000.0;
    
    if(n.y + n.vy > h || n.y + n.vy < 0)
    {
      n.vy = -n.vy;
    }
    
    n.y += n.vy*millis()/1000.0;
    print(n.vx);
    
    n.draw();
  }
  
}

class Node
{
  float x = 0.0;
  float y = 0.0;
  
  float vx = 0.0;
  float vy = 0.0;
  
  float h;
  
  Node(float x, float y, float vx, float vy)
  {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    
    h = random(0.0,1.0);
  }
  void draw()
  {
    fill(h,0.5,1.0);
    ellipse(this.x,this.y,constrain(5*millis()/1000.0,0.0, max),constrain(5*millis()/1000.0,0.0,max));
  }
  
}