precision highp float;
uniform vec3 iResolution;
uniform float iTime;
uniform float iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iChannelResolution[4];
in vec2 vUv;
out vec4 fragColor;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelSize = 1. / iResolution.xy;
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);

    vec4 noise = texture(iChannel3, fragCoord.xy / iChannelResolution[3].xy + fract(vec2(42,56)*iTime));
    
	vec2 lightSize=vec2(4.);

    // get the gradients from the blurred image
	vec2 d = pixelSize*2.;
	vec4 dx = (texture(iChannel2, uv + vec2(1,0)*d) - texture(iChannel2, uv - vec2(1,0)*d))*0.5;
	vec4 dy = (texture(iChannel2, uv + vec2(0,1)*d) - texture(iChannel2, uv - vec2(0,1)*d))*0.5;

	// add the pixel gradients
	d = pixelSize*1.;
	dx += texture(iChannel0, uv + vec2(1,0)*d) - texture(iChannel0, uv - vec2(1,0)*d);
	dy += texture(iChannel0, uv + vec2(0,1)*d) - texture(iChannel0, uv - vec2(0,1)*d);

	vec2 displacement = vec2(dx.x,dy.x)*lightSize; // using only the red gradient as displacement vector
	float light = pow(max(1.-distance(0.5+(uv-0.5)*aspect*lightSize + displacement,0.5+(iMouse.xy*pixelSize-0.5)*aspect*lightSize),0.),4.);

	// recolor the red channel
	float val = texture(iChannel0,uv+vec2(dx.x,dy.x)*pixelSize*8.).x;
	vec4 rd = vec4(val)*vec4(0.7,1.5,2.0,1.0)-vec4(0.3,1.0,1.0,1.0);
    
    // and add the light map
    fragColor = mix(rd,vec4(8.0,6.,2.,1.), light*0.75*vec4(1.-val)); 
	
	// Debug: test各个值
	// fragColor = vec4(val); // 测试val
	// fragColor = vec4(light); // 测试light
	// fragColor = rd; // 测试rd颜色映射
	// fragColor = vec4(abs(dx.x), abs(dy.x), 0., 1.); // 测试梯度    
}

void main() {
    vec2 fragCoord = vUv * iResolution.xy;
    mainImage(fragColor, fragCoord);
}