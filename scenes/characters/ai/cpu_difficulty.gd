class_name CpuDifficulty
extends Resource
## Decision settings only: all difficulties share the player's movement speed.

## Seconds between observations of the target.
@export_range(0.02, 2.0, 0.01, "suffix:s") var decision_interval: float = 0.25
## Maximum look-ahead time. Zero means seek without prediction.
@export_range(0.0, 1.0, 0.01, "suffix:s") var prediction_time: float = 0.2
## Maximum displacement of the estimated destination.
@export_range(0.0, 32.0, 0.5, "suffix:px") var target_error: float = 4.0
