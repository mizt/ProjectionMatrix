#import <Cocoa/Cocoa.h>
#import <simd/simd.h>
#import <string>

#import "lunasvg.h"
#import "Config.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBI_ONLY_PNG

namespace stb_image {
    #import "stb_image_write.h"
}

float radians(float angle) {
    return M_PI*(angle/180.0);
}

simd::float4x4 projectionMatrix(float fovy, float aspect, float near, float far) {

    float angle  = radians(0.5f*fovy);
    float yScale = 1.0f/std::tan(angle);
    float xScale = yScale/aspect;
    float zScale = far/(far-near);

    simd::float4 P;
    simd::float4 Q;
    simd::float4 R;
    simd::float4 S;

    P.x = xScale;
    P.y = 0.0f;
    P.z = 0.0f;
    P.w = 0.0f;

    Q.x = 0.0f;
    Q.y = yScale;
    Q.z = 0.0f;
    Q.w = 0.0f;

    R.x = 0.0f;
    R.y = 0.0f;
    R.z = zScale;
    R.w = 1.0f;

    S.x =  0.0f;
    S.y =  0.0f;
    S.z = -near * zScale;
    S.w =  0.0f;

    return simd::float4x4(P,Q,R,S);
}

simd::float4x4 rotationMatrix(const float angle, const simd::float3 v) {
    
    simd::float4 P;
    simd::float4 Q;
    simd::float4 R;
    simd::float4 S;
    
    if(v.x==0&&v.y==0&&v.z==0) {
        
        P = simd::float4{1,0,0,0};
        Q = simd::float4{0,1,0,0};
        R = simd::float4{0,0,1,0};
        S = simd::float4{0,0,0,1};
        
    }
    else {
        
        float r = radians(angle);
        float s = sin(r);
        float c = cos(r);
        float oc = 1.0-c;
        
        P.x = oc*v.x*v.x+c;
        P.y = oc*v.x*v.y-v.z*s;
        P.z = oc*v.z*v.x+v.y*s;
        P.w = 0.0f;
        
        Q.x = oc*v.x*v.y+v.z*s;
        Q.y = oc*v.y*v.y+c;
        Q.z = oc*v.y*v.z-v.x*s;
        Q.w = 0.0f;
        
        R.x = oc*v.z*v.x-v.y*s;
        R.y = oc*v.y*v.z+v.x*s;
        R.z = oc*v.z*v.z+c;
        R.w = 0.0f;
        
        S.x = 0.0f;
        S.y = 0.0f;
        S.z = 0.0f;
        S.w = 1.0f;
        
    }
    
    return simd::float4x4(P,Q,R,S);
}


void drawLine(NSMutableString *svg, int x1, int y1, int x2, int y2) {
    [svg appendString:[NSString stringWithFormat:@"<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",x1,y1,x2,y2]];
}

void drawQuad(NSMutableString *svg, int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
    [svg appendString:[NSString stringWithFormat:@"<polyline points=\"%d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d\" />",x1,y1,x2,y2,x2,y2,x3,y3,x3,y3,x4,y4,x4,y4,x1,y1]];
}

void drawTriangle(NSMutableString *svg, int x1, int y1, int x2, int y2, int x3, int y3) {
    [svg appendString:[NSString stringWithFormat:@"<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",x1,y1,x2,y2]];
    [svg appendString:[NSString stringWithFormat:@"<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",x2,y2,x3,y3]];
    [svg appendString:[NSString stringWithFormat:@"<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",x3,y3,x1,y1]];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        int W = 1920*2;
        int H = 1080*2;
        
        NSString *setting = [NSString stringWithFormat:@"<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"0 0 %d %d\" style=\"enable-background:new 0 0 %d %d;\" xml:space=\"preserve\"><rect x=\"0\" y=\"0\" width=\"%d\" height=\"%d\" fill=\"none\" stroke=\"none\" />",W,H,W,H,W,H];
    
        unsigned int *texture = new unsigned int[W*H];
        
        const float ANGLE = 130;
        simd::float4x4 RM = rotationMatrix(ANGLE,simd::float3{1,1,0});

        printf("{\n");
        for(int i=0; i<4; i++) {
            printf("\t");
            for(int j=0; j<4; j++) {
                printf("%f",RM.columns[i][j]);
                if(!(i==3&&j==3)) printf(", ");
            }
            printf("\n");
        }
        printf("}\n");
        
        const float FOV = 60;
        simd::float4x4 PM = projectionMatrix(FOV,1.0,0.01,1000);
        
        printf("{\n");
        for(int i=0; i<4; i++) {
            printf("\t");
            for(int j=0; j<4; j++) {
                printf("%f",PM.columns[i][j]);
                if(!(i==3&&j==3)) printf(", ");
            }
            printf("\n");
        }
        printf("}\n");
        
        NSMutableString *svg = [NSMutableString stringWithCapacity:0];
        [svg appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
        [svg appendString:setting];
        
        simd::float4 xyzw[4];
        float points[4][2];
        
        float px[4] = {-0.8, 0.8,0.8,-0.8};
        float py[4] = {-0.8,-0.8,0.8, 0.8};
        
        bool draw[4] = {
            false,
            false,
            false,
            false
        };
        
        for(int n=0; n<4; n++) {
            
            float x = px[n];
            float y = py[n];

            xyzw[n] = (RM*(simd::float4{x,y,PLANE_Z,-1.0}));
            
            xyzw[n].z+=OFFSET_Z;
            
            //NSLog(@"%f,%f,%f",xyzw.x,xyzw.y,xyzw.z);

            xyzw[n] = PM*xyzw[n];
            
            printf("simd::float3 p%d = {%f,%f,%f};\n ",n,xyzw[n].x,xyzw[n].y,xyzw[n].z);
                        
            if(xyzw[n].z<0) draw[n] = true;
            
          
        }
        
        if(draw[0]||draw[1]||draw[2]||draw[3]) {
            
            for(int n=0; n<4; n++) {
                
                if(draw[n]) {
                    
                    points[n][0] = (W*0.5);
                    points[n][1] = (H*0.5);
                    if(xyzw[n].z) {
                        points[n][0]+=(xyzw[n].x/xyzw[n].z*(W*0.5));
                        points[n][1]-=(xyzw[n].y/xyzw[n].z*(H*0.5));
                    }
                    
                }
                
            }
            
            [svg appendString:@"<g id=\"plane\" fill=\"rgb(255,0,0)\" opacity=\"0.5\">"];

            if(draw[0]&&draw[1]&&draw[2]&&draw[3]) {
                drawQuad(svg,points[0][0],points[0][1],points[1][0],points[1][1],points[2][0],points[2][1],points[3][0],points[3][1]);
            }
            
            [svg appendString:@"</g>"];
            
            int cx = (W*0.5);
            int cy = (H*0.5);
            
            {
                simd::float4 xyzw = (RM*(simd::float4{0.0,0.0,0.0,-1.0})).xyzw;
                xyzw.z+=OFFSET_Z;
                xyzw = PM*xyzw;
                
                if(xyzw.z) {
                    cx+=(xyzw.x/xyzw.z*(W*0.5));
                    cy-=(xyzw.y/xyzw.z*(H*0.5));
                }
            }
            
            [svg appendString:@"<g id=\"lines\" fill=\"none\" stroke=\"#FFF\" opacity=\"0.5\" stroke-width=\"3\" stroke-linecap=\"round\">"];
            
            if(draw[0]) drawLine(svg,cx,cy,points[0][0],points[0][1]);
            if(draw[1]) {
                
                
                
                drawLine(svg,cx,cy,points[1][0],points[1][1]);
            }
            if(draw[2]) drawLine(svg,cx,cy,points[2][0],points[2][1]);
            if(draw[3]) drawLine(svg,cx,cy,points[3][0],points[3][1]);
            
            [svg appendString:@"</g>"];
            [svg appendString:@"</svg>"];
            
            std::string str = [svg UTF8String];
            std::unique_ptr<lunasvg::Document> document = lunasvg::Document::loadFromData(str);
            
            lunasvg::Bitmap bitmap = document->renderToBitmap();
                            
            unsigned int *pixels = (unsigned int *)bitmap.data();
            int rb = bitmap.stride()>>2;

            for(int i=0; i<H; i++) {
                for(int j=0; j<W; j++) {
                    texture[i*W+j] = pixels[i*rb+j];
                }
            }
            
            if(pixels) pixels = nullptr;
            if(document) document = nullptr;
            
        }
        else {
            for(int i=0; i<H; i++) {
                for(int j=0; j<W; j++) {
                    texture[i*W+j] = 0xFFFF0000;
                }
            }
        }
        
        
        stb_image::stbi_write_jpg("../../dst.jpg",W,H,4,(void const*)texture,64);

        
        
        if(texture) delete[] texture;
            
    }
    
    return 0;
}
