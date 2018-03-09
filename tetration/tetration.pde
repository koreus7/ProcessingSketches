// This takes about 2 minutes to compute on my MBP 2011

float tetin(float x, float xn, float n)
{
  if(n == 1)
  {
    return pow(x,xn);
  }
  
  return tetin(x, pow(x,xn), n - 1);
}

float tet(float x, float n)
{
  return tetin(x, x, n);
}

boolean eq(float x, float y, float t)
{
  return x > y - t && x < y + t;
}

void setup()
{ 
  size(1000,1000);
  background(255);
  colorMode(HSB, 1.0);
  
  float sf = 3.0/width;
  
  final int mx = 20;
  for(int i = 1; i < mx ; i++)
  {
    for(int x = 0; x < width; x++)
    {
      for(int y = 0; y < height; y++)
      {
        int xc = x - width/2;
        int yc = y - height/2;
        float xs = xc*sf;
        float ys = -yc*sf;
        
        if(eq(ys,tet(xs,i),0.01) || eq(ys,tet(-xs,i),0.01))
        {
          set(x,y,color(float(i)/mx,0.5,0.9));
        }
      }
    }
  }
}