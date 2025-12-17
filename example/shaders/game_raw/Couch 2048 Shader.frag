void mainImage(out vec4 O,in vec2 U){
    vec2 R=iResolution.xy,
         p=(U+U-R)/R.y;
    O=vec4(0.);
    float m0=1000.,
          m1=1000.;
    int mi=-3;
    vec2 mp;
    for(int i=0;i<NUM_BALLS;i++){
        vec2 tp=texelFetch(iChannel0,ivec2(i,0),0).xy;
        float mt=length(tp-p)-getBallRadFromID(i);
        if(mt<m1){
        	m1=mt;
            if(m1<m0){mi=i;mt=m1;m1=m0;m0=mt;mp=tp;}
        }
    }
    float mt=min(min(p.y+.9,p.x+1.7),1.7-p.x);
    mt=exSDF(p);
    if(mt<m1){
        m1=mt;
        if(m1<m0){mt=m1;m1=m0;m0=mt;mi=-3;}
    }
    float r=texelFetch(iChannel0,ivec2(mi,1),0).x;
    mat2 rt=mat2(cos(r),sin(r),-sin(r),cos(r));
    mi=(mi+1)/2;
    vec3 c=vec3(238.,228.,218.);
    float cu=SQSDF(p-vec2(0.,-.25),vec2(.7,.24))-.2;
    float st=1./R.y;
    vec3 bc=mix(vec3(119.,110.,101)*clamp(3.*min(mt,cu)+.8,0.,1.),
                vec3(238.,228.,218.)*.75*clamp(.5*p.y+1.,0.,1.),
                1.-smoothstep(-st,st,cu));
    //color values based on the original game
    switch(mi){
        case  0:c=vec3(237.,194.,46);break;
        case  1:c=vec3(237.,197.,63);break;
        case  2:c=vec3(237.,200.,80);break;
        case  3:c=vec3(237.,204.,97);break;
        case  4:c=vec3(237.,207.,114);break;
        case  5:c=vec3(246.,94.,59);break;
        case  6:c=vec3(246.,124.,95);break;
        case  7:c=vec3(245.,149.,99);break;
        case  8:c=vec3(242.,177.,121.);break;
        case  9:c=vec3(237.,224.,200.);break;
        case 10:c=vec3(238.,228.,218.);break;
    }
    float d=-1.;
    #define t(a,b) texture(iChannel1,(.5+vec2(a,12.))/16.+(clamp(q+vec2(b,0.)/8.,-.125,.125))/4.).x-127./255.
    vec2 q=rt*(p-mp);
    if(mi>-1){
        switch(mi){
            case  0:d=max(max(t(2.,1.35),t(0.,.45)),max(t(4.,-.45),t(8.,-1.35)));break;
            case  1:d=max(max(t(1.,1.35),t(0.,.45)),max(t(2.,-.45),t(4.,-1.35)));break;//WIP
            case  2:d=max(t(5.,.9),max(t(1.,0.),t(2.,-.9)));break;
            case  3:d=max(t(2.,.9),max(t(5.,0.),t(6.,-.9)));break;
            case  4:d=max(t(1.,.9),max(t(2.,0.),t(8.,-.9)));break;
            case  5:d=max(t(6.,.45),t(4.,-.45));break;
            case  6:d=max(t(3.,.45),t(2.,-.45));break;
            case  7:d=max(t(1.,.45),t(6.,-.45));break;
            case  8:d=t(8.,0.);break;
            case  9:d=t(4.,0.);break;
            case 10:d=t(2.,0.);break;
        }
        c=mix(c,(mi>8?vec3(119.,110.,101.):vec3(249.,246.,242.)),smoothstep(-st*256.,st*256.,d));
    }
    float l=min(smoothstep(-st,st,-m0),smoothstep(-st,st,m1-m0-.01));
    c=mix(bc,c,l);
    if(texelFetch(iChannel0,ivec2(0),0).x<100.){
    	q=p/3.;
    	#define t2(a,b) texture(iChannel1,(.5+a)/16.+(clamp(q+vec2(b,-1.3+.4*sin(.3*b+3.*iTime))/8.,-.125,.125))/4.).x-127./255.
    	d=      t2(vec2( 9.,10.), 3.);
        d=max(d,t2(vec2(15.,11.), 2.));
        d=max(d,t2(vec2( 5.,10.), 1.));
        d=max(d,t2(vec2( 7.,10.),-1.));
        d=max(d,t2(vec2( 9.,11.),-2.));
        d=max(d,t2(vec2(14.,11.),-3.));
        c=mix(c,vec3(249.,246.,242.),smoothstep(-st*256./3.,st*256./3.,d));
    }
   	c/=255.;
    O.rgb=c;
}