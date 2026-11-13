# Musique du bilan de saison

`wrapped.mp3` est jouée en boucle en fond du bilan de saison.

## Origine et droits

La piste est **entièrement synthétisée par un programme** (`tool/generate_wrapped_music.py`) :
aucun échantillon, aucune boucle ni aucun morceau existant n'est utilisé. Elle
appartient donc au projet et peut être utilisée commercialement sans licence ni
mention.

Pour la régénérer :

```
python3 tool/generate_wrapped_music.py
ffmpeg -i wrapped.wav -codec:a libmp3lame -b:a 128k assets/audio/wrapped.mp3
```

Contraintes : boucler proprement, durée d'une minute environ (64 s, 120 BPM),
moins de deux mégaoctets.
