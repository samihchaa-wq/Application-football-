import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// Repeint le stade aux couleurs du club, image par image.
///
/// La vidéo d'origine a des tribunes, drapeaux et fumigènes bleus et jaunes.
/// Chaque image est redessinée sur une toile : les bleus prennent la couleur
/// principale du club, les jaunes sa seconde couleur. La pelouse (verte), les
/// lignes (blanches) et les fumigènes rouges ne bougent pas. Les ombres et
/// reflets sont conservés : seule la teinte change.
///
/// Si le téléphone ne sait pas dessiner ainsi (WebGL absent ou refusé),
/// [StadiumRecolor.create] rend null : la vidéo est alors montée telle quelle,
/// atténuée, pour ne pas afficher les couleurs d'un autre club.
class StadiumRecolor {
  StadiumRecolor._(
    this.canvas,
    this._gl,
    this._texture,
    this._scaleLocation,
  );

  final web.HTMLCanvasElement canvas;
  final web.WebGLRenderingContext _gl;
  final web.WebGLTexture _texture;
  final web.WebGLUniformLocation? _scaleLocation;

  static const _vertexShader = '''
attribute vec2 aPos;
varying vec2 vUv;
void main() {
  vUv = vec2(aPos.x * 0.5 + 0.5, 0.5 - aPos.y * 0.5);
  gl_Position = vec4(aPos, 0.0, 1.0);
}
''';

  // Même calcul que la maquette validée sur l'image fixe : un poids par
  // famille de teinte (bleus autour de 222°, jaunes autour de 47°), nul pour
  // les couleurs ternes, puis la couleur du club éclaircie ou assombrie comme
  // l'était l'original.
  static const _fragmentShader = '''
precision mediump float;
varying vec2 vUv;
uniform sampler2D uImage;
uniform vec2 uScale;
uniform vec3 uPrimary;
uniform vec3 uSecondary;

vec3 rgb2hsl(vec3 c) {
  float mx = max(max(c.r, c.g), c.b);
  float mn = min(min(c.r, c.g), c.b);
  float d = mx - mn;
  float l = (mx + mn) * 0.5;
  if (d < 1e-5) return vec3(0.0, 0.0, l);
  float s = d / max(1.0 - abs(2.0 * l - 1.0), 1e-5);
  float h;
  if (mx == c.r) h = mod((c.g - c.b) / d, 6.0);
  else if (mx == c.g) h = (c.b - c.r) / d + 2.0;
  else h = (c.r - c.g) / d + 4.0;
  return vec3(h * 60.0, s, l);
}

vec3 hsl2rgb(vec3 hsl) {
  float c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
  float hp = mod(hsl.x / 60.0, 6.0);
  float x = c * (1.0 - abs(mod(hp, 2.0) - 1.0));
  vec3 rgb;
  if (hp < 1.0) rgb = vec3(c, x, 0.0);
  else if (hp < 2.0) rgb = vec3(x, c, 0.0);
  else if (hp < 3.0) rgb = vec3(0.0, c, x);
  else if (hp < 4.0) rgb = vec3(0.0, x, c);
  else if (hp < 5.0) rgb = vec3(x, 0.0, c);
  else rgb = vec3(c, 0.0, x);
  return rgb + (hsl.z - c * 0.5);
}

float band(float h, float center, float width, float soft) {
  float dist = abs(mod(h - center + 180.0, 360.0) - 180.0);
  return clamp((width + soft - dist) / soft, 0.0, 1.0);
}

vec3 paint(vec3 hsl, vec3 club, float refL) {
  float l = clamp(club.z + (hsl.z - refL), 0.0, 1.0);
  float s = club.y * min(1.0, hsl.y / 0.6);
  return hsl2rgb(vec3(club.x, s, l));
}

void main() {
  vec2 uv = 0.5 + (vUv - 0.5) * uScale;
  vec3 c = texture2D(uImage, uv).rgb;
  vec3 hsl = rgb2hsl(c);
  float vivid = clamp((hsl.y - 0.15) / 0.2, 0.0, 1.0);
  float wb = band(hsl.x, 222.0, 32.0, 12.0) * vivid;
  float wy = band(hsl.x, 47.0, 16.0, 8.0) * vivid;
  c = mix(c, paint(hsl, uPrimary, 0.40), wb);
  c = mix(c, paint(hsl, uSecondary, 0.55), wy);
  gl_FragColor = vec4(c, 1.0);
}
''';

  /// Prépare la toile, ou null si le téléphone ne sait pas la dessiner.
  static StadiumRecolor? create({
    required Color primary,
    required Color secondary,
  }) {
    try {
      final canvas = web.HTMLCanvasElement();
      canvas.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = 'none';
      final context = canvas.getContext(
        'webgl',
        {'premultipliedAlpha': false, 'antialias': false}.jsify(),
      );
      if (context == null) return null;
      final gl = context as web.WebGLRenderingContext;

      final program = gl.createProgram();
      final vertex =
          _compile(gl, web.WebGLRenderingContext.VERTEX_SHADER, _vertexShader);
      final fragment = _compile(
          gl, web.WebGLRenderingContext.FRAGMENT_SHADER, _fragmentShader);
      if (program == null || vertex == null || fragment == null) return null;
      gl
        ..attachShader(program, vertex)
        ..attachShader(program, fragment)
        ..linkProgram(program);
      final linked = gl.getProgramParameter(
          program, web.WebGLRenderingContext.LINK_STATUS);
      if (linked.dartify() != true) return null;
      gl.useProgram(program);

      final buffer = gl.createBuffer();
      gl
        ..bindBuffer(web.WebGLRenderingContext.ARRAY_BUFFER, buffer)
        ..bufferData(
          web.WebGLRenderingContext.ARRAY_BUFFER,
          Float32List.fromList([-1, -1, 1, -1, -1, 1, 1, 1]).toJS,
          web.WebGLRenderingContext.STATIC_DRAW,
        );
      final position = gl.getAttribLocation(program, 'aPos');
      gl
        ..enableVertexAttribArray(position)
        ..vertexAttribPointer(
            position, 2, web.WebGLRenderingContext.FLOAT, false, 0, 0);

      final texture = gl.createTexture();
      if (texture == null) return null;
      gl.bindTexture(web.WebGLRenderingContext.TEXTURE_2D, texture);
      for (final (name, value) in [
        (
          web.WebGLRenderingContext.TEXTURE_WRAP_S,
          web.WebGLRenderingContext.CLAMP_TO_EDGE
        ),
        (
          web.WebGLRenderingContext.TEXTURE_WRAP_T,
          web.WebGLRenderingContext.CLAMP_TO_EDGE
        ),
        (
          web.WebGLRenderingContext.TEXTURE_MIN_FILTER,
          web.WebGLRenderingContext.LINEAR
        ),
        (
          web.WebGLRenderingContext.TEXTURE_MAG_FILTER,
          web.WebGLRenderingContext.LINEAR
        ),
      ]) {
        gl.texParameteri(web.WebGLRenderingContext.TEXTURE_2D, name, value);
      }

      void setColor(String uniform, Color color) {
        final hsl = HSLColor.fromColor(color.withValues(alpha: 1));
        gl.uniform3f(gl.getUniformLocation(program, uniform), hsl.hue,
            hsl.saturation, hsl.lightness);
      }

      setColor('uPrimary', primary);
      setColor('uSecondary', secondary);
      gl.uniform1i(gl.getUniformLocation(program, 'uImage'), 0);

      return StadiumRecolor._(
        canvas,
        gl,
        texture,
        gl.getUniformLocation(program, 'uScale'),
      );
    } catch (_) {
      return null;
    }
  }

  static web.WebGLShader? _compile(
    web.WebGLRenderingContext gl,
    int type,
    String source,
  ) {
    final shader = gl.createShader(type);
    if (shader == null) return null;
    gl
      ..shaderSource(shader, source)
      ..compileShader(shader);
    final ok =
        gl.getShaderParameter(shader, web.WebGLRenderingContext.COMPILE_STATUS);
    return ok.dartify() == true ? shader : null;
  }

  /// Dessine [source] (la vidéo ou l'image fixe), cadrée comme
  /// `object-fit: cover`. Rend false si le dessin a échoué : la vidéo doit
  /// alors être montrée telle quelle.
  bool draw(web.TexImageSource source, int mediaWidth, int mediaHeight) {
    if (mediaWidth <= 0 || mediaHeight <= 0) return true;
    try {
      final ratio = web.window.devicePixelRatio.clamp(1, 2);
      final width = (canvas.clientWidth * ratio).round().clamp(1, 1440);
      final height = (canvas.clientHeight * ratio).round().clamp(1, 3120);
      if (canvas.width != width || canvas.height != height) {
        canvas
          ..width = width
          ..height = height;
        _gl.viewport(0, 0, width, height);
      }
      final view = width / height;
      final media = mediaWidth / mediaHeight;
      final scaleX = view < media ? view / media : 1.0;
      final scaleY = view < media ? 1.0 : media / view;
      _gl
        ..uniform2f(_scaleLocation, scaleX, scaleY)
        ..bindTexture(web.WebGLRenderingContext.TEXTURE_2D, _texture)
        ..texImage2D(
          web.WebGLRenderingContext.TEXTURE_2D,
          0,
          web.WebGLRenderingContext.RGBA,
          web.WebGLRenderingContext.RGBA.toJS,
          web.WebGLRenderingContext.UNSIGNED_BYTE.toJS,
          source,
        )
        ..drawArrays(web.WebGLRenderingContext.TRIANGLE_STRIP, 0, 4);
      return true;
    } catch (_) {
      return false;
    }
  }
}
