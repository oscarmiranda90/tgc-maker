vec4 spinning_camera(float t)
{
    return vec4(2.0 * sin(t), -0.5, -2.0 * cos(t), 1.5);
}

vec4 fixed_camera()
{
    return vec4(0.0, -13.0 / 3.5, -17.5 / 3.5, 4.0);
}


vec4 mouse_camera()
{
    vec2 m = vec2(0.5);
    if (iMouse.z > 0.0)
    {
        m = iMouse.xy / iResolution.xy;
    }
    
	float ax = -m.x * 3.14 * 2.0  + 3.14 / 2.0;
	float ay = -m.y * 3.14;
    return vec4(2.0 * cos(ax), 2.0 * cos(ay), 2.0 * sin(ax), 1.5);
}

vec4 camera()
{
    //return fixed_camera();
    return mouse_camera();
}

vec3 fixed_light()
{
    return vec3(0.0, 0.0, -64.5 / 3.5);
}

vec3 spinning_light(float t)
{
    return vec3(64.5 / 3.5 * sin(t), 1.0, -64.5 / 3.5 * cos(t));
}

vec3 spinning_light_2(float t)
{
    return vec3(10.5 * sin(t), -10.5 * cos(t), -10.5);
}

vec3 light()
{
    //return spinning_light(iTime);
    return spinning_light_2(iTime / 2.0);
    return fixed_light();
}


vec2 hash2( vec2 p )
{
    // procedural white noise	
    vec2 q = vec2(dot(p,vec2(127.1,311.7)),
                  dot(p,vec2(269.5,183.3)) );
	return fract(vec2(sin(q)*43758.5453));
}

vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
				   dot(p,vec2(269.5,183.3)), 
				   dot(p,vec2(419.2,371.9)) );
	return fract(sin(q)*43758.5453);
}

vec4 hash4( vec2 p )
{
    vec4 q = vec4( dot(p,vec2(127.1,311.7)), 
				   dot(p,vec2(269.5,183.3)), 
				   dot(p,vec2(419.2,371.9)), 
				   dot(p,vec2(832.3,201.5)) );
	return fract(sin(q)*43758.5453);
}

//https://iquilezles.org/articles/voronoise
float voronoise( in vec2 p, float u, float v )
{
	float k = 1.0+63.0*pow(1.0-v,6.0);

    vec2 i = floor(p);
    vec2 f = fract(p);
    
	vec2 a = vec2(0.0,0.0);
    for( int y=-2; y<=2; y++ )
    for( int x=-2; x<=2; x++ )
    {
        vec2  g = vec2( x, y );
		vec3  o = hash3( i + g )*vec3(u,u,1.0);
		vec2  d = g - f + o.xy;
		float w = pow( 1.0-smoothstep(0.0,1.414,length(d)), k );
		a += vec2(o.z*w,w);
    }
	
    return max(a.x/a.y, 0.0);
}

//https://iquilezles.org/articles/voronoilines/
vec2 voronoi(vec2 p)
{
    vec2 ip = floor(p);
    vec2 fp = fract(p);

	vec2 mg, mr;

    float md = 8.0;
    vec2 mz = vec2(0.0);
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
		vec4 o = hash4(ip + g);//*vec3(u,u,1.0);
        vec2 r = g + vec2(o) - fp;
        float d = dot(r,r);

        if(d < md)
        {
            md = d;
            mr = r;
            mg = g;
            mz = o.zw;
        }
    }

    return mz;
}


//https://stackoverflow.com/questions/3407942/rgb-values-of-visible-spectrum
vec3 spectral_spektre(float l)
{
    l = 400.0 + l * 300.0;
    float r=0.0,g=0.0,b=0.0;
         if ((l>=400.0)&&(l<410.0)) { float t=(l-400.0)/(410.0-400.0); r=    +(0.33*t)-(0.20*t*t); }
    else if ((l>=410.0)&&(l<475.0)) { float t=(l-410.0)/(475.0-410.0); r=0.14         -(0.13*t*t); }
    else if ((l>=545.0)&&(l<595.0)) { float t=(l-545.0)/(595.0-545.0); r=    +(1.98*t)-(     t*t); }
    else if ((l>=595.0)&&(l<650.0)) { float t=(l-595.0)/(650.0-595.0); r=0.98+(0.06*t)-(0.40*t*t); }
    else if ((l>=650.0)&&(l<700.0)) { float t=(l-650.0)/(700.0-650.0); r=0.65-(0.84*t)+(0.20*t*t); }
         if ((l>=415.0)&&(l<475.0)) { float t=(l-415.0)/(475.0-415.0); g=             +(0.80*t*t); }
    else if ((l>=475.0)&&(l<590.0)) { float t=(l-475.0)/(590.0-475.0); g=0.8 +(0.76*t)-(0.80*t*t); }
    else if ((l>=585.0)&&(l<639.0)) { float t=(l-585.0)/(639.0-585.0); g=0.82-(0.80*t)           ; }
         if ((l>=400.0)&&(l<475.0)) { float t=(l-400.0)/(475.0-400.0); b=    +(2.20*t)-(1.50*t*t); }
    else if ((l>=475.0)&&(l<560.0)) { float t=(l-475.0)/(560.0-475.0); b=0.7 -(     t)+(0.30*t*t); }
    return vec3(r,g,b);
}

//https://www.alanzucconi.com/2017/07/15/improving-the-rainbow/
vec3 spectral_gems(float w)
{
    return vec3
    (       
        max(1.0 - pow(4.0 * (w - 0.75), 2.0), 0.0),
        max(1.0 - pow(4.0 * (w - 0.5), 2.0), 0.0),
        max(1.0 - pow(4.0 * (w - 0.25), 2.0), 0.0)
    );
}

vec3 voronoi_normal(vec2 uv, vec3 normal, vec3 forward)
{
    //float noise = voronoise(uv * 20.0, 0.0, 0.0);
    vec2 noise = voronoi(uv * 20.0);
    //vec2 white_noise = hash2(uv);
    //vec2 noise = white_noise * 1.0;//voronoi_noise * 0.995 + white_noise * 0.005;
    //noise.x = voronoise(uv * 120.0 * vec2(4.0, 1.0), 0.0, 1.0);
    //noise.y = voronoise(uv * 120.0 * vec2(4.0, 1.0), 0.0, 1.0);
    
    float theta = noise.x * 2.0 * 3.14;
    float phi = acos(1.0 - noise.y * 0.00125);

    vec3 k = cross(normal, normalize(forward));
    vec3 v = normal;

    vec3 a = normal * cos(phi) + cross(k, v) * sin(phi) + k * dot(k, v) * (1.0 - cos(phi));
    vec3 b = dot(a, normal)*normal;
    vec3 o = a - b;
    vec3 w = cross(normal, o);
    vec3 th = length(o)*(cos(theta)*normalize(o)+sin(theta)*normalize(w));
    return b + th;
}

vec3 bump_normal(vec2 uv, vec3 normal, vec3 forward)
{
    float delta = 0.001;
    float delta_h = 0.00003;
    vec2 noise = hash2(uv);
    float p = voronoise(uv * 120.0 * vec2(4.0, 1.0), 0.0, 1.0) * delta_h;
    float x = voronoise((uv + vec2(delta, 0.0)) * 120.0 * vec2(4.0, 1.0), 0.0, 1.0) * delta_h;
    float y = voronoise((uv + vec2(0.0, delta)) * 120.0 * vec2(4.0, 1.0), 0.0, 1.0) * delta_h;
    
    return normalize(cross(vec3(delta, 0.0, x - p), vec3(0.0, delta, y - p)));
}

float draw_point(vec3 ro, vec3 rd, vec3 p)
{
    float d = length(cross(p - ro, rd)) / length(rd);
    d = smoothstep(.03, .01, d);
    return d;
}


vec4 plane_from_basis(vec3 v0, vec3 v1, vec3 v2)
{
    vec3 vc = cross(v2 - v0, v1 - v0);
    return vec4(vc, -dot(vc, v0));
}

vec4 ray_plane_intersect(vec3 ro, vec3 rd, vec4 plane)
{
    float v = dot(vec3(plane), rd);
    float o = dot(vec3(plane), ro);
    float od = -plane.w - o;
    float d = od / v;
    return vec4(ro + d * rd, d);
}

void draw_card(
       out vec3 position, out vec3 normal, out vec3 uv, out vec3 holo_normal, out vec3 color,
       vec3 ro, vec3 rd, vec3 p, vec3 w, vec3 h, float r)
{
    vec3 d0 = normalize(w);
    vec3 d1 = normalize(h);
    
    vec4 plane = plane_from_basis(p, w, h);
    vec4 plane_intersect = ray_plane_intersect(ro, rd, plane);
    
    float u = dot(vec3(plane_intersect) - p, d0);
    u = clamp(u, 0.0, length(w));
    float v = dot(vec3(plane_intersect) - p, d1);
    v = clamp(v, 0.0, length(h));
    
    vec3 projection = p + u * d0 + v * d1;
    color = vec3(smoothstep(r + 0.005, r, length(projection - vec3(plane_intersect))));
    
    uv = vec3(plane_intersect) - p - w / 2.0 - h / 2.0;
    position = vec3(plane_intersect);
    normal = bump_normal(vec2(uv), cross(d0, d1), d0);
    holo_normal = voronoi_normal(vec2(uv), cross(d0, d1), d0);
}

vec3 light(
    vec3 light_pos,
    vec3 light_color,
    vec3 object_color,
    vec3 object_position,
    vec3 object_normal,
    vec3 object_width,
    vec3 object_height,
    vec3 object_uv,
    vec3 holo_normal,
    vec3 ro,
    vec3 rd)
{
    float ambient_c = 0.0;
    vec3 ambient = ambient_c * light_color;
    
    float diffuse_c = 0.1;
    vec3 light_dir = normalize(light_pos - object_position);
    float diff = max(dot(object_normal, light_dir), 0.0);
    vec3 diffuse = diffuse_c * diff * light_color;
    
    float specular_c = 1.0;
    vec3 reflect_dir = reflect(-light_dir, object_normal);
    float spec = pow(clamp(dot(-normalize(rd), reflect_dir), 0.0, 1.0), 512.0);
    vec3 specular = specular_c * spec * light_color;

    vec3 n1 = holo_normal * 0.8;
    vec3 n2 = object_normal * 0.2;
    vec3 n = normalize(vec3((n1.x + n2.x) * 2.0, (n1.y + n2.y) * 2.0, holo_normal.z * 1.0));
    
    float a = dot(n, ro);
    float b = dot(n, light_pos);
    float t = a / (a + b);
    vec3 s = (1.0 - t) * (ro - n * a) + t * (light_pos - n * b);
    vec3 disp = object_position - s;
    
    float angle = atan(disp.y, disp.x);
    
    float spectrum = pow(max(dot(-normalize(rd), reflect(-light_dir, n)), 0.0), 2.0);
    float corner = (1.0 + cos(4.0 * angle + 3.14)) / 2.0;
    spectrum = (spectrum + corner * 0.42) * (1.0 - corner * 0.29);
    
    float holo_a = 0.55;
    float holo_b = 0.20;
    float holo_c = 0.2;
    float holo_d = 0.825;
    vec3 holo = spectral_gems(1.0 - (spectrum - holo_a) / holo_b) * smoothstep(0.0, holo_c, cos(8.0 * angle) - holo_d) * light_color;
    //return vec3(holo_normal.x, holo_normal.y, 0) * object_color;
    return (ambient + diffuse + specular + holo) * object_color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float card_height = 1.0;
    float card_width = 0.66;
    float corner_radius = 0.04;
    
    vec4 cam = camera();
    
    vec3 ro = vec3(cam);
    vec3 lookat = vec3(0.);
    float zoom = cam.w;
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= .5;
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 f = normalize(lookat - ro);
    vec3 r = cross(vec3(0.0, 1.0, 0.0), f);
    vec3 u = cross(f, r);
    
    vec3 c = ro + f * zoom;
    vec3 i = c + uv.x * r + uv.y * u;
    
    vec3 rd = i - ro;

    vec3 p = vec3(0.0 + card_width / 2.0, 0.0 - card_height / 2.0, 0.0);
    vec3 d0 = vec3(-card_width,0.,0.);
    vec3 d1 = vec3(0.0,card_height,0.0);

    vec3 position;
    vec3 normal;
    vec3 card_uv;
    vec3 holo_normal;
    vec3 color;
    draw_card(position, normal, card_uv, holo_normal, color, ro, rd, p, d0, d1, corner_radius);
    
    
    vec3 light_pos = light();
    vec3 light_color = vec3(255.0 / 255.0, 244.0 / 255.0, 229.0 / 255.0);
    
    vec3 out_color = vec3(0.0);
    out_color += light(spinning_light_2(iTime / 2.0), light_color, color, position, normal, d0, d1, card_uv, holo_normal, ro, rd);
    out_color += light(spinning_light_2(iTime / 2.1 + 3.14), light_color, color, position, normal, d0, d1, card_uv, holo_normal, ro, rd);
    out_color += color * light_color * 0.1;
    //color += vec3(draw_point(ro, rd, light()));

    fragColor = vec4(out_color, 0.0);
}