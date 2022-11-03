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
        
        simd::float4x4 RM;
        
        for(int i=0; i<4; i++) {
            for(int j=0; j<4; j++) {
                RM.columns[i][j] = 0;
            }
        }
        
        RM.columns[0][0] = 1;
        RM.columns[1][1] = 1;
        RM.columns[2][2] = 1;
        RM.columns[3][3] = 1;
        
        simd::float4x4 PM;
        PM.columns[0] = simd::float4{ 1.422119, 0.000000, 0.000000, 0.000000 };
        PM.columns[1] = simd::float4{0.000000, 2.528212, 0.000000, 0.000000 };
        PM.columns[2] = simd::float4{-0.000878, 0.005784, -1.000000, -1.000000 };
        PM.columns[3] = simd::float4{0.000000, 0.000000, -0.001000, 0.000000 };
        
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
        
        float points[4][2];
        
        float px[4] = {-0.5,0.5,0.5,-0.5};
        float py[4] = {-0.5,-0.5,0.5,0.5};
        
        for(int n=0; n<4; n++) {
            
            float x = px[n];
            float y = py[n];

            simd::float4 xyzw = (RM*(simd::float4{x,y,-PLANE_Z,-1.0}));
            
            xyzw.z-=OFFSET_Z;
            xyzw = PM*xyzw;
            
            points[n][0] = (W*0.5);
            points[n][1] = (H*0.5);
            
            if(xyzw.z) {
                points[n][0]+=(xyzw.x/xyzw.z*(W*0.5));
                points[n][1]-=(xyzw.y/xyzw.z*(H*0.5));
            }
        }
        
        [svg appendString:@"<g id=\"plane\" fill=\"#AAA\">"];

        drawQuad(svg,points[0][0],points[0][1],points[1][0],points[1][1],points[2][0],points[2][1],points[3][0],points[3][1]);
        
        [svg appendString:@"</g>"];
        
        int cx = (W*0.5);
        int cy = (H*0.5);
        
        {
            simd::float4 xyzw = (RM*(simd::float4{0.0,0.0,0.0,-1.0})).xyzw;
            xyzw.z-=OFFSET_Z;
            xyzw = PM*xyzw;
            
            if(xyzw.z) {
                cx+=(xyzw.x/xyzw.z*(W*0.5));
                cy-=(xyzw.y/xyzw.z*(H*0.5));
            }
        }
        
        [svg appendString:@"<g id=\"lines\" fill=\"none\" stroke=\"#FFF\" stroke-width=\"3\" stroke-linecap=\"round\">"];
        
        drawLine(svg,cx,cy,points[0][0],points[0][1]);
        drawLine(svg,cx,cy,points[1][0],points[1][1]);
        drawLine(svg,cx,cy,points[2][0],points[2][1]);
        drawLine(svg,cx,cy,points[3][0],points[3][1]);
        
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
        
        stb_image::stbi_write_jpg("../../dst.jpg",W,H,4,(void const*)texture,64);
        
        if(pixels) pixels = nullptr;
        if(document) document = nullptr;
        if(texture) delete[] texture;
            
    }
    
    return 0;
}
