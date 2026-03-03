class_name ChapterData
extends Resource

## チャプター識別子
@export var chapter_id: String = ""

## 表示名
@export var chapter_name: String = ""

## イントロ用テキスト
@export var location_text: String = ""
@export var date_text: String = "2026/02/24  23:47"

## ステージシーンパス
@export_file("*.tscn") var stage_scene_path: String = ""

## プレイヤースポーン位置
@export var player_spawn: Vector3 = Vector3(0, 1, 15)

## ゴースト設定
@export var ghost_configs: Array[Resource] = []

## アイテム配置
@export var item_positions: PackedVector3Array = []

## 出口位置
@export var exit_position: Vector3 = Vector3(23, 1.5, 15)

## エリアライト
@export var lights: Array[Resource] = []

## 環境設定
@export var ambient_light_energy: float = 0.0
@export var directional_light_energy: float = 0.0
@export var background_color: Color = Color(0.3, 0.35, 0.5, 1)
@export var fog_enabled: bool = false
@export var fog_density: float = 0.01

## Forward Plus 演出（ホラー環境）
@export var use_sky_background: bool = false
@export var sky_top_color: Color = Color(0, 0, 0, 1)
@export var sky_horizon_color: Color = Color(0.05, 0.05, 0.05, 1)
@export var ambient_light_color: Color = Color(0, 0, 0, 1)
@export var tonemap_mode: int = 0
@export var ssao_enabled: bool = false
@export var ssil_enabled: bool = false
@export var sdfgi_enabled: bool = false
@export var fog_light_color: Color = Color(0.5, 0.6, 0.7, 1)
@export var fog_aerial_perspective: float = 0.0
@export var volumetric_fog_enabled: bool = false
@export var volumetric_fog_density: float = 0.0
@export var vhs_overlay: bool = false

## 配信者のモノローグ
@export var monologue_lines: PackedStringArray = []

## 次のチャプターID（空 = 最終チャプター）
@export var next_chapter_id: String = ""
