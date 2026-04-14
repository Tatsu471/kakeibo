import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  // TODO: Google Cloud Vision APIキーをここに設定してください
  static const String _apiKey = 'AIzaSyBx2GZlLfyvr0k8kB5ijldrs3Wy_Aa3mgo';
  static const String _apiUrl = 'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  /// 画像データからレシートの合計金額を抽出する
  Future<int?> extractAmount(Uint8List imageBytes) async {
    if (_apiKey == 'YOUR_GOOGLE_CLOUD_VISION_API_KEY') {
      throw Exception('Google Cloud Vision APIキーが設定されていません。');
    }

    final base64Image = base64Encode(imageBytes);

    final requestBody = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [{'type': 'TEXT_DETECTION'}]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fullText = data['responses'][0]['fullTextAnnotation']?['text'] as String?;
      if (fullText != null) {
        return _parseAmount(fullText);
      }
    } else {
      throw Exception('OCR解析に失敗しました: ${response.statusCode}');
    }
    return null;
  }

  /// 抽出されたテキストから「合計金額」と思われる数値を正規表現で探す
  int? _parseAmount(String text) {
    // 1. 改行で分割
    final lines = text.split('\n');
    
    // 2. 「合計」「Total」「小計」などのキーワードを探す
    // 日本のレシートでよく使われるキーワード
    final keywords = ['合計', '合計金額', '総計', 'お支払', '支払額', 'Total', 'TOTAL', 'Amount'];
    
    int? result;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].replaceAll(' ', '').replaceAll(',', '');
      
      bool foundKeyword = false;
      for (var kw in keywords) {
        if (line.contains(kw)) {
          foundKeyword = true;
          break;
        }
      }

      if (foundKeyword) {
        // その行、あるいは次の行から数値を抽出
        final amount = _extractNumber(line) ?? (i + 1 < lines.length ? _extractNumber(lines[i+1]) : null);
        if (amount != null) {
          // 最も大きい数値を合計とみなす（税抜き金額などと混同しないよう暫定）
          if (result == null || amount > result) {
            result = amount;
          }
        }
      }
    }

    return result;
  }

  int? _extractNumber(String text) {
    // 数字以外の文字（円、¥、$など）を除去して連続した数字を抽出
    final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return null;
    return int.tryParse(cleanText);
  }
}
