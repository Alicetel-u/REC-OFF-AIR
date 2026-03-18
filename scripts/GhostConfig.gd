class_name GhostConfig
extends Resource

@export var position: Vector3 = Vector3.ZERO
@export var patrol_points: PackedVector3Array = []  # 空 = デフォルト巡回パターン
@export var model_path: String = ""  # 空 = ランダムモデル、指定 = 専用GLB
@export var model_scale: Vector3 = Vector3(0.3, 0.3, 0.3)
@export var forced_motion: int = -1  # -1=ランダム、0以上=MotionPattern固定
@export var forced_state: int = -1   # -1=通常AI、0=PATROL,1=ALERT,2=CHASE,3=CAUGHT
