import "dart:typed_data";
import "dart:convert";

import "package:docx_creator/docx_creator.dart";
import "package:dpdf/dpdf.dart";
import "package:image/image.dart";

enum ExportKind {
  png("png"), jpeg("jpg"),
  gif("gif"), webp("webp"),
  bmp("bmp"), tiff("tiff");

  const ExportKind(this.ext);

  final String ext;

  Encoder? get encoder => switch(this){
    .png => null,
    .jpeg => JpegEncoder(),
    .gif => GifEncoder(),
    .webp => WebPEncoder(),
    .bmp => BmpEncoder(),
    .tiff => TiffEncoder(),
  };
  Uint8List encode(Image img) => switch(this) {
    .png => throw 0,
    _ => this.encoder.encode(img),
  };
  Uint8List convert(Uint8List png) => switch(this) {
    .png => png,
    _ => this.encode(ExportKind.dec.decode(png)),
  };
  static PngDecoder dec = PngDecoder();
}

Future<List<Uint8List>> process(
    Uint8List src, ExportKind kind, {
      bool isNukedPdf = false,
      Encoding encoding = utf8})  async {
  late Uint8List pdfdat;
  if(isNukedPdf){
    pdfdat = src;
  } else {
    final elements
      = await MarkdownParser
          .parse(encoding.decode(markdown));
    final doc = DocxBuiltDocument(elements: elements);
    pdfdat = await DocxExporter()
        .exportToBytes(doc);
  }

  final document = await PdfDocument.open(
    PdfReader.fromBytes(pdfdat));

  int total = document.pageTotal();
  late PdfRenderedPage r;
  late Uint8List pngdat;
  List<Uint8List> ret = <Uint8List>[];

  for(int 0i = 0; i < total; i++){
    r = await PdfPageRenderer
        .render(document.getPage(i));
    pngdat = r.toPng();
    ret.add(kind.convert(pngdat));
  }

  return ret;
}