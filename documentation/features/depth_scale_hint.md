# Depth Scale Hint

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre can pass depth-derived scale facts and, optionally, a rendered depth image with a meal photo to the configured AI provider. These are inputs for an estimate; the app does not calculate food mass or identify ingredients from depth.

## Capture and availability

The depth capture uses the iOS camera session. The native camera selection prefers LiDAR, then supported multi-camera devices, then the wide camera; devices without depth delivery continue with ordinary photo capture. Android does not provide this depth capture path. A depth map may also be available from a non-LiDAR iOS camera, but relative-accuracy data does not pass the scale-facts quality gate.

The app receives a Float32 depth buffer in metres, the depth-map dimensions, the sensor accuracy mode, and camera intrinsics when available. It derives scale facts only when those inputs are present. The buffer is used in memory for facts and rendering; the meal record stores the derived facts, not the raw buffer.

## Scale facts and quality gate

`DepthScaleCalculator` accepts finite depth values greater than 0.05 m and less than 5 m. It computes the valid-sample share across the frame. Subject distance is the median of valid samples in the central third of the depth map (falling back to all valid samples if that region has none); near and far values are the 5th and 95th percentile of valid samples. Frame width and height are estimated from that median distance and the camera intrinsics.

The facts are marked valid only when the central subject distance is 15–120 cm inclusive, at least half of the frame’s samples are valid, and the sensor reports absolute accuracy. This is an input filter, not a measurement-accuracy guarantee. Invalid facts are omitted from the scale prompt. The optional depth image has a separate setting and is not gated by `DepthScaleFacts.isValid`, so a rendered map can still be attached when depth values exist even if scale facts fail the gate.

## What is sent to the provider

When enabled and valid, the scale facts add rounded distance, frame dimensions, and near/far distances to the system prompt. The prompt asks the model to use those values when estimating portion size. When the depth-image setting is enabled and rendering succeeds, the app adds a second image after the meal photos, with a legend describing the rendered camera-distance bands. The depth image is a visualization of distance from the camera, not height above a detected plate or table plane. Neither facts nor image segment the scene into foods, identify ingredients, or directly yield portion mass or volume.

The initial image-analysis request may include the scale facts and optional depth image. A validation repair request can include valid scale facts, but the repair path does not attach the depth image. Both the meal photo and any optional depth image are sent through the currently selected AI provider; the raw depth buffer is not part of that request. See [BYOK AI Meal Capture & Validation](byok_ai_validation.md) for provider behavior and [Meal Capture Pipeline](meal_capture_pipeline.md) for the surrounding capture flow.

## Rendered depth image

`DepthMapRenderer` maps usable distances to a default 40-band Viridis palette; invalid pixels are gray. It uses the 2nd–98th percentile range when at least 32 usable depth samples exist. If that range is narrower than 4 cm it expands it to 4 cm. When fewer than 32 usable samples prevent an automatic range, it falls back to 0–80 cm. Distances outside the selected range are clamped to the end bands. These choices affect only the visualization, not the scale facts.

The image is created on demand for review or analysis. If rendering or PNG encoding fails, the photo analysis can continue without it. Forty color bands are a display choice and do not establish corresponding physical precision.

## User controls

The two switches appear in AI settings when AI is enabled and the iOS camera reports depth delivery support. Both default to on and are stored in local shared preferences.

| Setting | Effect |
|---|---|
| `depth_scan_scale_hint_enabled` | Include valid scale facts in the prompt. |
| `depth_scan_depth_image_enabled` | Render and allow the depth image as an additional provider image. |

The controls are independent. Turning off scale facts does not itself disable depth-image rendering or attachment, and turning off the depth image does not itself suppress valid scale facts.

## Persistence and telemetry

When a meal is saved, available scale facts are serialized into the meal entry’s `captureMeta` JSON. The raw depth buffer and rendered depth image are not stored in that metadata. The depth capture and the user opening the depth visualization call `feature_used` telemetry with the feature keys `lidar_depth_captured` and `lidar_depth_visualized`; those calls add no depth measurements or image data. PostHog transmission is gated by telemetry opt-in, and telemetry can also be disabled at build time. See [TELEMETRY.md](../../TELEMETRY.md).

The scale facts and rendered image can be shared with the configured AI provider as described above. The repository does not establish that depth improves estimate accuracy, and it does not provide a validated food-mass accuracy range. Treat the result as an AI-assisted estimate that should be reviewed before saving.
