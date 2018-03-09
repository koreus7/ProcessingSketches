import java.util.*;
import static java.lang.System.out;
import java.util.function.Consumer;

public class LineInfo
{
  public int x;
  public int y;
  public int x1;
  public int y1;
  
  public LineInfo(int x, int y, int x1, int y1)
  {
    this.x = x;
    this.y = y;
    this.x1 = x1;
    this.y1 = y1;
  }
  public LineInfo(float x, float y, float x1, float y1)
  {
    this.x = floor(x);
    this.y = floor(y);
    this.x1 = floor(x1);
    this.y1 = floor(y1);
  }
}

public abstract class LineDrawer
{
  public abstract void drawLine(LineInfo info);
}

public class WhiteLineDrawer extends LineDrawer
{
 public void drawLine(LineInfo info)
 {
  fill(color(1,1));
  line(info.x,info.y,info.x1,info.y1);
 }
}

public class BlackLineDrawer extends LineDrawer
{
 public void drawLine(LineInfo info)
 {
  fill(color(0,1));
  line(info.x,info.y,info.x1,info.y1);
 }
}



void drawLine(LineInfo info)
{
   fill(color(0,1));
  line(info.x,info.y,info.x1,info.y1);
}


public class TreeNode 
{
  public List<TreeNode> children;
  
  public TreeNode()
  {
    children = new ArrayList<TreeNode>();
  }
}

public class Tree 
{
  private TreeNode root;
  
  public Tree(TreeNode root)
  {
    this.root = root;
  }
  
  public TreeNode GetRoot()
  {
    return this.root;
  }
  
  private void drawChildren(TreeNode node, float baseAngle, float seperationAngle, float startX, float startY, float radius, float scaleFactor, int currDepth)
  {
    if(node.children != null && node.children.size() > 0)
    {
      for(int i = 0; i < node.children.size(); i++)
      {
        float angle = baseAngle + seperationAngle*i;
        float x = startX + cos(angle)*radius;
        float y = startY - sin(angle)*radius;
        drawLine(new LineInfo(startX, startY, x, y));
        
        drawChildren(node.children.get(i), angle - (seperationAngle*degree)/2.0, seperationAngle, x, y, radius*scaleFactor, scaleFactor, currDepth + 1);
      }
    }
  }
  
  public void Draw(float baseAngle, float seperationAngle, float startX, float startY, float radius, float scaleFactor)
  {
    this.drawChildren(this.root, baseAngle, seperationAngle, startX, startY, radius, scaleFactor, 0);
  }
}


Tree tree;

final int degree = 4;
final int depth = 4;


PGraphics bottomLayer;
PGraphics topLayer;

void setup()
{
  colorMode(HSB,1.0);
  fill(color(0,0,1));
  stroke(color(0,0,0));
  frameRate(30);
  size(900,600);
  
 // topLayer = createGraphics(width, height);
 // bottomLayer = createGraphics(width, height);
  
  tree = new Tree(new TreeNode());

  
  List<TreeNode> layer = new ArrayList<TreeNode>();
  List<TreeNode> newLayer = new ArrayList<TreeNode>();
  layer.add(tree.root);
  
  for(int i = 0; i < depth; i++)
  {
    for(TreeNode node: layer)
    {
      for(int j = 0; j < degree; j++)
      {
        TreeNode newNode = new TreeNode();
        node.children.add(newNode);
        newLayer.add(newNode);
      }
    }
    
    layer = newLayer;
    newLayer = new ArrayList<TreeNode>();
  }
  

}

void whiteLine(LineInfo info)
{
  fill(color(1,1));
  line(info.x,info.y,info.x1,info.y1);
}

void blackLine(LineInfo info)
{
  fill(color(0,1));
  line(info.x,info.y,info.x1,info.y1);
}

void draw()
{
   // bottomLayer.beginDraw();
    
    fill(color(1));
    rect(0,0,width,height);
    
    float timeMod = millis()/2000.0;
    tree.Draw(0, TWO_PI*1.0/16.0 + timeMod, width/2, height/2, 100, 0.5);
    tree.Draw(PI, TWO_PI*1.0/16.0 + timeMod, width/2, height/2, 100, 0.5);
    
   // bottomLayer.endDraw();
    
  //  topLayer.beginDraw();
    
  //  tree.Draw(0, TWO_PI*1.0/16.0 + timeMod, width/2, height/2, 100, 0.5, whiteLine);
  //  tree.Draw(PI, TWO_PI*1.0/16.0 + timeMod, width/2, height/2, 100, 0.5, whiteLine);
    
   // topLayer.endDraw();
    
   // image(bottomLayer,0,0);
   // image(topLayer,0,0);
}