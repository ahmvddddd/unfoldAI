# UnfoldAI

**UnfoldAI** is a Flutter-based web application that visualizes biometric data such as Heart Rate Variability (HRV), Resting Heart Rate (RHR), and Steps through interactive charts.
It demonstrates responsive visualization, dynamic range selection, and high-performance rendering for large datasets using downsampling techniques such as Largest Triangle Three Buckets (LTTB).

---

## Live link

[unfoldAI](https://ahmvddddd.github.io/unfoldAI/)

---

## Visual Demo

A simple videoram of how the app works:

<img src="assets/demo.mp4" alt="Demo" width="520" height="800"/>

---

## Overview

The application provides:

. Interactive biometric charts with tooltips, annotations, and synced axes.
. Range filtering (7, 30, and 90 days).
.Large dataset toggle to simulate high-volume data (>10,000 points).
. State management with Riverpod.
. Loading skeletons, error views, and retry handling.
. Responsive layout, optimized for 375px width and above.
. Smooth chart performance (<16 ms per frame) via data decimation (LTTB).

---

## Data Flow

biometrics_controller.dart loads or simulates data for each biometric metric.
charts_controller.dart applies LTTB downsampling for large datasets, ensuring efficient rendering.
dashboard_page.dart observes the controller’s state and renders multiple BiometricsChart widgets, each linked to a specific biometric metric.

---

## Setup & Run

### Prerequisites

Flutter SDK 3.22+

Dart 3+

Chrome or Edge browser (for Flutter Web)

## Installation

```
git clone https://github.com/ahmvddddd/unfoldAI.git
cd unfoldAI
flutter pub get
flutter run -d chrome
```

## Testing

Run all tests:

```
flutter test
```

## Libraries & Tools

flutter_riverpod — reactive state management

fl_chart — interactive and animated data visualization

skeletonizer — loading skeletons for placeholder views

LTTB algorithm — used to downsample large datasets while preserving trends

## Performance Notes

When rendering large datasets (10k+ points), downsampling reduces the number of drawn points to maintain smooth UI updates (<16 ms per frame).
The app dynamically applies LTTB to ensure performance without compromising data integrity or user experience.

Trade-offs and Decimation Strategy

To review the discussion on performance optimization and trade-offs made between different downsampling techniques (LTTB, bucket mean, and others), see:
➡ [tradeoffs.md](tradeoffs.md)


