# Depth Scale Hint (LiDAR)

The single largest error in estimating a portion from a photograph is not recognising the food — it is not knowing how big anything is. A plate assumed 1.5× too wide is a portion roughly 3× too large. On devices with a LiDAR sensor, Train Libre removes that unknown by measuring the scene and handing the model a few measured numbers.

This is a **hint to the AI**, not a local computation of what is on the plate.

---

## 1. Explicit Non-Goals

The following are deliberately *not* built, because geometry sees height differences, not ingredients — rice and chicken side by side at the same height are one shape, and a heap of rice with a dent in it is two:

*   No local segmentation or mask generation (neither geometric nor via CoreML/Vision).
*   No plate or plane detection, no clustering of points into ingredients.
*   No local per-ingredient volume calculation.
*   No point cloud in the prompt — it does not work and costs a great many tokens.
*   No bundled model, no training, no new network or cloud dependency beyond the existing BYOK provider.

What *is* done: reading the depth buffer, elementary arithmetic on it (median, percentiles, camera intrinsics), and rendering an image.

---

## 2. Capture

Depth is delivered by the same native `AVCaptureSession` that provides the preview, the barcode stream and the photo (see [Meal Capture Pipeline](meal_capture_pipeline.md)). `DepthScanCapability` reports two independent things: whether the unified session can run at all (false on Android and in tests) and whether a depth map accompanies the photo. Everything below is skipped when depth is unavailable, and no user on a device without LiDAR is told that anything is missing.

The raw depth buffer never leaves the device.

---

## 3. The Scale Facts

`DepthScaleCalculator` reduces a Float32 depth buffer (metres) plus camera intrinsics to five numbers:

| Fact | Definition |
|---|---|
| `subjectDistanceCm` | median distance to the subject, measured over the centre third of the frame |
| `frameWidthCm`, `frameHeightCm` | how much of the world the frame covers at that distance |
| `nearCm`, `farCm` | 5th and 95th percentile distance — nearest and farthest surface |
| `validSampleRatio` | share of usable, non-null depth samples across the frame |

### Quality Gate
A measurement is only used when it is trustworthy. It is discarded when:
*   the subject distance falls outside **15–120 cm**,
*   fewer than **50 %** of samples are valid, or
*   the sensor reports `relative` rather than `absolute` accuracy.

Glass, liquids and reflective surfaces are the typical cause of a rejected measurement. A rejected measurement means the analysis proceeds exactly as it did before LiDAR existed — never with a wrong scale.

---

## 4. What the Model Receives

### The Numbers
When the facts pass the gate, a block is prepended to the system prompt stating the distance, the physical frame size and the near/far range, marked explicitly as *measured, not estimated*, with the instruction to derive plate and portion dimensions from the frame size instead of from assumed cutlery sizes. The same summary is repeated in the repair prompt, so a correction pass cannot silently discard the measurement.

### The Depth Image
Optionally a second image is attached: a false-colour depth map rendered by `DepthMapRenderer`.

*   **Plain distance from the camera**, not height above a reference plane. An earlier version derived a plane from the frame; point the camera at a room and that "reference" lands on a wall metres away, and the picture stops meaning anything.
*   **The ramp is fitted to what the frame actually contains** — the 2nd to 98th percentile of valid readings, with a minimum span of 4 cm and a 0–80 cm fallback when there is too little to measure. A fixed 0–80 cm scale would paint a plate sitting between 24 and 31 cm in a single colour.
*   **40 bands.** Eight was far too coarse: across an 8 cm plate each band covered a full centimetre, and rice heaped in the middle looked the same as rice spread flat. Forty puts the steps at about two millimetres, finer than the sensor's own noise — deliberately, because at that density the image stops reading as bands and becomes a smooth relief, and the dithering along an edge is a fairer picture of an uncertain measurement than a hard line.
*   **Viridis**, sampled from anchor points so the band count can change without hand-picking colours. Missing readings are neutral gray.

A generated legend tells the model what the bands mean in centimetres, together with the instruction that the photo identifies the food while the depth map gives its shape.

The depth image is what distinguishes a heaped portion from a flat one: both cover the same area in a photo.

---

## 5. User Control

Both halves are separately switchable, because they cost different things and their value is a genuinely open question:

| Setting key | Default | Effect |
|---|---|---|
| `depth_scan_scale_hint_enabled` | on | the measured numbers in the prompt |
| `depth_scan_depth_image_enabled` | on | the false-colour depth map as a second image |

The numbers are cheap and certain; the picture costs a second image per analysis. Switching them lets the same meal be photographed twice, with and without, which is the only honest way to judge the effect on real food.

---

## 6. Storage and Telemetry

The scale facts of a capture are persisted in `MealEntries.captureMeta` alongside the provider and model used, so a logged meal records how it was measured. Two telemetry events (`lidar_depth_captured`, `lidar_depth_visualized`) record only *that* a measurement or visualisation happened — see [TELEMETRY.md](../../TELEMETRY.md).

---

## 7. Privacy

The photo already goes to the BYOK provider the user configured. What is added is a handful of centimetre figures and, optionally, an abstract depth image — both carrying less personal information than the photograph itself. The raw depth buffer never leaves the device, and without a configured AI provider nothing is transmitted at all.

---

## 8. Accuracy Expectations

Published laboratory baselines for image-plus-depth food mass estimation sit around 15–25 % error; pure image estimation typically lands at 40–50 %. A scale hint therefore aims to make a rough estimate less rough — it does not make it a measurement. The clinical disclaimer in [BYOK AI Meal Capture & Validation](byok_ai_validation.md) applies unchanged.
