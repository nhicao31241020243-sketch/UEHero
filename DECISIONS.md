# Career Map decisions

- Career Map uses the existing Flutter/Material stack and `SharedPreferences`; no new dependency is required.
- Progress currency is named **Stardust** in UI, while the service stores integer points.
- The central service is `ProgressService.awardPoints(eventType, refId, metadata)`.
- Duplicate awards are rejected for the same event type and reference ID.
- The daily Stardust cap is 100 points. An award is clipped at the remaining daily capacity.
- Career nodes are data-driven in `lib/config/career_progress_config.dart`: Launch Pad, Foundation, Skill Forge, Portfolio Station, Interview Orbit, Job Galaxy.
- Ranks are Cadet, Explorer, Navigator, Commander, Captain.
- Existing `PointsManager` remains intact during migration; existing features will receive one additional `awardPoints` call at their completion point.
- Missing artwork uses existing planet assets or a local vector/gradient placeholder; no external copyrighted assets are introduced.
- The map route is generated deterministically from milestone thresholds: 29
  stepping stones follow an S-shaped curve, and milestone stones are mapped to
  the nearest generated step. New career tracks can change data without
  scattering pixel coordinates through the UI.
- Stepping stones and the space backdrop use Flutter Canvas and gradients.
  Existing local planet and mascot assets are reused; no dependency was added.
- Mascot travel uses a hop arc and can be skipped with a tap. The animation is
  intentionally lightweight for mid-range devices.
