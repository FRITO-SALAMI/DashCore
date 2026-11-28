#include <flutter/runtime_effect.glsl>
precision mediump float;
uniform vec2 uSize;
uniform vec3 uPaint;
uniform float uLighting;
uniform sampler2D uTexture;
out vec4 fragColor;
void main() {
  vec2 uv=FlutterFragCoord().xy/uSize;
  vec4 pixel=texture(uTexture,clamp(uv,0.0,1.0));
  pixel*=step(0.0,uv.x)*step(0.0,uv.y)*step(uv.x,1.0)*step(uv.y,1.0);
  vec3 rgb=pixel.rgb/max(pixel.a,0.00001);
  float red=rgb.r-max(rgb.g,rgb.b);
  float mask=smoothstep(0.025,0.11,red)*smoothstep(0.07,0.23,rgb.r);
  // Preserve only the outer rear lenses with soft boundaries.
  float tail=smoothstep(0.17,0.29,abs(uv.x-0.5))*smoothstep(0.845,0.87,uv.y)*(1.0-smoothstep(0.91,0.935,uv.y));
  mask*=1.0-tail;
  float shade=clamp(rgb.r*1.40,0.0,1.10);
  float reflection=min(rgb.g,rgb.b);
  vec3 paint=uPaint*shade+vec3(reflection*0.40);
  vec3 body=mix(rgb,clamp(paint,0.0,1.0),mask)*pixel.a;
  float forward=max(0.0,0.12-uv.y);
  float width=0.016+forward*0.34;
  float dxL=(uv.x-0.23)/width, dxR=(uv.x-0.77)/width;
  float left=exp(-2.0*dxL*dxL);
  float right=exp(-2.0*dxR*dxR);
  float beam=(left+right)*exp(-forward*11.0)*step(uv.y,0.12)*uLighting*0.48;
  vec2 rearL=(uv-vec2(0.25,0.88))/vec2(0.11,0.045);
  vec2 rearR=(uv-vec2(0.75,0.88))/vec2(0.11,0.045);
  float rear=(exp(-dot(rearL,rearL)*1.6)+exp(-dot(rearR,rearR)*1.6))*uLighting*0.32;
  float glow=clamp(beam+rear,0.0,1.0)*(1.0-pixel.a);
  vec3 glowColor=(vec3(0.78,0.89,1.0)*beam+vec3(1.0,0.06,0.025)*rear)*(1.0-pixel.a);
  fragColor=vec4(body+glowColor,pixel.a+glow);
}
