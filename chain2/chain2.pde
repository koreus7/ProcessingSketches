ArrayList<Node> nodes;
int nodeAmount = 100;
float maxLifetime = 80.0;
float lastTime = 0.0;
int nodeQuota = nodeAmount*8;
float count = 0;
float mix = 0.1;
int sign = 1;

void setup()
{
  size(940, 540);
  frameRate(30);
  nodes = new ArrayList<Node>();

}

ArrayList<Node> RemoveDead( ArrayList<Node> nodes )
{
  ArrayList<Node> result = new ArrayList<Node>();
  
  for(Node n : nodes)
  {
    if(!n.dead)
    {
      result.add(n);
    }
  }
  
  return result;
  
}

float f(float x)
{
  x = x*PI*8.0;
  //return (sin(x)*0.4 + sin(x/4.0))/4.0;
  return cos(x + PI/2.0);
}

float g(float x)
{
  x = x*PI*8.0; 
  return sin(x);
}


void draw()
{
  background(0);
  float deltaTime = millis() - lastTime;
  count += 0.0009;
  

  
  if(mix >= 1)
  {
    mix = 1;
    sign = -1;
  }
  else if(mix <= 0)
  {
    mix = 0;
    sign = 1;
  }
  
  mix += sign*0.01;
  
  if(nodeQuota >= nodeAmount)
  {
    for(int i = 0; i < nodeAmount; i++)
    {
      float per = float(i)/nodeAmount;
      float x = per*width;
      
      float source = f(per + count)*mix + g(per + count)*(1 - mix);
      
      float y = source*height*0.4 + height*0.5;
      nodes.add( new Node(x,y) );
     
    }
    
    nodeQuota -= nodeAmount;
  }
  
  for(Node n : nodes)
  {
    n.lifetime += deltaTime;
    if(n.lifetime > maxLifetime)
    {
      n.dead = true;
      nodeQuota += 1;
    }
    noFill();
    stroke(255);
    //float s = abs(sin(millis()/1000.0))*5 + 5;
    float s = (mix)*100.0 + 5.0;
    ellipse(n.x, n.y,s,s);
  }
  
  nodes = RemoveDead(nodes);
  
  lastTime = millis();
}

class Node
{
  float x;
  float y;
  float lifetime = 0.0;
  boolean dead = false;
  
  Node( float x, float y )
  {
    this.x = x;
    this.y = y;
  }
}