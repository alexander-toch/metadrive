#version 330

// Number of splits in the PSSM, it must be in line with what is configured in the PSSMCameraRig
const int split_count=2;
uniform  vec3 light_direction;

uniform mat3 p3d_NormalMatrix;

uniform struct {
  sampler2D data_texture;
  sampler2D heightfield;
  int view_index;
  int terrain_size;
  int chunk_size;
} ShaderTerrainMesh;

uniform struct {
  vec4 position;
  vec3 color;
  vec3 attenuation;
  vec3 spotDirection;
  float spotCosCutoff;
  float spotExponent;
  sampler2DShadow shadowMap;
  mat4 shadowViewMatrix;
} p3d_LightSource[1];

uniform struct {
  vec4 ambient;
} p3d_LightModel;

uniform vec3 wspos_camera;

// asset
uniform vec3 crosswalk_semantics;
uniform vec3 lane_line_semantics;
uniform vec3 road_semantics;
uniform vec3 ground_semantics;

uniform sampler2D attribute_tex;

// just learned that uniform means the variable won't change in each stage, while in/out is able to do that : )
uniform float elevation_texture_ratio;
uniform float height_scale;

uniform sampler2D PSSMShadowAtlas;

uniform mat4 pssm_mvps[split_count];
uniform vec2 pssm_nearfar[split_count];
uniform float border_bias;
const float fixed_bias=0;
uniform bool use_pssm;
uniform bool fog;

in vec2 terrain_uv;
in vec3 vtx_pos;
in vec4 projecteds[1];

out vec4 color;


void main() {
    float r_min = (1-1/elevation_texture_ratio)/2;
    float r_max = (1-1/elevation_texture_ratio)/2+1/elevation_texture_ratio;
    vec4 attri;
    attri = texture(attribute_tex, terrain_uv*elevation_texture_ratio+0.5);

    // get the color and terrain normal in world space
    // GROUND = 0.0
    // WHITE_STRIPE = 0.02
    // ROAD = 0.2
    // WHITE = 0.3 # map all semantic colors between 0.21 and 0.29
    // CROSSWALK = 0.4
    // YELLOW = 0.9

    vec3 diffuse;
    float eps = 1.0;
    vec3 black = vec3(0.0, 0.0, 0.0);
    if ((attri.r > 0) && (terrain_uv.x>=r_min) && (terrain_uv.y >= r_min) && (terrain_uv.x<=r_max) && (terrain_uv.y<=r_max)){
        if (abs(attri.r*255 - 1.0) < eps) {
            // white stripe gaps should be visible
            diffuse = lane_line_semantics;
        }  else if (abs(attri.r*255 - 2.0) < eps) {
            // road
            diffuse = black;
        }  else if (abs(attri.r*255 - 4.0) < eps) {
            // white
            diffuse = lane_line_semantics;
        }  else if (abs(attri.r*255 - 6.0) < eps) {
            // yellow
            diffuse=lane_line_semantics;
        } else {
            // Semantics for value 4
            diffuse = black;
        }
    } else {
        diffuse = black;
    }

    color = vec4(diffuse, 1.0);
}