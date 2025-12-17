//ball sequence is as follows (value,size):
//  2048 | .42
//2x1024 | .39
//2x 512 | .36
//2x 256 | .33
//2x 128 | .30
//2x  64 | .27
//2x  32 | .24
//2x  16 | .21
//2x   8 | .18
//2x   4 | .15
//2x   2 | .12

#define NUM_BALLS 21

#define getBallRadFromID(id) (.42-.03*float((id+1)/2))

//Thanks IQ for the derivation of this function
float SQSDF(vec2 p,vec2 b){
    vec2 d=abs(p)-b;
    return min(max(d.x,d.y),0.)+length(max(d,vec2(0)));
}

float exSDF(vec2 p){
	float d=SQSDF(p-vec2(0.,-.85),vec2(.6,.05))-.2;
    d=min(d,SQSDF(p-vec2(.9,-.6),vec2(.04,.4))-.1);
    d=min(d,SQSDF(p-vec2(-.9,-.6),vec2(.04,.4))-.1);
    return min(d,SQSDF(p-vec2(0.,-.85),vec2(.5,.03))-.2);
}

vec2 SDFGrad(vec2 p){
	vec2 e=vec2(.001,0.);
    return normalize(vec2(exSDF(p+e.xy)-exSDF(p-e.xy),
                          exSDF(p+e.yx)-exSDF(p-e.yx)));
}