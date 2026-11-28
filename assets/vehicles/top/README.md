# Top-view vehicle artwork

These original raster assets were generated for DashCore using the user's visual references. They are stylized illustrations, not manufacturer CAD or certified dimensional models.

Flutter decodes the active image at 320 px on devices in low-resource mode and 512 px otherwise. The vehicle paint shader changes red body panels while retaining glass, chrome, and rear lenses. Front and rear lighting use the same local shader plus small lens strokes; they do not require a WebView, GLB, continuous timer, or network request. Lights repaint during their short scheduled transition, and the schedule waits for the next boundary while the app is visible.

The generic car is the fallback for unidentified models. The old `nissan_h1` catalog asset depicts a Hyundai H1; the local display name now reflects the H1 model.
