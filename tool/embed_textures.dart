// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// Embeds raw image bytes into a GLB file as a standard glTF bufferView,
/// replacing external URI references (such as `Textures/colormap.png`).
Uint8List embedTextureInGlb(
  Uint8List glbBytes,
  Uint8List imageBytes,
  String mimeType,
) {
  final byteData = ByteData.sublistView(glbBytes);
  final magic = byteData.getUint32(0, Endian.little);
  final version = byteData.getUint32(4, Endian.little);
  if (magic != 0x46546C67 || version != 2) {
    throw Exception('Not a valid GLB 2.0 file');
  }

  int offset = 12;
  int? jsonChunkLength;
  int? jsonChunkStart;
  int? binChunkLength;
  int? binChunkStart;

  while (offset < glbBytes.length) {
    final chunkLength = byteData.getUint32(offset, Endian.little);
    final typeStr = String.fromCharCodes(
      glbBytes.sublist(offset + 4, offset + 8),
    );
    if (typeStr == 'JSON') {
      jsonChunkLength = chunkLength;
      jsonChunkStart = offset + 8;
    } else if (typeStr == 'BIN\x00') {
      binChunkLength = chunkLength;
      binChunkStart = offset + 8;
    }
    offset += 8 + chunkLength;
  }

  if (jsonChunkStart == null || jsonChunkLength == null) {
    throw Exception('No JSON chunk found');
  }

  final jsonStr = utf8.decode(
    glbBytes.sublist(jsonChunkStart, jsonChunkStart + jsonChunkLength),
  );
  final Map<String, dynamic> gltf = jsonDecode(jsonStr);

  Uint8List existingBin = binChunkStart != null && binChunkLength != null
      ? glbBytes.sublist(binChunkStart, binChunkStart + binChunkLength)
      : Uint8List(0);

  int padBin = (4 - (existingBin.length % 4)) % 4;
  int imageOffset = existingBin.length + padBin;

  final newBinBuilder = BytesBuilder();
  newBinBuilder.add(existingBin);
  if (padBin > 0) {
    newBinBuilder.add(Uint8List(padBin));
  }
  newBinBuilder.add(imageBytes);
  int finalBinPad = (4 - (newBinBuilder.length % 4)) % 4;
  if (finalBinPad > 0) {
    newBinBuilder.add(Uint8List(finalBinPad));
  }
  final newBin = newBinBuilder.toBytes();

  List bufferViews = gltf['bufferViews'] = (gltf['bufferViews'] as List? ?? []);
  int newBufferViewIndex = bufferViews.length;
  bufferViews.add({
    'buffer': 0,
    'byteOffset': imageOffset,
    'byteLength': imageBytes.length,
  });

  List buffers = gltf['buffers'] = (gltf['buffers'] as List? ?? []);
  if (buffers.isEmpty) {
    buffers.add({'byteLength': newBin.length});
  } else {
    buffers[0] = {'byteLength': newBin.length};
  }

  List images = gltf['images'] = (gltf['images'] as List? ?? []);
  for (int i = 0; i < images.length; i++) {
    var img = Map<String, dynamic>.from(images[i]);
    img.remove('uri');
    img['bufferView'] = newBufferViewIndex;
    img['mimeType'] = mimeType;
    images[i] = img;
  }

  final newJsonStr = jsonEncode(gltf);
  final newJsonBytes = utf8.encode(newJsonStr);
  int jsonPad = (4 - (newJsonBytes.length % 4)) % 4;
  final finalJsonBuilder = BytesBuilder();
  finalJsonBuilder.add(newJsonBytes);
  if (jsonPad > 0) {
    finalJsonBuilder.add(List.filled(jsonPad, 0x20));
  }
  final finalJson = finalJsonBuilder.toBytes();

  final totalLength = 12 + 8 + finalJson.length + 8 + newBin.length;
  final result = BytesBuilder();

  final headerBytes = ByteData(12);
  headerBytes.setUint32(0, 0x46546C67, Endian.little);
  headerBytes.setUint32(4, 2, Endian.little);
  headerBytes.setUint32(8, totalLength, Endian.little);
  result.add(headerBytes.buffer.asUint8List());

  final jsonHeader = ByteData(8);
  jsonHeader.setUint32(0, finalJson.length, Endian.little);
  jsonHeader.setUint32(4, 0x4E4F534A, Endian.little);
  result.add(jsonHeader.buffer.asUint8List());
  result.add(finalJson);

  final binHeader = ByteData(8);
  binHeader.setUint32(0, newBin.length, Endian.little);
  binHeader.setUint32(4, 0x004E4942, Endian.little);
  result.add(binHeader.buffer.asUint8List());
  result.add(newBin);

  return result.toBytes();
}

void main() {
  final carColormap = Uint8List.fromList(
    Process.runSync('unzip', [
          '-p',
          '.assetcache/car-kit.zip',
          'Models/GLB format/Textures/colormap.png',
        ], stdoutEncoding: null).stdout
        as List<int>,
  );

  final charColormap = Uint8List.fromList(
    Process.runSync('unzip', [
          '-p',
          '.assetcache/mini-characters.zip',
          'Models/GLB format/Textures/colormap.png',
        ], stdoutEncoding: null).stdout
        as List<int>,
  );

  final toyColormap = Uint8List.fromList(
    Process.runSync('unzip', [
          '-p',
          '.assetcache/toy-car-kit.zip',
          'Models/GLB format/Textures/colormap.png',
        ], stdoutEncoding: null).stdout
        as List<int>,
  );

  final cityColormap = Uint8List.fromList(
    Process.runSync('unzip', [
          '-p',
          '.assetcache/city-kit-suburban.zip',
          'Models/GLB format/Textures/colormap.png',
        ], stdoutEncoding: null).stdout
        as List<int>,
  );

  final zips = {
    'car': (
      Process.runSync('unzip', [
        '-l',
        '.assetcache/car-kit.zip',
      ]).stdout.toString(),
      carColormap,
    ),
    'char': (
      Process.runSync('unzip', [
        '-l',
        '.assetcache/mini-characters.zip',
      ]).stdout.toString(),
      charColormap,
    ),
    'toy': (
      Process.runSync('unzip', [
        '-l',
        '.assetcache/toy-car-kit.zip',
      ]).stdout.toString(),
      toyColormap,
    ),
    'city': (
      Process.runSync('unzip', [
        '-l',
        '.assetcache/city-kit-suburban.zip',
      ]).stdout.toString(),
      cityColormap,
    ),
  };

  final glbFiles = Directory('assets/models')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.glb'))
      .toList();

  int modified = 0;
  for (final file in glbFiles) {
    final bytes = file.readAsBytesSync();
    final byteData = ByteData.sublistView(bytes);
    int offset = 12;
    bool hasUri = false;
    while (offset < bytes.length) {
      final chunkLength = byteData.getUint32(offset, Endian.little);
      final typeStr = String.fromCharCodes(
        bytes.sublist(offset + 4, offset + 8),
      );
      if (typeStr == 'JSON') {
        final jsonStr = utf8.decode(
          bytes.sublist(offset + 8, offset + 8 + chunkLength),
        );
        final jsonObj = jsonDecode(jsonStr);
        final images = jsonObj['images'] as List?;
        if (images != null) {
          for (var img in images) {
            if (img['uri'] != null) {
              hasUri = true;
              break;
            }
          }
        }
        break;
      }
      offset += 8 + chunkLength;
    }

    if (!hasUri) continue;

    final name = file.uri.pathSegments.last;
    Uint8List? textureToEmbed;
    for (final entry in zips.entries) {
      if (entry.value.$1.contains(name)) {
        textureToEmbed = entry.value.$2;
        break;
      }
    }

    if (textureToEmbed != null) {
      final newBytes = embedTextureInGlb(bytes, textureToEmbed, 'image/png');
      file.writeAsBytesSync(newBytes);
      modified++;
    }
  }

  print('Successfully processed GLBs: $modified embedded.');
}
