//! Unflatten Studio 的虚拟相机配方模型与确定性解析器。

use serde::{Deserialize, Serialize};
use thiserror::Error;

pub const CAMERA_SCHEMA_V1: &str = "unflatten-camera/v1";

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CameraRecipe {
    pub schema: String,
    pub id: String,
    pub name: String,
    pub description: String,
    pub pack: CameraPack,
    pub seed: u64,
    #[serde(default)]
    pub tags: Vec<String>,
    pub body: BodyProfile,
    pub lens: LensProfile,
    pub medium: MediumProfile,
    pub capture: CaptureProfile,
    pub condition: ConditionProfile,
    #[serde(default)]
    pub protect: Vec<SemanticRegion>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum CameraPack {
    Analog,
    Y2kDigicam,
    Optical,
    MobileEras,
    Custom,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BodyProfile {
    pub profile: String,
    pub dynamic_range: f32,
    pub highlight_rolloff: f32,
    pub base_noise: f32,
    pub saturation_bias: f32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LensProfile {
    pub profile: String,
    pub focal_length_mm: f32,
    pub distortion: f32,
    pub edge_softness: f32,
    pub chromatic_aberration: f32,
    pub vignette: f32,
    pub bloom: f32,
    pub halation: f32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediumProfile {
    pub profile: String,
    pub grain: f32,
    pub color_noise: f32,
    pub contrast: f32,
    pub saturation: f32,
    pub warmth: f32,
    pub shadow_tint: ColorVector,
    pub highlight_tint: ColorVector,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CaptureProfile {
    pub exposure_bias: f32,
    pub white_balance: f32,
    pub flash_strength: f32,
    pub flash_falloff: f32,
    pub underexposure: f32,
    pub timestamp: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConditionProfile {
    pub dust: f32,
    pub scratches: f32,
    pub light_leak: f32,
    pub dead_pixels: u16,
    pub compression: f32,
    pub wear: f32,
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct ColorVector {
    pub red: f32,
    pub green: f32,
    pub blue: f32,
}

impl ColorVector {
    pub const NEUTRAL: Self = Self {
        red: 0.0,
        green: 0.0,
        blue: 0.0,
    };
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SemanticRegion {
    Person,
    Skin,
    Sky,
    Text,
    Logo,
    Product,
    Background,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ResolvedCamera {
    pub recipe: CameraRecipe,
    pub signature: DefectSignature,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DefectSignature {
    pub grain_seed: u64,
    pub dust_seed: u64,
    pub dead_pixel_seed: u64,
    pub light_leak_angle: f32,
    pub light_leak_origin_x: f32,
    pub light_leak_origin_y: f32,
    pub chroma_offset_x: f32,
    pub chroma_offset_y: f32,
}

#[derive(Debug, Error, PartialEq)]
pub enum RecipeError {
    #[error("不支持的相机配方 Schema：{0}")]
    UnsupportedSchema(String),
    #[error("相机配方 ID 必须使用小写字母、数字和连字符")]
    InvalidId,
    #[error("相机配方名称不能为空")]
    EmptyName,
    #[error("参数 {field} 超出允许范围 {min}..={max}，当前值为 {value}")]
    OutOfRange {
        field: &'static str,
        min: f32,
        max: f32,
        value: f32,
    },
    #[error("参数 deadPixels 超出允许范围 0..=4096，当前值为 {0}")]
    TooManyDeadPixels(u16),
    #[error("相机配方 JSON 无法解析：{0}")]
    InvalidJson(String),
}

impl CameraRecipe {
    pub fn from_json(json: &str) -> Result<Self, RecipeError> {
        let recipe: Self = serde_json::from_str(json)
            .map_err(|error| RecipeError::InvalidJson(error.to_string()))?;
        recipe.validate()?;
        Ok(recipe)
    }

    pub fn to_pretty_json(&self) -> Result<String, RecipeError> {
        self.validate()?;
        serde_json::to_string_pretty(self)
            .map_err(|error| RecipeError::InvalidJson(error.to_string()))
    }

    pub fn validate(&self) -> Result<(), RecipeError> {
        if self.schema != CAMERA_SCHEMA_V1 {
            return Err(RecipeError::UnsupportedSchema(self.schema.clone()));
        }
        if self.name.trim().is_empty() {
            return Err(RecipeError::EmptyName);
        }
        if !is_valid_recipe_id(&self.id) {
            return Err(RecipeError::InvalidId);
        }

        validate_unit("body.dynamicRange", self.body.dynamic_range)?;
        validate_unit("body.highlightRolloff", self.body.highlight_rolloff)?;
        validate_unit("body.baseNoise", self.body.base_noise)?;
        validate_signed_unit("body.saturationBias", self.body.saturation_bias)?;

        validate_range("lens.focalLengthMm", self.lens.focal_length_mm, 1.0, 500.0)?;
        validate_signed_unit("lens.distortion", self.lens.distortion)?;
        validate_unit("lens.edgeSoftness", self.lens.edge_softness)?;
        validate_unit("lens.chromaticAberration", self.lens.chromatic_aberration)?;
        validate_unit("lens.vignette", self.lens.vignette)?;
        validate_unit("lens.bloom", self.lens.bloom)?;
        validate_unit("lens.halation", self.lens.halation)?;

        validate_unit("medium.grain", self.medium.grain)?;
        validate_unit("medium.colorNoise", self.medium.color_noise)?;
        validate_signed_unit("medium.contrast", self.medium.contrast)?;
        validate_signed_unit("medium.saturation", self.medium.saturation)?;
        validate_signed_unit("medium.warmth", self.medium.warmth)?;
        validate_color("medium.shadowTint", self.medium.shadow_tint)?;
        validate_color("medium.highlightTint", self.medium.highlight_tint)?;

        validate_range(
            "capture.exposureBias",
            self.capture.exposure_bias,
            -3.0,
            3.0,
        )?;
        validate_signed_unit("capture.whiteBalance", self.capture.white_balance)?;
        validate_unit("capture.flashStrength", self.capture.flash_strength)?;
        validate_unit("capture.flashFalloff", self.capture.flash_falloff)?;
        validate_unit("capture.underexposure", self.capture.underexposure)?;

        validate_unit("condition.dust", self.condition.dust)?;
        validate_unit("condition.scratches", self.condition.scratches)?;
        validate_unit("condition.lightLeak", self.condition.light_leak)?;
        validate_unit("condition.compression", self.condition.compression)?;
        validate_unit("condition.wear", self.condition.wear)?;
        if self.condition.dead_pixels > 4096 {
            return Err(RecipeError::TooManyDeadPixels(self.condition.dead_pixels));
        }

        Ok(())
    }

    pub fn resolve(&self) -> Result<ResolvedCamera, RecipeError> {
        self.validate()?;
        let mut random = SplitMix64::new(self.seed ^ stable_hash(&self.id));
        let signature = DefectSignature {
            grain_seed: random.next_u64(),
            dust_seed: random.next_u64(),
            dead_pixel_seed: random.next_u64(),
            light_leak_angle: random.next_unit_f32() * 360.0,
            light_leak_origin_x: random.next_unit_f32(),
            light_leak_origin_y: random.next_unit_f32(),
            chroma_offset_x: random.next_signed_f32(),
            chroma_offset_y: random.next_signed_f32(),
        };
        Ok(ResolvedCamera {
            recipe: self.clone(),
            signature,
        })
    }
}

fn is_valid_recipe_id(id: &str) -> bool {
    !id.is_empty()
        && !id.starts_with('-')
        && !id.ends_with('-')
        && id
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-')
}

fn validate_unit(field: &'static str, value: f32) -> Result<(), RecipeError> {
    validate_range(field, value, 0.0, 1.0)
}

fn validate_signed_unit(field: &'static str, value: f32) -> Result<(), RecipeError> {
    validate_range(field, value, -1.0, 1.0)
}

fn validate_color(field: &'static str, color: ColorVector) -> Result<(), RecipeError> {
    validate_signed_unit(field, color.red)?;
    validate_signed_unit(field, color.green)?;
    validate_signed_unit(field, color.blue)
}

fn validate_range(field: &'static str, value: f32, min: f32, max: f32) -> Result<(), RecipeError> {
    if value.is_finite() && (min..=max).contains(&value) {
        Ok(())
    } else {
        Err(RecipeError::OutOfRange {
            field,
            min,
            max,
            value,
        })
    }
}

fn stable_hash(value: &str) -> u64 {
    value.bytes().fold(0xcbf29ce484222325, |hash, byte| {
        (hash ^ u64::from(byte)).wrapping_mul(0x100000001b3)
    })
}

struct SplitMix64 {
    state: u64,
}

impl SplitMix64 {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next_u64(&mut self) -> u64 {
        self.state = self.state.wrapping_add(0x9e3779b97f4a7c15);
        let mut value = self.state;
        value = (value ^ (value >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
        value = (value ^ (value >> 27)).wrapping_mul(0x94d049bb133111eb);
        value ^ (value >> 31)
    }

    fn next_unit_f32(&mut self) -> f32 {
        let value = self.next_u64() >> 40;
        value as f32 / 16_777_215.0
    }

    fn next_signed_f32(&mut self) -> f32 {
        self.next_unit_f32() * 2.0 - 1.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_recipe() -> CameraRecipe {
        CameraRecipe {
            schema: CAMERA_SCHEMA_V1.to_owned(),
            id: "y2k-night-party".to_owned(),
            name: "Y2K Night Party".to_owned(),
            description: "正面直闪与早期 CCD 夜景。".to_owned(),
            pack: CameraPack::Y2kDigicam,
            seed: 2048,
            tags: vec!["ccd".to_owned(), "flash".to_owned()],
            body: BodyProfile {
                profile: "compact-ccd-2003".to_owned(),
                dynamic_range: 0.38,
                highlight_rolloff: 0.18,
                base_noise: 0.14,
                saturation_bias: 0.12,
            },
            lens: LensProfile {
                profile: "compact-wide".to_owned(),
                focal_length_mm: 32.0,
                distortion: 0.08,
                edge_softness: 0.16,
                chromatic_aberration: 0.12,
                vignette: 0.09,
                bloom: 0.11,
                halation: 0.02,
            },
            medium: MediumProfile {
                profile: "early-digital".to_owned(),
                grain: 0.04,
                color_noise: 0.16,
                contrast: 0.12,
                saturation: 0.14,
                warmth: -0.08,
                shadow_tint: ColorVector {
                    red: -0.08,
                    green: 0.01,
                    blue: 0.12,
                },
                highlight_tint: ColorVector::NEUTRAL,
            },
            capture: CaptureProfile {
                exposure_bias: 0.3,
                white_balance: -0.08,
                flash_strength: 0.72,
                flash_falloff: 0.68,
                underexposure: 0.31,
                timestamp: false,
            },
            condition: ConditionProfile {
                dust: 0.02,
                scratches: 0.0,
                light_leak: 0.0,
                dead_pixels: 2,
                compression: 0.07,
                wear: 0.12,
            },
            protect: vec![SemanticRegion::Skin, SemanticRegion::Text],
        }
    }

    #[test]
    fn valid_recipe_round_trips_json() {
        let recipe = sample_recipe();
        let json = recipe.to_pretty_json().expect("配方应该能够序列化");
        let decoded = CameraRecipe::from_json(&json).expect("配方应该能够反序列化");
        assert_eq!(decoded, recipe);
    }

    #[test]
    fn rejects_values_outside_declared_range() {
        let mut recipe = sample_recipe();
        recipe.lens.vignette = 1.2;
        assert!(matches!(
            recipe.validate(),
            Err(RecipeError::OutOfRange {
                field: "lens.vignette",
                ..
            })
        ));
    }

    #[test]
    fn same_seed_produces_same_signature() {
        let recipe = sample_recipe();
        let first = recipe.resolve().expect("配方应该能够解析");
        let second = recipe.resolve().expect("配方应该能够解析");
        assert_eq!(first.signature, second.signature);
    }

    #[test]
    fn seed_change_produces_different_signature() {
        let first = sample_recipe().resolve().expect("配方应该能够解析");
        let mut changed = sample_recipe();
        changed.seed += 1;
        let second = changed.resolve().expect("配方应该能够解析");
        assert_ne!(first.signature, second.signature);
    }
}
