# Maera shooting animation

The first presentation slice animates Maera's draw, hold, Focus, release,
follow-through, and recovery. Natural and Vey still use their static concepts.
All three characters share the arrow flight, impact, score popup, and sounds.

## Edit the presentation

- Open `features/range/maera_archer.tscn` and select `Sprite`. Its SpriteFrames
  resource contains named animations and atlas regions. Preview the sequences
  in Godot's SpriteFrames panel. Draw frames follow the existing 0.52-second
  readiness threshold; holding at full draw uses `hold` or `focus`.
- `BowSocket` sets the flight's visual origin. Keep it at the arrow's exit from
  the bow if changing the sprite's size or placement.
- Open `features/range/shot_feedback.tscn` to change flight and recovery timing
  or replace hit/miss/result sounds in the Inspector. The default flight is
  0.22 seconds, followed by 0.38 seconds of feedback, or 0.82 seconds for a
  terminal shot.
- `EffectPopup` shows already-resolved bonuses and Focus gains/refunds below
  the points at impact. It floats and fades with `ScorePopup` on the same clock.
- Draw/readiness audio players live in `range_view.tscn`; release, impact, and
  result players live in `shot_feedback.tscn`. WAV sources are reproducible
  with `python tools/generate_sfx.py`.

The atlas is generated raster art, with its accepted direction and last edit
prompt in `assets/art/maera/README.md`. It is an initial animation pass; it does
not replace the plan for consistent, hand-refined game-resolution pixel art.

## Handedness and camera

Maera shoots **left-handed toward screen right**, seen mostly from behind.
The copper right arm holds the bow in the foreground. The left drawing arm is
on the far side of her body and is occluded by the torso and head where
appropriate. Its elbow can appear beyond the silhouette. Keep that depth order
through the whole sequence; do not put the left sleeve across her visible back.
The right hand must remain an anatomical right hand. Its thumb wraps on the
far side of the grip, behind the bow/riser and hidden from this rear camera;
do not draw a thumb across the camera-facing side of the fist. The drawing hand,
bowstring vertex, and arrow nock meet in every pre-release pose.
At full draw, the drawing hand is hidden behind the far side of the head;
the visible neck and collar must have no glove or wrist protruding below the
chin. Overholding uses the same `hold` frame, while `focus` loops the full-draw
and focused-hold frames. Check both Focus frames when reviewing a long hold.

Grip reference: [Online Archery Academy's hand-position guide](https://www.onlinearcheryacademy.com/archery-hand-position-set/).

## Timing and scoring contract

The controller snapshots and scores the last displayed circle and target
centers at release. It reserves the shot, spends armed Focus once, and blocks
shooting, cancellation, Focus, and menu changes until feedback finishes. Targets
stay at that snapshot so the visible arrow and impact agree.

The view's presentation clock reports impact and completion. The controller
applies the already resolved points, impact record, and Focus refund at impact.
It advances the run only after completion. A reset clears the pending result
and all feedback. Animated motion never determines ring scores.

Regression assertions cover delayed scoring, duplicate events, input during
flight, frozen targets, Focus, final-shot transitions, and reset during flight.
