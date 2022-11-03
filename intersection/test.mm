#import <Foundation/Foundation.h>
#import <vector>
#import <simd/simd.h>

simd::float3 intersection(simd::float3 p1, simd::float3 p2) {
	simd::float3 p = p1;
	simd::float3 v = p2-p1;
	simd::float3 n = {0,0,+1};
	return p+v*(simd::dot(simd::float3{0,0,0},n)-(simd::dot(p,n)/simd::dot(v,n)));
}

std::vector<simd::float3> quad(simd::float3 *points) {

	std::vector<simd::float3> results;
	
	int num = 0; 
	bool draw[4] = {true,true,true,true};
	for(int n=0; n<4; n++) {
		if(points[n].z>0) {
			draw[n] = false;
			num++;
		}
	}
	
	if(num!=0) {
		if(num==4) {
			for(int n=0; n<4; n++) {
				results.push_back(points[n]);
			}
		}
		else {

			if(num==3) {
				
				for(int n=0; n<4; n++) {
					
					if(draw[n]) { // (n-1), n, (n+1)
						
						results.push_back(points[n]);
						
						int L = n-1;
						if(L<0) L+=4; 
						
						int R = (n+1)%4;
						
						simd::float3 p[2] = {
							intersection(points[L],points[n]),
							intersection(points[n],points[R])
						};
						
						results.push_back(p[0]);
						results.push_back(p[1]);
						
						break;
					}
				}
			}
			else if(num==2) {
				
				if(draw[0]&&draw[1]) { // p0, p1, (p2), (p3)
					
					simd::float3 p[2] = {
						intersection(points[1],points[2]),
						intersection(points[3],points[0])
					};
					
					results.push_back(points[0]);
					results.push_back(points[1]);
					results.push_back(p[0]);
					results.push_back(p[1]);
					
				}
				else if(draw[1]&&draw[2]) { // (p0), p1, p2, (p3)
					
					simd::float3 p[2] = {
						intersection(points[0],points[1]),
						intersection(points[2],points[3])
					};
					
					results.push_back(p[0]);
					results.push_back(points[1]);
					results.push_back(points[2]);
					results.push_back(p[1]);
					
				}
				else if(draw[2]&&draw[3]) { // (p0), (p1), p2, p3
					
					simd::float3 p[2] = {
						intersection(points[3],points[0]),
						intersection(points[1],points[2])
					};
					
					results.push_back(p[0]);
					results.push_back(p[1]);
					results.push_back(points[2]);
					results.push_back(points[3]);
					
				}
				else if(draw[3]&&draw[1]) { // p0, (p1), (p2), p3
					
					simd::float3 p[2] = {
						intersection(points[0],points[1]),
						intersection(points[2],points[3])
					};
					
					results.push_back(points[0]);
					results.push_back(p[0]);
					results.push_back(p[1]);
					results.push_back(points[3]);
					
				}
			}
			else if(num==1) { // n-1, (n), (n), n+1 n+2
				
				for(int n=0; n<4; n++) {
					
					if(draw[n]) {
						results.push_back(points[n]);
					}
					else {
						
						int L = n-1;
						if(L<0) L+=4; 
						
						int R = (n+1)%4;
						
						simd::float3 p[2] = {
							intersection(points[L],points[n]),
							intersection(points[n],points[R])
						};
						
						results.push_back(p[0]);
						results.push_back(p[1]);
						
					}
				}
			}
		}
	}
	else {
		
	}
	
	return results;
}

std::vector<simd::float3> line(simd::float3 a, simd::float3 b) {

	std::vector<simd::float3> results;
	
	if(!(a.z>0&&b.z>0)) {
		
		if(a.z<=0&&b.z<=0) {
			results.push_back(a);
			results.push_back(b);
		}
		else if(a.z>0) {
			simd::float3 c = intersection(b,a);
			if(!(b.x==c.x&&b.y==c.y&&b.z==c.z)) {
				results.push_back(b);
				results.push_back(c);
			}
		}
		else if(b.z>0) {
			simd::float3 c = intersection(a,b);
			if(!(a.x==c.x&&a.y==c.y&&a.z==c.z)) {
				results.push_back(a);
				results.push_back(c);
			}
		}
	}
	
	return results;
}

int main(int argc, char *argv[]) {
	@autoreleasepool {

		simd::float3 points[4] = {
			simd::float3{-2.998540,-4.325368,-0.918615},
			simd::float3{-0.227259,0.227259,0.307068},
			simd::float3{4.325368,2.998540,-0.918615},
			simd::float3{1.554087,-1.554087,-2.144299}
		};

		std::vector<simd::float3> q = quad(points);
		
		if(q.size()>0) {
			for(int n=0; n<q.size(); n++) {
				printf("v %f %f %f\n",q[n].x,q[n].y,q[n].z);
			}
			
			printf("f");
			for(int n=0; n<q.size(); n++) {
				printf(" %d",n+1);
			}
			printf("\n");
		}
		
		simd::float3 eye = simd::float3{0,0,0};
		
		std::vector<simd::float3> l = line(eye,points[1]);
		
		if(l.size()>=2) {
			NSLog(@"%f,%f,%f",l[0].x,l[0].y,l[0].z);
			NSLog(@"%f,%f,%f",l[1].x,l[1].y,l[1].z);
		}
		
	}
}