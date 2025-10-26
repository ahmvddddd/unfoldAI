# Tradeoffs

## Trade-offs in Downsampling and Performance Optimization

This document explains the trade-offs made while implementing data decimation strategies in UnfoldAI.

## 1. Largest Triangle Three Buckets (LTTB)

### Pros

. Preserves visual trends of data.

. Computationally efficient (O(n)).

. Maintains key visual points (peaks and valleys).

### Cons

. Slightly complex implementation.

. May not capture micro-trends within very dense buckets.

## 2. Bucket Mean

### Pros

. Simple to implement and understand.

. Suitable for uniformly distributed data.

### Cons

. Averages may blur sharp changes.

. Does not guarantee preservation of significant peaks.

## 3. Random Sampling

### Pros

. Fastest method.

. Suitable for quick approximations.

### Cons

. Poor accuracy; high risk of losing trend fidelity.

## 4. Final Choice: LTTB

LTTB was selected for its balance between speed and visual accuracy.
It ensures each frame renders within 16 ms, even for datasets exceeding 10,000 points, without noticeable visual degradation.
