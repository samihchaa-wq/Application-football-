#!/usr/bin/env python3
"""Neutralise les inscriptions composées par les spectateurs du stade.

Reconstitue les seules tribunes sur les 3,25 premières secondes à partir
d'une image neutre de la vidéo d'origine (3,2 s). Terrain, animation ultérieure,
format, cadence et durée sont conservés. Aucun texte de remplacement.
Ne modifie aucun dépôt original et n'accède à aucune donnée utilisateur.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import cv2
import numpy as np

HOLD_SECONDS = 3.14
END_SECONDS = 3.25
CLEAN_REFERENCE_SECONDS = 3.20


def neutralize(frame: np.ndarray, reference: np.ndarray, timestamp: float) -> np.ndarray:
    if timestamp >= END_SECONDS:
        return frame
    height, width = frame.shape[:2]
    scale = width / 720.0
    y = np.arange(height, dtype=np.float32)
    # Les deux bandes ne contiennent que les tribunes ; ne pas toucher au terrain.
    upper = np.minimum(y / 7.0, (189 * scale - y) / (10 * scale))
    lower = np.minimum(
        (y - 227 * scale) / (10 * scale),
        (380 * scale - y) / (10 * scale),
    )
    coverage = np.maximum(np.clip(upper, 0.0, 1.0), np.clip(lower, 0.0, 1.0))
    transition = (
        1.0 if timestamp < HOLD_SECONDS else
        max(0.0, (END_SECONDS - timestamp) / (END_SECONDS - HOLD_SECONDS))
    )
    alpha = (coverage * transition).reshape((-1, 1, 1))
    if not np.any(alpha):
        return frame
    # Apparition progressive dans le noir initial.
    level = min(1.0, max(0.0, timestamp / 0.65))
    repaired = frame.astype(np.float32) * (1.0 - alpha)
    repaired += reference.astype(np.float32) * (level * alpha)
    return np.clip(repaired, 0, 255).astype(np.uint8)


def convert(source: Path, target: Path) -> None:
    video = cv2.VideoCapture(str(source))
    if not video.isOpened():
        raise RuntimeError(f"Vidéo illisible : {source}")
    w = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = video.get(cv2.CAP_PROP_FPS)
    if (w, h) not in {(720, 1558), (1080, 2338)} or abs(fps - 30.0) > .01:
        raise RuntimeError(f"Format non reconnu : {w}x{h} à {fps} i/s")
    video.set(cv2.CAP_PROP_POS_MSEC, CLEAN_REFERENCE_SECONDS * 1000)
    ok, clean = video.read()
    if not ok:
        raise RuntimeError("Image de référence neutre introuvable")
    video.set(cv2.CAP_PROP_POS_FRAMES, 0)

    command = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-f", "rawvideo", "-pixel_format", "bgr24",
        "-video_size", f"{w}x{h}", "-framerate", "30", "-i", "pipe:0",
        "-an", "-c:v", "libx264", "-preset", "veryfast",
        "-crf", "22", "-pix_fmt", "yuv420p",
        "-movflags", "+faststart", str(target),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    count = 0
    try:
        while True:
            ok, frame = video.read()
            if not ok:
                break
            assert process.stdin is not None
            process.stdin.write(neutralize(frame, clean, count / 30.0).tobytes())
            count += 1
    finally:
        assert process.stdin is not None
        process.stdin.close()
        status = process.wait()
        video.release()
    if status or count != 451:
        raise RuntimeError(f"Encodage incomplet : status={status}, frames={count}")
    print(f"{source} → {target} ({count} images)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="assets/composition")
    parser.add_argument("--output", default="build/neutral-stadium")
    args = parser.parse_args()
    source = Path(args.source)
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    for filename in ("stade.mp4", "stade-720.mp4"):
        convert(source / filename, output / filename)


if __name__ == "__main__":
    main()
