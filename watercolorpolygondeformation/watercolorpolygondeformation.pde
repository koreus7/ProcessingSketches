import java.util.*;


final int maxInit = 6;

class Layer
{
  private List<PVector> verts;
  private int colour;
  private PVector center;
  
  public Layer(List<PVector> verts, int colour, PVector center)
  {
    this.colour = colour;
    this.verts = verts;
    this.center = center;
  }
  
  public void render()
  {
    int col = color(
    hue(this.colour) + (random(2.0) - 1.0)*0.01,
    saturation(this.colour)  + (random(2.0) - 1.0)*0.1, 
    brightness(this.colour)  + (random(2.0) - 1.0)*0.3,
    alpha(this.colour));
    drawPolygon(this.verts, col, this.center.x,this.center.y);
  }
  
}

List<Layer> toDraw = new ArrayList<Layer>();

void setup()
{
    
  fullScreen();
  //size(900,600);
  
  frameRate(60);
  
  
  colorMode(RGB,1.0);
  background(color(243/255.0,1,226/255.0));
  noStroke();
    
  final int col0 = color(235/255.0,127/255.0,0,0.03);
  final int col1 = color(22/255.0,149/255.0,163/255.0,0.03);
  final int col2 = color(172/255.0,240/255.0, 242/255.0,0.03);
  
  colorMode(HSB, 1.0);
  toDraw.addAll(
    blob(width/4.0,height/4.0, 0.8, col0)
  );
  toDraw.addAll(
    blob(width/4.0 - 100.0,height/4.0, 0.8, col1)
  );
  toDraw.addAll(
    blob(width/4.0 + 100.0,height/4.0, 0.8, col2)
  );
  
  Collections.shuffle(toDraw);
}


List<Layer> blob(float x, float y, float size, int col)
{
  return blob(new PVector(x,y), size, col);
}

List<Layer> blob(PVector loc, float size, int col)
{
  List<PVector> Points = new ArrayList<PVector>();
  List<Layer> layers = new ArrayList<Layer>();
  
  float rad = size*0.5*width/2.0;
  
  for(int i = 0; i < maxInit; i++)
  {
    float per = i/float(maxInit);
    float angle = 2*PI*per;
    float posX = sin(angle)*rad + loc.x;
    float posY = cos(angle)*rad + loc.y;
    Points.add(new PVector(posX, posY));
  }
  
  Points = deform(Points, size*30.0);
  Points = deform(Points, size*25.0);
  Points = deform(Points, size*20.0);
  Points = deform(Points, size*10.0);
  
  for(int i = 0; i < 50; i++)
  {
    List<PVector> verts = DetailLayer(Points, size*10.0);
    layers.add(new Layer(verts, col, loc));
  }
  
  return layers;
}

List<PVector> deform(List<PVector> original, float deformationFactor)
{
  List<PVector> retVal = new ArrayList<PVector>();
  
  for(int i = 0; i < original.size() - 1; i++)
  {
      PVector a = original.get(i); 
      PVector b = original.get(i + 1);
      float noiseFac = 100.0;
      float midXdeformed = (a.x + b.x)/2.0 + (2*randomGaussian() - 1)*deformationFactor;//(noise(a.x*noiseFac,a.y*noiseFac)*0.9);
      float midYdeformed = (a.y + b.y)/2.0 + (2*randomGaussian() - 1)*deformationFactor;//(noise(a.x*noiseFac,a.y*noiseFac)*0.9);
      retVal.add(a);
      retVal.add(new PVector(midXdeformed, midYdeformed));
      retVal.add(b);
  }
  
  return retVal;
}


List<PVector> DetailLayer(List<PVector> base, float deformationFactor)
{
  List<PVector> layer = deform(base, deformationFactor);
  layer = deform(layer, deformationFactor*0.9);
  layer = deform(layer, deformationFactor*0.7);
  layer = deform(layer, deformationFactor*0.3);
  layer = deform(layer, deformationFactor*0.1);
  return layer;
}


void drawPolygon(List<PVector> verts, int col, float offsetX, float offsetY)
{
  fill(col);
  beginShape();
  for(int i = 0; i < verts.size(); i++)
  {
    vertex(verts.get(i).x + offsetX, verts.get(i).y + offsetY);
  }
  endShape();
}

void draw()
{
  if(toDraw.size() > 0)
  {
    toDraw.remove(0).render();
  }
}