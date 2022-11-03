#import <Foundation/Foundation.h>
#import <simd/simd.h>

simd::float3 intersection(simd::float3 p1, simd::float3 p2) {
	simd::float3 p = p1;
	simd::float3 v = p2-p1;
	simd::float3 n = {0,0,+1};
	return p+v*(simd::dot(simd::float3{0,0,0},n)-(simd::dot(p,n)/simd::dot(v,n)));
}

void dumpQuad(bool *draw, simd::float3 *points) {
	
	int num = 0;
	for(int n=0; n<4; n++) {
		num = draw[n]?1:0;
	}
	
	if(num!=0) {
		
		if(num==4) {
			
			for(int n=0; n<4; n++) {
				printf("v %f %f %f\n",points[n].x,points[n].y,points[n].z);
			}
			
			printf("f 1 2 3 4\n");
			
		}
		else {
			
			if(num==3) {
				
				for(int n=0; n<4; n++) {
					
					if(draw[n]) { // (n-1), n, (n+1)
						
						printf("v %f %f %f\n",points[n].x,points[n].y,points[n].z);
						
						int L = n-1;
						if(L<0) L+=4; 
						
						int R = (n+1)%4;
						
						simd::float3 p[2] = {
							intersection(points[L],points[n]),
							intersection(points[n],points[R])
						};
						
						printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
						printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
						
						break;
					}
				}
				
				printf("f 1 2 3\n");
				
			}
			else if(num==2) {
				
				if(draw[0]&&draw[1]) { // p0, p1, (p2), (p3)
					
					simd::float3 p[2] = {
						intersection(points[1],points[2]),
						intersection(points[3],points[0])
					};
					
					printf("v %f %f %f\n",points[0].x,points[0].y,points[0].z);
					printf("v %f %f %f\n",points[1].x,points[1].y,points[1].z);
					printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
					printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
					
				}
				else if(draw[1]&&draw[2]) { // (p0), p1, p2, (p3)
					
					simd::float3 p[2] = {
						intersection(points[0],points[1]),
						intersection(points[2],points[3])
					};
					
					printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
					printf("v %f %f %f\n",points[1].x,points[1].y,points[1].z);
					printf("v %f %f %f\n",points[2].x,points[2].y,points[2].z);
					printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
					
				}
				else if(draw[2]&&draw[3]) { // (p0), (p1), p2, p3
					
					simd::float3 p[2] = {
						intersection(points[3],points[0]),
						intersection(points[1],points[2])
					};
					
					printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
					printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
					printf("v %f %f %f\n",points[2].x,points[2].y,points[2].z);
					printf("v %f %f %f\n",points[3].x,points[3].y,points[3].z);
					
				}
				else if(draw[3]&&draw[1]) { // p0, (p1), (p2), p3
					
					simd::float3 p[2] = {
						intersection(points[0],points[1]),
						intersection(points[2],points[3])
					};
					
					printf("v %f %f %f\n",points[0].x,points[0].y,points[0].z);
					printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
					printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
					printf("v %f %f %f\n",points[3].x,points[3].y,points[3].z);
					
				}
				
				printf("f 1 2 3 4\n");
				
			}
			else if(num==1) { // n-1, (n), (n), n+1 n+2
				
				for(int n=0; n<4; n++) {
					
					if(draw[n]) {
						printf("v %f %f %f\n",points[n].x,points[n].y,points[n].z);
					}
					else {
						
						int L = n-1;
						if(L<0) L+=4; 
						
						int R = (n+1)%4;
						
						simd::float3 p[2] = {
							intersection(points[L],points[n]),
							intersection(points[n],points[R])
						};
						
						printf("v %f %f %f\n",p[0].x,p[0].y,p[0].z);
						printf("v %f %f %f\n",p[1].x,p[1].y,p[1].z);
					}
					
				}
				
				printf("f 1 2 3 4 5");
				
			}
		}
	}
	else {
		
	}
}

int main(int argc, char *argv[]) {
	@autoreleasepool {
		
		bool draw[4] = {
			true,
			false,
			true,
			true
		};
		
		simd::float3 points[4] = {
			simd::float3{-2.998540,-4.325368,-0.918615},
			simd::float3{-0.227259,0.227259,0.307068},
			simd::float3{4.325368,2.998540,-0.918615},
			simd::float3{1.554087,-1.554087,-2.144299}
		};

		dumpQuad(draw,points);
	}
}