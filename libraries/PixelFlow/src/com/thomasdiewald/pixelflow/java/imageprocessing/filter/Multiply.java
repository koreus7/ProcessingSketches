/**
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */


package com.thomasdiewald.pixelflow.java.imageprocessing.filter;


import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTexture;

import processing.opengl.PGraphicsOpenGL;
import processing.opengl.Texture;

public class Multiply {
  
  public DwPixelFlow context;
  
  public Multiply(DwPixelFlow context){
    this.context = context;
  }
  
  
  public void apply(PGraphicsOpenGL src, PGraphicsOpenGL dst, float[] multiplier) {
    Texture tex_src = src.getTexture(); if(!tex_src.available())  return;
    Texture tex_dst = dst.getTexture(); if(!tex_dst.available())  return;
       
//    dst.beginDraw();
    context.begin();
    context.beginDraw(dst);
    apply(tex_src.glName, dst.width, dst.height, multiplier);
    context.endDraw();
    context.end("Multiply.apply");
//    dst.endDraw();
  }
  
  public void apply(PGraphicsOpenGL src, DwGLTexture dst, float[] multiplier) {
    Texture tex_src = src.getTexture();
    if(!tex_src.available()) 
      return;
       
    context.begin();
    context.beginDraw(dst);
    apply(tex_src.glName, dst.w, dst.h, multiplier);
    context.endDraw();
    context.end("Multiply.apply");
  }
  
  
  public void apply(DwGLTexture src, DwGLTexture dst, float[] multiplier) {
    context.begin();
    context.beginDraw(dst);
    apply(src.HANDLE[0], dst.w, dst.h, multiplier);
    context.endDraw();
    context.end("Multiply.apply");
  }
  
  DwGLSLProgram shader;
  public void apply(int tex_handle, int w, int h, float[] multiplier){
    if(shader == null) shader = context.createShader(DwPixelFlow.SHADER_DIR+"Filter/multiply.frag");
    shader.begin();
    shader.uniform2f     ("wh_rcp", 1f/w, 1f/h);
    shader.uniformTexture("tex", tex_handle);
    shader.uniform4fv    ("multiplier", 1, multiplier);
    shader.drawFullScreenQuad(0, 0, w, h);
    shader.end();
  }
  
  
}
