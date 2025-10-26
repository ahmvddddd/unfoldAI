# UnfoldAI (Flutter Web/Mobile)

**Live demo:** [unfoldAI](https://ahmvddddd.github.io/unfoldAI/)

**Video (≤2 min):** [Demo Video](assets/demo.mp4) 

**Repo:** [Repo](https://github.com/ahmvddddd/unfoldAI/)

## What it does
- 3 synced charts: HRV, RHR, Steps  
- Shared crosshair + 7d/30d/90d range toggle  
- Journal annotations (tap to view mood/note)  
- HRV band (7-day mean ± 1σ)  
- Latency (700–1200 ms) + ~10% random load failures + Retry  
- Decimation for 30/90 days + dark mode  

## How to run
```bash
flutter pub get
flutter run -d chrome
# or build for web:
flutter build web && serve from /build/web

```

## Data loading

Injects 700–1200 ms latency and ~10% random load failures.

Libraries (+ why)

Syncfusion Charts (web pan/zoom/trackball), Riverpod (state), Skeletonizer (loading).

## Architecture

Models → Services/Loader → Controllers (providers) → Screens/Widgets.

## Performance note

Bucket-mean decimation for 30/90-day ranges keeps frames under 16 ms.
Preserves min/max in unit tests.

## Known limits

Trackball API varies by Syncfusion version.
Mobile FPS depends on device; a11y not added yet.

---
