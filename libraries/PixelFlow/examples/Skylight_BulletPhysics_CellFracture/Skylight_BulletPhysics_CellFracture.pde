/**
 * 
 * PixelFlow | Copyright (C) 2017 Thomas Diewald (www.thomasdiewald.com)
 * 
 * src  - www.github.com/diwi/PixelFlow
 * 
 * A Processing/Java library for high performance GPU-Computing.
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;


import javax.vecmath.Matrix4f;
import javax.vecmath.Vector3f;

import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.ObjectArrayList;
import com.jogamp.opengl.GL2;

import peasy.*;
import bRigid.*;

import wblut.geom.WB_AABB;
import wblut.geom.WB_Coord;
import wblut.geom.WB_Mesh;
import wblut.geom.WB_Point;
import wblut.geom.WB_Vector;
import wblut.geom.WB_Voronoi;
import wblut.geom.WB_VoronoiCell3D;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.antialiasing.SMAA.SMAA;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTextureUtils;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DepthOfField;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;
import com.thomasdiewald.pixelflow.java.render.skylight.DwSceneDisplay;
import com.thomasdiewald.pixelflow.java.render.skylight.DwScreenSpaceGeometryBuffer;
import com.thomasdiewald.pixelflow.java.render.skylight.DwSkyLight;
import com.thomasdiewald.pixelflow.java.utils.DwBoundingSphere;
import com.thomasdiewald.pixelflow.java.utils.DwFrameCapture;

import processing.core.PApplet;
import processing.core.PFont;
import processing.core.PMatrix3D;
import processing.core.PShape;
import processing.opengl.PGL;
import processing.opengl.PGraphics3D;



  
  //
  // author: Thomas Diewald
  //
  //
  // This Example shows how to combine the PixelFlow Skylight-Renderer and 
  // Bullet-Physics. Rigid Bodies are created from a Voronoi-Tesselation.
  //
  // Features:
  //
  // - CellFracture from Voronoi-Tesselation - HE_Mesh
  // - Rigid Body Simulation - bRigid, Bullet Physics
  // - Skylight Renderer, Sun + AO
  // - DoF
  // - Bloom
  // - SMAA
  // - shooting
  // - ...
  //
  // required Libraries to run this example (PDE contribution manager):
  //
  // - PeasyCam
  //   library for camera control, by Jonathan Feinberg
  //   http://mrfeinberg.com/peasycam/
  //
  // - bRigid (jBullet-Physics for Processing),
  //   library for rigid body simulation, by Daniel Koehler
  //   http://www.lab-eds.org/bRigid
  //
  // - HE_Mesh
  //   library for creating and manipulating polygonal meshes, by Frederik Vanhoutte
  //   https://github.com/wblut/HE_Mesh (manual installation)
  //
  // - PixelFlow
  //   library for skylight, post-fx, lots of GLSL, etc..., by Thomas Diewald
  //   https://github.com/diwi/PixelFlow
  //
  //


  
  int viewport_w = 1280;
  int viewport_h = 720;
  int viewport_x = 230;
  int viewport_y = 0;

  // Camera
  PeasyCam cam;
  
  // Bullet Physics
  BPhysics physics;
  
  // Bullet bodies, group-shape
  PShape group_bulletbodies;
  
  // PixelFlow Context
  DwPixelFlow context;
  
  // PixelFlow Filter, for post fx
  DwFilter filter;
  
  // some render-targets
  PGraphics3D pg_render;
  PGraphics3D pg_aa;
  
  // SkyLight Renderer
  DwSkyLight skylight;
  PMatrix3D mat_scene_view;
  PMatrix3D mat_scene_bounds;
  
  // AntiAliasing - SMAA
  SMAA smaa;

  // Depth of Field - DoF
  DepthOfField dof;
  DwScreenSpaceGeometryBuffer geombuffer;
  PGraphics3D pg_tmp;
  
  PFont font12;
  
  
  DwFrameCapture capture;
  
  // switches
  public boolean UPDATE_PHYSICS    = true;
  public boolean APPLY_DOF         = true;
  public boolean APPLY_BLOOM       = true;
  public boolean DISPLAY_WIREFRAME = false;
  
  public void settings() {
    size(viewport_w, viewport_h, P3D);
    smooth(0);
  }

  public void setup() {
    
    surface.setLocation(viewport_x, viewport_y);
    
    float SCENE_SCALE = 1000;
    
    // for screenshot
    capture = new DwFrameCapture(this, "examples/");
    
    font12 = createFont("../data/SourceCodePro-Regular.ttf", 12);

    cam = new PeasyCam(this, 0, 0, 0, SCENE_SCALE);
    perspective(60 * DEG_TO_RAD, width/(float)height, 2, SCENE_SCALE * 250);

    group_bulletbodies = createShape(GROUP);
    
    physics = new BPhysics(); // no bounding box
    physics.world.setGravity(new Vector3f(0, 0, -100));
   
    pg_render = (PGraphics3D) createGraphics(width, height, P3D);
    pg_render.smooth(0);
    pg_render.beginDraw();
    pg_render.endDraw();
    
    
    // compute scene bounding-sphere
    DwBoundingSphere scene_bs = new DwBoundingSphere();
    scene_bs.set(0, 0, 200, 450);
    PMatrix3D mat_bs = scene_bs.getUnitSphereMatrix();

    // matrix, to place (centering, scaling) the scene in the viewport
    mat_scene_view = new PMatrix3D();
    mat_scene_view.scale(SCENE_SCALE);
    mat_scene_view.apply(mat_bs);

    // matrix, to place the scene in the skylight renderer
    mat_scene_bounds = mat_scene_view.get();
    mat_scene_bounds.invert();
    mat_scene_bounds.preApply(mat_bs);

    // callback for rendering the scene
    DwSceneDisplay scene_display = new DwSceneDisplay(){
      @Override
      public void display(PGraphics3D canvas) {
        displayScene(canvas);  
      }
    };
    
    // library context
    context = new DwPixelFlow(this);
    context.print();
    context.printGL();
    
    // postprocessing filters
    filter = DwFilter.get(context);
    
    // init skylight renderer
    skylight = new DwSkyLight(context, scene_display, mat_scene_bounds);
    
    // parameters for sky-light
    skylight.sky.param.iterations     = 50;
    skylight.sky.param.solar_azimuth  = 0;
    skylight.sky.param.solar_zenith   = 0;
    skylight.sky.param.sample_focus   = 1; // full sphere sampling
    skylight.sky.param.intensity      = 1.0f;
    skylight.sky.param.rgb            = new float[]{1,1,1};
    skylight.sky.param.shadowmap_size = 512; // quality vs. performance
    
    // parameters for sun-light
    skylight.sun.param.iterations     = 50;
    skylight.sun.param.solar_azimuth  = 35;
    skylight.sun.param.solar_zenith   = 65;
    skylight.sun.param.sample_focus   = 0.1f;
    skylight.sun.param.intensity      = 1.0f;
    skylight.sun.param.rgb            = new float[]{1,1,1};
    skylight.sun.param.shadowmap_size = 512;
    
    // postprocessing AA
    smaa = new SMAA(context);
    pg_aa = (PGraphics3D) createGraphics(width, height, P3D);
    pg_aa.smooth(0);
    pg_aa.textureSampling(5);
    
    
    dof = new DepthOfField(context);
    geombuffer = new DwScreenSpaceGeometryBuffer(context, scene_display);
    
    pg_tmp = (PGraphics3D) createGraphics(width, height, P3D);
    pg_tmp.smooth(0);
    
    DwGLTextureUtils.changeTextureFormat(pg_tmp, GL2.GL_RGBA16F, GL2.GL_RGBA, GL2.GL_FLOAT);
    pg_tmp.beginDraw();
    pg_tmp.endDraw();
    
    // fresh start
    reset();
    
    createFractureShape();
    
    frameRate(60);
  }
  


  public void draw() {
    
    // handle bullet physics update, etc...
    if(UPDATE_PHYSICS){

      physics.update();
      
      removeLostBodies();
      
      for (BObject body : physics.rigidBodies) {
        updateShapes(body);
      }
    }
    
 
    // when the camera moves, the renderer restarts
    updateCamActiveStatus();
    if(CAM_ACTIVE || UPDATE_PHYSICS){
      skylight.reset();
    }

    // update renderer
    skylight.update();
    

    // apply AntiAliasing
    smaa.apply(skylight.renderer.pg_render, pg_aa);
    
    // apply bloom
    if(APPLY_BLOOM){
      filter.bloom.param.mult   = 0.15f; //map(mouseX, 0, width, 0, 1);
      filter.bloom.param.radius = 0.5f; // map(mouseY, 0, height, 0, 1);
      filter.bloom.apply(pg_aa, null, pg_aa);
    }  
    
    // apply DoF
    if(APPLY_DOF){
      int mult_blur = 5;
      
      geombuffer.update(skylight.renderer.pg_render);
      
      filter.gaussblur.apply(geombuffer.pg_geom, geombuffer.pg_geom, pg_tmp, mult_blur);

      dof.param.focus_pos = new float[]{0.5f, 0.5f};
//      dof.param.focus_pos[0] =   map(mouseX, 0, width , 0, 1);
//      dof.param.focus_pos[1] = 1-map(mouseY, 0, height, 0, 1);
      dof.param.mult_blur = mult_blur;
      dof.apply(pg_aa, pg_render, geombuffer);
      filter.copy.apply(pg_render, pg_aa);
    }
    
    // display result
    cam.beginHUD();
    {
      background(255);
      noLights();
      image(pg_aa, 0, 0);
      
      displayCross();
      
      displayHUD();
    }
    cam.endHUD();
    
    // info
    String txt_fps = String.format(getClass().getName()+ "  [fps %6.2f]  [bodies %d]", frameRate, physics.rigidBodies.size());
    surface.setTitle(txt_fps);
  }
  
  
  
  public void displayCross(){
    pushMatrix();
    float cursor_s = 10;
    float fpx = (       dof.param.focus_pos[0]) * width;
    float fpy = (1.0f - dof.param.focus_pos[1]) * height;
    blendMode(EXCLUSION);
    translate(fpx, fpy);
    strokeWeight(1);
    stroke(255,200);
    line(-cursor_s, 0, +cursor_s, 0);
    line(0, -cursor_s, 0, +cursor_s);
    blendMode(BLEND);
    popMatrix();
  }

  
  
  
  public void displayHUD(){
    
    String txt_fps            = String.format(Locale.ENGLISH, "fps: %6.2f", frameRate);
    String txt_num_bodies     = String.format(Locale.ENGLISH, "rigid bodies: %d", physics.rigidBodies.size());
    String txt_samples_sky    = String.format(Locale.ENGLISH, "sky/sun: %d/%d (samples)", skylight.sky.param.iterations,  skylight.sun.param.iterations);
 
//    String txt_model          = String.format(Locale.ENGLISH, "[1-9] model: %d", BUILDING);
    String txt_reset          = String.format(Locale.ENGLISH, "[r] reset");
    String txt_update_physics = String.format(Locale.ENGLISH, "[p] physics:   %b", UPDATE_PHYSICS);
    String txt_apply_bloom    = String.format(Locale.ENGLISH, "[q] bloom:     %b", APPLY_BLOOM);
    String txt_apply_dof      = String.format(Locale.ENGLISH, "[w] DoF:       %b", APPLY_DOF);
    String txt_wireframe      = String.format(Locale.ENGLISH, "[e] wireframe: %b", DISPLAY_WIREFRAME);
    String txt_shoot          = String.format(Locale.ENGLISH, "[ ] shoot");

    int tx, ty, sy;
    tx = 10;
    ty = 10;
    sy = 13;
    
    fill(0, 100);
    noStroke();
    stroke(0, 200);
    rectMode(CORNER);
    rect(5, 5, 200, 170);
    
    textFont(font12);
//    textMode(SCREEN);
    fill(220);
    text(txt_fps            , tx, ty+=sy);
    text(txt_num_bodies     , tx, ty+=sy);
    text(txt_samples_sky    , tx, ty+=sy);
    ty+=sy;
//    text(txt_model          , tx, ty+=sy);
    text(txt_reset          , tx, ty+=sy);
    text(txt_update_physics , tx, ty+=sy);
    text(txt_apply_bloom    , tx, ty+=sy);
    text(txt_apply_dof      , tx, ty+=sy);
    text(txt_wireframe      , tx, ty+=sy);
    text(txt_shoot          , tx, ty+=sy);

  }
  
  
  
  // reset scene
  public void reset(){
    // remove bodies
    for(int i = physics.rigidBodies.size() - 1; i >= 0; i--){
      BObject body = physics.rigidBodies.get(i);
      physics.removeBody(body);
    }
    
    // just in case, i am actually not not sure if PShape really needs this to 
    // avoid memoryleaks.
    for(int i = group_bulletbodies.getChildCount() - 1; i >= 0; i--){
      group_bulletbodies.removeChild(i);
    }

    addGround();
  }
  

  // bodies that have fallen outside of the scene can be removed
  public void removeLostBodies(){
    for(int i = physics.rigidBodies.size() - 1; i >= 0; i--){
      BObject body = physics.rigidBodies.get(i);
      Vector3f pos = body.getPosition();
      
      if(pos.z < -1000){
        int idx = group_bulletbodies.getChildIndex(body.displayShape);
        if(idx >= 0){
          group_bulletbodies.removeChild(idx);
        }
        physics.removeBody(body);
      }
    }
  }
  
  
  // toggle shading/wireframe display
  public void toggleDisplayWireFrame(){
    DISPLAY_WIREFRAME = !DISPLAY_WIREFRAME;
    for (BObject body : physics.rigidBodies) {
      PShape shp = body.displayShape;
      String name = shp.getName();
      if(name != null && name.contains("[wire]")){
        shp.setFill(!DISPLAY_WIREFRAME);
        shp.setStroke(DISPLAY_WIREFRAME);
      }
    }
    skylight.reset();
  }
  
  
  // check if camera is moving
  float[] cam_pos = new float[3];
  boolean CAM_ACTIVE = false;
  public void updateCamActiveStatus(){
    float[] cam_pos_curr = cam.getPosition();
    CAM_ACTIVE = false;
    CAM_ACTIVE |= cam_pos_curr[0] != cam_pos[0];
    CAM_ACTIVE |= cam_pos_curr[1] != cam_pos[1];
    CAM_ACTIVE |= cam_pos_curr[2] != cam_pos[2];
    cam_pos = cam_pos_curr;
  }
  
  

  public void keyReleased(){
    if(key == 'p') UPDATE_PHYSICS = !UPDATE_PHYSICS;
    if(key == 'q') APPLY_BLOOM = !APPLY_BLOOM;
    if(key == 'w') APPLY_DOF = !APPLY_DOF;
    if(key == 'e') toggleDisplayWireFrame();
    if(key == 'r') createFractureShape();
    if(key == ' ') addShootingBody();
    if(key == 's') saveScreenshot();
  }
  
  

  
  // shoot body into the scene
  int shooter_count = 0;
  PMatrix3D mat_mvp     = new PMatrix3D();
  PMatrix3D mat_mvp_inv = new PMatrix3D();
  
  public void addShootingBody(){
    

    float vel = 2000;
    float mass = 100000;
    float dimr = 40;
    

    PGraphics3D pg = (PGraphics3D) skylight.renderer.pg_render;
    mat_mvp.set(pg.modelview);
    mat_mvp.apply(mat_scene_view);
    mat_mvp_inv.set(mat_mvp);
    mat_mvp_inv.invert();
    
    float[] cam_start = {0, 0, -0, 1};
    float[] cam_aim   = {0, 0, -400, 1};
    float[] world_start = new float[4];
    float[] world_aim   = new float[4];
    mat_mvp_inv.mult(cam_start, world_start);
    mat_mvp_inv.mult(cam_aim, world_aim);
    
    Vector3f pos = new Vector3f(world_start[0], world_start[1], world_start[2]);
    Vector3f aim = new Vector3f(world_aim[0], world_aim[1], world_aim[2]);
    Vector3f dir = new Vector3f(aim);
    dir.sub(pos);
    dir.normalize();
    dir.scale(vel);

    BObject obj;
    
//    if((shooter_count % 2) == 0){
      obj = new BSphere(this, mass, 0, 0, 0, dimr*0.5f);
//    } else {
//      obj = new BBox(this, mass, dimr, dimr, dimr);
//    }
    BObject body = new BObject(this, mass, obj, pos, true);
    
    body.setPosition(pos);
    body.setVelocity(dir);
    body.setRotation(new Vector3f(random(-1, 1),random(-1, 1),random(-1, 1)), random(PI));

    body.rigidBody.setRestitution(0.9f);
    body.rigidBody.setFriction(1);
//    body.rigidBody.setHitFraction(1);
    body.rigidBody.setDamping(0.1f, 0.1f);
    
    body.displayShape.setStroke(false);
    body.displayShape.setFill(true);
    body.displayShape.setFill(color(255,200,0));
    body.displayShape.setStrokeWeight(1);
    body.displayShape.setStroke(color(0));
    if(obj instanceof BBox){
      fixBoxNormals(body.displayShape);
    }

    physics.addBody(body);
    group_bulletbodies.addChild(body.displayShape);
    
    body.displayShape.setName("[shooter_"+shooter_count+"] [wire]");
    shooter_count++;
  }
  

  // bRigid-bug: face 1 and 3, vertex order -> inverse normal
  private void fixBoxNormals(PShape box){
    PShape face;
    face = box.getChild(1);
    for(int i = 0; i < 4; i++){
      face.setNormal(i, -1, 0, 0);
    }
    face = box.getChild(3);
    for(int i = 0; i < 4; i++){
      face.setNormal(i, +1, 0, 0);
    }
  }
  
  
  
  
  public void createFractureShape(){
    long timer = System.currentTimeMillis();

    reset();
    
    float translate_z = 0;
    float pos_z = 20f;
    
    int num_voronoi_cells = 300;
    List<WB_Point> points = new ArrayList<WB_Point>(num_voronoi_cells);

    int dimx = 100;
    int dimy = 100;
    int dimz = 100;
    int off = 40;
    
    // create centroids for voronoi-cells
    for(int i = 0; i < num_voronoi_cells; i++){
      float randx = random(1); // randx *= randx;
      float randy = random(1); // randy *= randy;
      float randz = random(1); // randz *= randz;
      
      float px = (randx * 2 - 1) * (dimx-off);
      float py = (randy * 2 - 1) * (dimy-off);
      float pz = (randz * 2 - 1) * (dimz-off);
      
      points.add(new WB_Point(px, py, pz));
    }

    // create voronoi
    WB_AABB box = new WB_AABB(-dimx, -dimy, -dimz, dimx, dimy, dimz);
    List<WB_VoronoiCell3D> cells = WB_Voronoi.getVoronoi3D(points, box);
    
    // create a rigid body + PShape for each Voronoi-Cell
    for (int i = 0; i < cells.size(); i++) {
      WB_VoronoiCell3D cell = cells.get(i);
      WB_Mesh mesh = cell.getMesh();
      int num_verts = mesh.getNumberOfVertices();
      List<WB_Coord> verts = mesh.getPoints();
      
      // compute center of mass
      float[][] pnts = new float[num_verts][3];
      for(int j = 0; j < num_verts; j++){
        WB_Coord vtx = verts.get(j);
        pnts[j][0] = vtx.xf(); 
        pnts[j][1] = vtx.yf(); 
        pnts[j][2] = vtx.zf(); 
      }
  


      // this one gives better results, than the coronoi center
      DwBoundingSphere cell_bs = new DwBoundingSphere();
      cell_bs.compute(pnts, pnts.length);
      Vector3f center_of_mass = new Vector3f(cell_bs.pos);
      
//      WB_Point cell_center = mesh.getCenter();
//      Vector3f center_of_mass = new Vector3f(cell_center.xf(), cell_center.yf(), cell_center.zf());
//      WB_Point cell_generator = cell.getGenerator();
//      Vector3f center_of_mass = new Vector3f(cell_generator.xf(), cell_generator.yf(), cell_generator.zf());

      
      // create rigid body coords, center is at 0,0,0
      ObjectArrayList<Vector3f> vertices = new ObjectArrayList<Vector3f>(verts.size());
      for(int j = 0; j < num_verts; j++){
        Vector3f vtx = new Vector3f(pnts[j]);
        vtx.sub(center_of_mass);
        vertices.add(vtx);
      }
      
      // create rigid body
      int mass = 5000;
      BConvexHull body = new BConvexHull(this, mass, vertices, new Vector3f(), true);
      physics.addBody(body);
      
      // setup initial body transform-matrix
      PMatrix3D mat_p5 = new PMatrix3D();
      mat_p5.translate(center_of_mass.x, center_of_mass.y, center_of_mass.z);
      mat_p5.translate(0, 0, pos_z + dimz);
      mat_p5.translate(0, 0, translate_z);
      
      Matrix4f mat = new Matrix4f();
      mat.setRow(0, mat_p5.m00, mat_p5.m01, mat_p5.m02, mat_p5.m03);
      mat.setRow(1, mat_p5.m10, mat_p5.m11, mat_p5.m12, mat_p5.m13);
      mat.setRow(2, mat_p5.m20, mat_p5.m21, mat_p5.m22, mat_p5.m23);
      mat.setRow(3, mat_p5.m30, mat_p5.m31, mat_p5.m32, mat_p5.m33);

      Transform transform = new Transform(mat);
      
      // rigid-body properties
      body.rigidBody.setWorldTransform(transform);
//      body.rigidBody.setRestitution(.1f);
      body.rigidBody.setFriction(0.91f);
//      body.rigidBody.setDamping(0.2f, 0.2f);
      
      
//      body.displayShape.setStroke(false);
//      body.displayShape.setFill(true);
//      body.displayShape.setFill(color(255));
//      body.displayShape.setStrokeWeight(1);
//      body.displayShape.setStroke(color(0));
//      body.displayShape.setName("cvh");
//      group_bulletbodies.addChild(body.displayShape);
//      
//      // fix normals
//      {
//        PShape[] faces = body.displayShape.getChildren();
//        PVector vnorm = new  PVector();
//        for(int j = 0; j < faces.length; j++){
//          PShape face = faces[j];
//          int num_face_verts = face.getVertexCount();
//          for(int k = 0; k < num_face_verts; k++){
//            face.getNormal(k, vnorm);
//            face.setNormal(k, -vnorm.x, -vnorm.y, -vnorm.z);
//          }
//        }
//      }
      
      // create PShape
      PShape voronoi_cell = createVoronoiCellShape(cell, center_of_mass);
      
      // link everything together
      body.displayShape = voronoi_cell;
      group_bulletbodies.addChild(voronoi_cell);
    }
    
    
    timer = System.currentTimeMillis() - timer;
    System.out.println("createFractureShape "+timer+" ms");

  }

  
  public PShape createVoronoiCellShape(WB_VoronoiCell3D cell, Vector3f center_of_mass){
    
    boolean[] on_bounds = cell.boundaryArray();
    
    PShape voronoi_cell = createShape(GROUP);
    
    WB_Mesh mesh = cell.getMesh();
    List<WB_Coord> verts = mesh.getPoints();
    int[][] faces = mesh.getFacesAsInt();

    int on_boundary = 0;
    for(int j = 0; j < faces.length; j++){
      int[] face = faces[j];
      WB_Vector normal = mesh.getFaceNormal(j);
      
      PShape polygon = createShape();

      polygon.beginShape(POLYGON);
      polygon.normal(normal.xf(), normal.yf(), normal.zf());
      
      for(int k = 0; k < face.length; k++){
        WB_Coord vtx = verts.get(face[k]);
        
        float x = vtx.xf() - center_of_mass.x;
        float y = vtx.yf() - center_of_mass.y;
        float z = vtx.zf() - center_of_mass.z;
        polygon.vertex(x,y,z);
        
        if(on_bounds[face[k]]){
          on_boundary++;
        }
      }
      
      polygon.endShape(CLOSE);
//      polygon.setFill(true);
//      if(on_boundary == face.length){
//      if(on_boundary > 0){
//        polygon.setFill(color(8));
//      } else {
//        polygon.setFill(color(255,0,0));
//      }
//    
//      polygon.setStroke(false);
      
      
      voronoi_cell.addChild(polygon);
    }

    String wire = "";
    voronoi_cell.setFill(true);
//    if(on_boundary == face.length){
    if(on_boundary > 0){
      voronoi_cell.setFill(color(32));
      wire = "[wire]";
    } else {
      voronoi_cell.setFill(color(255,8,0));
    }
  
    voronoi_cell.setStroke(false);
    voronoi_cell.setStroke(color(64,4,0));
    voronoi_cell.setName("[cvh] "+wire);

    return voronoi_cell;
  }
  
  
  
  
  // add ground bodies
  public void addGround(){
    {
      Vector3f pos = new Vector3f(0,0,10);
      BObject obj = new BBox(this, 0, 650, 650, 20);
      BObject body = new BObject(this, 0, obj, pos, true);
      
      body.setPosition(pos);
  
      body.displayShape.setStroke(false);
      body.displayShape.setFill(true);
      body.displayShape.setFill(color(200, 96, 16));
      body.displayShape.setFill(color(255));
      body.displayShape.setStrokeWeight(1);
      body.displayShape.setStroke(color(0));
      if(obj instanceof BBox){
        fixBoxNormals(body.displayShape);
      }
      physics.addBody(body);
      group_bulletbodies.addChild(body.displayShape);
      body.displayShape.setName("ground_box");
    }
  }
  
  
  
  

  // render scene
  public void displayScene(PGraphics3D pg){
    if(pg == skylight.renderer.pg_render){
      pg.background(16);
    }
    
    if(pg == geombuffer.pg_geom){
      pg.background(255, 255);
      pg.pgl.clearColor(1, 1, 1, 6000);
      pg.pgl.clear(PGL.COLOR_BUFFER_BIT);
    }
    
    pg.pushMatrix();
    pg.applyMatrix(mat_scene_view);
    pg.shape(group_bulletbodies);
    pg.popMatrix();
  }
  
  
  // update PShape matrices
  Transform transform = new Transform();
  Matrix4f out = new Matrix4f();
  
  public void updateShapes(BObject body){
    if (body.displayShape != null) {
      body.displayShape.resetMatrix();
      if (body.getMass() < 0) {
        transform = body.rigidBody.getMotionState().getWorldTransform(transform);
        out = transform.getMatrix(out);
        body.transform.set(transform);
        body.displayShape.applyMatrix(out.m00, out.m01, out.m02, out.m03, out.m10, out.m11, out.m12, out.m13, out.m20, out.m21, out.m22, out.m23, out.m30, out.m31, out.m32, out.m33);

      } else {
        transform = body.rigidBody.getWorldTransform(transform);
        body.transform.set(transform);
        body.displayShape.translate(transform.origin.x, transform.origin.y, transform.origin.z);
     
        
      }
    }
  }

  
  public void saveScreenshot(){
    File file = capture.createFilename();
//    pg_aa.save(file.getAbsolutePath());
    save(file.getAbsolutePath());
    System.out.println(file);
  }