import * as THREE from "https://unpkg.com/three@0.160.0/build/three.module.js";

const SHADERS = {
    A: "./shaders/buffera.frag",
    B: "./shaders/bufferb.frag",
    C: "./shaders/bufferc.frag",
    D: "./shaders/bufferd.frag",
    MAIN: "./shaders/image.frag",
};

const NOISE_PATH = "./noise.png";

const canvas = document.createElement("canvas");
const gl = canvas.getContext("webgl2");
if (!gl) {
    throw new Error("需要 WebGL2 才能运行这些着色器。请使用支持 WebGL2 的浏览器。 ");
}

const renderer = new THREE.WebGLRenderer({
    canvas,
    context: gl,
    antialias: true,
    alpha: false,
    premultipliedAlpha: false,
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setClearColor(0x000000, 1);
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
const quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), new THREE.MeshBasicMaterial());
scene.add(quad);

const clock = new THREE.Clock();
let frame = 0;
let debugMode = 0;

const mouse = new THREE.Vector4(0, 0, 0, 0);
let pointerDown = false;
let activePointerId = null;
let hasClick = false;
let clickX = 0;
let clickY = 0;

function getMouseXY(event) {
    const rect = renderer.domElement.getBoundingClientRect();
    const x = (event.clientX - rect.left) * (renderer.domElement.width / rect.width);
    const y = (event.clientY - rect.top) * (renderer.domElement.height / rect.height);
    return {
        x,
        y: renderer.domElement.height - y,
    };
}

function syncMouseState() {
    // Shadertoy 语义：
    // - iMouse.xy：仅在按下期间更新；松开后保持最后值（不会随 hover 改变）
    // - iMouse.zw：按下起点坐标；按下时为正，松开后为负
    if (!hasClick) {
        mouse.z = 0;
        mouse.w = 0;
        return;
    }

    if (pointerDown) {
        mouse.z = clickX;
        mouse.w = clickY;
    } else {
        mouse.z = -clickX;
        mouse.w = -clickY;
    }
}

function setMouseMove(event) {
    // 只有按住时才更新 xy（这就是“按住拖动才跟随”的关键）
    if (!pointerDown) {
        syncMouseState();
        return;
    }
    const { x, y } = getMouseXY(event);
    mouse.x = x;
    mouse.y = y;
    syncMouseState();
}

function setMouseDown(event) {
    const { x, y } = getMouseXY(event);
    mouse.x = x;
    mouse.y = y;
    hasClick = true;
    clickX = x;
    clickY = y;
    mouse.z = clickX;
    mouse.w = clickY;
}

function setMouseUp(event) {
    const { x, y } = getMouseXY(event);
    mouse.x = x;
    mouse.y = y;
    if (hasClick) {
        mouse.z = -clickX;
        mouse.w = -clickY;
    } else {
        mouse.z = 0;
        mouse.w = 0;
    }
}

// 使用 Pointer Events 来保持“按住才跟随”的语义，并避免 mouseup 丢失导致 mouseDown 卡住。
renderer.domElement.addEventListener("pointerdown", (event) => {
    if (!event.isPrimary) return;
    if (event.button !== 0) return;
    event.preventDefault();
    pointerDown = true;
    activePointerId = event.pointerId;
    renderer.domElement.setPointerCapture?.(event.pointerId);
    setMouseDown(event);
});

renderer.domElement.addEventListener("pointermove", (event) => {
    if (!event.isPrimary) return;
    // 兜底：如果松开事件丢了（某些系统/浏览器/手势场景会发生），用 buttons 同步状态。
    if (pointerDown && activePointerId === event.pointerId && (event.buttons & 1) === 0) {
        pointerDown = false;
        activePointerId = null;
        setMouseUp(event);
        return;
    }
    setMouseMove(event);
});

renderer.domElement.addEventListener("pointerup", (event) => {
    if (!event.isPrimary) return;
    if (event.button !== 0) return;
    event.preventDefault();
    if (activePointerId === event.pointerId) {
        renderer.domElement.releasePointerCapture?.(event.pointerId);
        pointerDown = false;
        activePointerId = null;
    }
    setMouseUp(event);
});

renderer.domElement.addEventListener("pointercancel", (event) => {
    if (!event.isPrimary) return;
    if (activePointerId === event.pointerId) {
        renderer.domElement.releasePointerCapture?.(event.pointerId);
        pointerDown = false;
        activePointerId = null;
    }
    // cancel 视为松开
    setMouseUp(event);
});

window.addEventListener("keydown", (event) => {
    if (event.key === "0") debugMode = 0; // main
    if (event.key === "1") debugMode = 1; // A
    if (event.key === "2") debugMode = 2; // B
    if (event.key === "3") debugMode = 3; // C
    if (event.key === "4") debugMode = 4; // D
    if (event.key === "5") debugMode = 5; // noise
});

const canRenderFloat = renderer.extensions.has("EXT_color_buffer_float");
const renderTargetType = canRenderFloat ? THREE.HalfFloatType : THREE.UnsignedByteType;

function createRenderTarget(width, height) {
    const target = new THREE.WebGLRenderTarget(width, height, {
        minFilter: THREE.LinearFilter,
        magFilter: THREE.LinearFilter,
        wrapS: THREE.RepeatWrapping,
        wrapT: THREE.RepeatWrapping,
        format: THREE.RGBAFormat,
        type: renderTargetType,
        depthBuffer: false,
        stencilBuffer: false,
    });
    target.texture.colorSpace = THREE.NoColorSpace;
    return target;
}

function buildFragmentShader(source, postfix = "") {
    if (source.includes("void main(")) {
        return source;
    }
    return `precision highp float;
uniform vec3 iResolution;
uniform float iTime;
uniform int iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iChannelResolution[4];
in vec2 vUv;
out vec4 fragColor;

${source}

void main() {
		vec2 fragCoord = vUv * iResolution.xy;
		mainImage(fragColor, fragCoord);
		${postfix}
}
`;
}

function createUniforms() {
    return {
        iResolution: { value: new THREE.Vector3(1, 1, 1) },
        iTime: { value: 0 },
        iFrame: { value: 0 },
        iMouse: { value: mouse },
        iChannel0: { value: null },
        iChannel1: { value: null },
        iChannel2: { value: null },
        iChannel3: { value: null },
        iChannelResolution: {
            value: [
                new THREE.Vector3(1, 1, 1),
                new THREE.Vector3(1, 1, 1),
                new THREE.Vector3(1, 1, 1),
                new THREE.Vector3(1, 1, 1),
            ],
        },
    };
}

class ShaderPass {
    constructor(fragmentSource, width, height, options = {}) {
        const material = new THREE.RawShaderMaterial({
            vertexShader: `in vec3 position;
in vec2 uv;
out vec2 vUv;
void main() {
		vUv = uv;
		gl_Position = vec4(position, 1.0);
}
`,
            fragmentShader: buildFragmentShader(fragmentSource, options.postfix ?? ""),
            uniforms: createUniforms(),
            glslVersion: THREE.GLSL3,
        });

        this.material = material;
        this.readTarget = createRenderTarget(width, height);
        this.writeTarget = createRenderTarget(width, height);
        this.size = { width, height };
    }

    resize(width, height) {
        if (this.size.width === width && this.size.height === height) {
            return;
        }
        this.size = { width, height };
        this.readTarget.setSize(width, height);
        this.writeTarget.setSize(width, height);
    }

    get texture() {
        return this.readTarget.texture;
    }

    render(target = null, clear = false) {
        quad.material = this.material;
        const renderTarget = target ?? this.writeTarget;
        renderer.setRenderTarget(renderTarget);
        if (clear) {
            renderer.clear();
        }
        renderer.render(scene, camera);
        renderer.setRenderTarget(null);
        if (target === null) {
            const temp = this.readTarget;
            this.readTarget = this.writeTarget;
            this.writeTarget = temp;
        }
    }
}

async function loadText(path) {
    const res = await fetch(path);
    if (!res.ok) {
        throw new Error(`Failed to load ${path}`);
    }
    return res.text();
}

function setChannel(uniforms, index, texture, size = null) {
    uniforms[`iChannel${index}`].value = texture;
    if (size && size.width && size.height) {
        uniforms.iChannelResolution.value[index].set(size.width, size.height, 1);
    } else if (texture && texture.image && texture.image.width && texture.image.height) {
        uniforms.iChannelResolution.value[index].set(
            texture.image.width || 1,
            texture.image.height || 1,
            1
        );
    } else {
        uniforms.iChannelResolution.value[index].set(1, 1, 1);
    }
}

function updateCommonUniforms(pass, time, frameIndex, resolution) {
    pass.material.uniforms.iTime.value = time;
    pass.material.uniforms.iFrame.value = Math.floor(frameIndex);
    pass.material.uniforms.iResolution.value.copy(resolution);
    pass.material.uniforms.iMouse.value = mouse;
}

function loadTexture(path) {
    return new Promise((resolve, reject) => {
        new THREE.TextureLoader().load(
            path,
            (tex) => resolve(tex),
            undefined,
            (err) => reject(err)
        );
    });
}

async function init() {
    const [fragA, fragB, fragC, fragD, fragMain] = await Promise.all([
        loadText(SHADERS.A),
        loadText(SHADERS.B),
        loadText(SHADERS.C),
        loadText(SHADERS.D),
        loadText(SHADERS.MAIN),
    ]);

    const noiseTexture = await loadTexture(NOISE_PATH);
    noiseTexture.wrapS = THREE.RepeatWrapping;
    noiseTexture.wrapT = THREE.RepeatWrapping;
    noiseTexture.minFilter = THREE.LinearFilter;
    noiseTexture.magFilter = THREE.LinearFilter;
    noiseTexture.colorSpace = THREE.NoColorSpace;

    const width = renderer.domElement.width;
    const height = renderer.domElement.height;

    const passA = new ShaderPass(fragA, width, height);
    const passB = new ShaderPass(fragB, width, height);
    const passC = new ShaderPass(fragC, width, height);
    const passD = new ShaderPass(fragD, width, height);
    const mainTarget = createRenderTarget(width, height);

    const mainMaterial = new THREE.RawShaderMaterial({
        vertexShader: `in vec3 position;
in vec2 uv;
out vec2 vUv;
void main() {
		vUv = uv;
		gl_Position = vec4(position, 1.0);
}
`,
        fragmentShader: buildFragmentShader(fragMain),
        uniforms: createUniforms(),
        glslVersion: THREE.GLSL3,
    });

    const resolution = new THREE.Vector3(width, height, 1);

    const presentMaterial = new THREE.RawShaderMaterial({
        vertexShader: `in vec3 position;
in vec2 uv;
out vec2 vUv;
void main() {
	vUv = uv;
	gl_Position = vec4(position, 1.0);
}
`,
        fragmentShader: `precision highp float;
uniform sampler2D tMap;
in vec2 vUv;
out vec4 fragColor;
void main() {
    vec4 col = texture(tMap, vUv);
    fragColor = vec4(col.rgb, 1.0);
}
`,
        uniforms: {
            tMap: { value: null },
        },
        glslVersion: THREE.GLSL3,
    });

    function resize() {
        renderer.setSize(window.innerWidth, window.innerHeight);
        const w = renderer.domElement.width;
        const h = renderer.domElement.height;
        resolution.set(w, h, 1);
        passA.resize(w, h);
        passB.resize(w, h);
        passC.resize(w, h);
        passD.resize(w, h);
        mainTarget.setSize(w, h);
    }

    window.addEventListener("resize", resize);

    function renderFrame() {
        const time = clock.getElapsedTime();

        updateCommonUniforms(passA, time, frame, resolution);
        setChannel(passA.material.uniforms, 0, passA.texture, passA.size);
        setChannel(passA.material.uniforms, 1, passC.texture, passC.size);
        setChannel(passA.material.uniforms, 2, passD.texture, passD.size);
        setChannel(passA.material.uniforms, 3, noiseTexture);
        passA.render();

        updateCommonUniforms(passB, time, frame, resolution);
        setChannel(passB.material.uniforms, 0, passA.texture, passA.size);
        setChannel(passB.material.uniforms, 1, null);
        setChannel(passB.material.uniforms, 2, null);
        setChannel(passB.material.uniforms, 3, null);
        passB.render();

        updateCommonUniforms(passC, time, frame, resolution);
        setChannel(passC.material.uniforms, 0, passB.texture, passB.size);
        setChannel(passC.material.uniforms, 1, null);
        setChannel(passC.material.uniforms, 2, null);
        setChannel(passC.material.uniforms, 3, null);
        passC.render();

        updateCommonUniforms(passD, time, frame, resolution);
        setChannel(passD.material.uniforms, 0, passA.texture, passA.size);
        setChannel(passD.material.uniforms, 1, null);
        setChannel(passD.material.uniforms, 2, null);
        setChannel(passD.material.uniforms, 3, null);
        passD.render(null, true);

        updateCommonUniforms({ material: mainMaterial }, time, frame, resolution);
        setChannel(mainMaterial.uniforms, 0, passA.texture, passA.size);
        setChannel(mainMaterial.uniforms, 1, null);
        setChannel(mainMaterial.uniforms, 2, passC.texture, passC.size);
        setChannel(mainMaterial.uniforms, 3, noiseTexture);

        quad.material = mainMaterial;
        renderer.setRenderTarget(mainTarget);
        renderer.render(scene, camera);
        renderer.setRenderTarget(null);

        const outputTexture =
            debugMode === 0
                ? mainTarget.texture
                : debugMode === 1
                    ? passA.texture
                    : debugMode === 2
                        ? passB.texture
                        : debugMode === 3
                            ? passC.texture
                            : debugMode === 4
                                ? passD.texture
                                : noiseTexture;

        presentMaterial.uniforms.tMap.value = outputTexture;
        quad.material = presentMaterial;
        renderer.render(scene, camera);

        frame += 1;
        requestAnimationFrame(renderFrame);
    }

    resize();
    renderFrame();
}

init().catch((error) => {
    console.error(error);
});
