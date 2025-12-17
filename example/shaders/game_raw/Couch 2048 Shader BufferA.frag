void mainImage(out vec4 O,in vec2 U){
	int id=int(U.x);
    vec2 R=iResolution.xy,
         M=(2.*iMouse.xy-R)/R.y;
    bool gd=texelFetch(iChannel0,ivec2(0),0).x<100.;
    if(id<NUM_BALLS&&U.y<1.){
        if(iFrame==0){
            if(id==19||id==20){O=vec4(0.,.5*float(id-20),0.,0.);
            //Cheats. Comment out the previous line and use one of these instead ;)
            //You Cheated Not Only the Game, But Yourself Though
            //if(id==2||id==3||id==5||id==7){O=vec4(0.,1.*float(id-2),0.,0.);
            //if(id==1||id==2){O=vec4(0.,1.*float(id-1),0.,0.);
            }else if(id==NUM_BALLS){
                O=vec4(-1.);
            }else{
                O=vec4(100.,0.,0.,0.);
            }
        }else{
            O=texelFetch(iChannel0,ivec2(id,0),0);
            int ds=19;
            if(texelFetch(iChannel0,ivec2(1,0),0).x<100.||
               texelFetch(iChannel0,ivec2(2,0),0).x<100.){
            	ds=15;
            }else if(texelFetch(iChannel0,ivec2(3,0),0).x<100.||
               		 texelFetch(iChannel0,ivec2(4,0),0).x<100.){
            	ds=17;
            }
            if(O.x<100.){
                int db=2*((id+1)/2);
                vec2 dp0=texelFetch(iChannel0,ivec2(db,0),0).xy;
                vec2 dp1=texelFetch(iChannel0,ivec2(db-1,0),0).xy;
                if(id!=0&&dp0.x<100.&&dp1.x<100.&&length(dp0-dp1)<2.*getBallRadFromID(id)){
                    O=vec4(100.,0.,0.,0.);
                }else{
                    for(int i=0;i<NUM_BALLS;i++){
                        if(i==id){
                            continue;
                        }
                        vec4 b=texelFetch(iChannel0,ivec2(i,0),0);
                        if(b.x<100.){
                            float l=length(b.xy-O.xy);
                            float d=getBallRadFromID(id)+getBallRadFromID(i);
                            if(l<d){
                                O.zw+=.08*sign(O.xy-b.xy)*(d-abs(O.xy-b.xy))/d;
                                O.zw*=.95;
                            }
                        }
                    }
                    float c=exSDF(O.xy)-getBallRadFromID(id);
                    if(c<0.){
                        O.zw-=2.*c*SDFGrad(O.xy);//6.//3.
                        O.zw*=.97;
                    }
                    if(!gd&&id==int(texelFetch(iChannel0,ivec2(NUM_BALLS,0),0).x)&&O.y<1.){
                        O.zw+=.5*normalize(M-O.xy)*max(0.,min(length(M-O.xy)-.05,.2));
                    }
                    O.zw*=.98;
                    O.w-=.03;
                    O.xy+=.032*O.zw;
                    if(O.y<-1.2){O=vec4(100.,0.,0.,0.);}
                }
            }else if(id==ds||id==ds+1){
                bool bc=true;
                for(int i=1;i<10;i++){
                    bc=bc&&!(texelFetch(iChannel0,ivec2(2*i,0),0).x<100.&&
                             texelFetch(iChannel0,ivec2(2*i-1,0),0).x<100.);
                }
                if(bc){
                    O=vec4(sin(iTime+float(id)),3.+float(id-ds),0.,0.)/2.;
                }
            }else{
                int db=2*((id+1)/2)+1;
                vec2 dp0=texelFetch(iChannel0,ivec2(db,0),0).xy;
                vec2 dp1=texelFetch(iChannel0,ivec2(db+1,0),0).xy;
                if(dp0.x<100.&&dp1.x<100.&&length(dp0-dp1)<2.*getBallRadFromID(db)){
                    if(id%2==1){
                        if(O.x>=100.){
                            O=vec4(dp0+dp1,0.,0.)/2.;
                        }
                    }else{
                        if(texelFetch(iChannel0,ivec2(id-1,0),0).x<100.||id==0){
                            O=vec4(dp0+dp1,0.,0.)/2.;
                        }
                    }
                }
            }
        }
    }else if(id==NUM_BALLS&&U.y<1.){
        O=texelFetch(iChannel0,ivec2(id,0),0);
        if(O.x==-1.){
            if(iMouse.z>0.){
                float md=1.;
                int mi=-1;
                for(int i=0;i<NUM_BALLS;i++){
                    vec2 b=texelFetch(iChannel0,ivec2(i,0),0).xy;
                    if(b.x<100.){
                        float d=length(b-M)/getBallRadFromID(i);
                        if(d<md){
                            md=d;
                            mi=i;
                        }
                    }
                }
                O.x=float(mi);
            }
        }else{
            vec2 dp=texelFetch(iChannel0,ivec2(O.x,0),0).xy;
            if(iMouse.z<=0.||dp.x>100.||dp.y>1.){
                O.x=-1.;
            }
        }
    }else if(id<NUM_BALLS&&U.y<2.){
        O.x=texelFetch(iChannel0,ivec2(id,1),0).x+.3*texelFetch(iChannel0,ivec2(id,0),0).z;
    }
}