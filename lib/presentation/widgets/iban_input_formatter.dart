import 'package:flutter/services.dart';

class IbanInputFormatter extends TextInputFormatter {
  // IBAN'ı formatla: TR50 0000 0022 3333 4444 77
  static String formatIban(String digits) {
    if (digits.isEmpty) return 'TR';
    if (digits.length <= 2) return 'TR$digits';
    
    // Format: TR50 (4) + space + 0000 (4) + space + 0022 (4) + space + 3333 (4) + space + 4444 (4) + space + 77 (2)
    final part1 = digits.substring(0, 2); // İlk 2 rakam (50)
    final remaining = digits.substring(2);
    
    String formatted = 'TR$part1';
    
    // Kalan rakamları 4'erli gruplara böl
    for (int i = 0; i < remaining.length; i += 4) {
      final end = (i + 4 < remaining.length) ? i + 4 : remaining.length;
      formatted += ' ${remaining.substring(i, end)}';
    }
    
    return formatted;
  }
  
  // Formatlanmış IBAN'dan rakamları çıkar
  // Eğer başta TR varsa onu atlar, yoksa direkt rakamları alır
  String _extractDigits(String formattedIban) {
    if (formattedIban.isEmpty) return '';
    
    String text = formattedIban.toUpperCase();
    
    // Başta TR varsa onu atla
    if (text.startsWith('TR')) {
      text = text.substring(2);
    }
    
    // Sadece rakamları al
    return text.replaceAll(RegExp(r'[^\d]'), '');
  }
  
  // Cursor pozisyonunu formatlanmış text'e göre ayarla
  int _adjustCursorPosition(int oldCursorPos, String oldFormatted, String newFormatted, int oldDigitCount, int newDigitCount) {
    // Eğer cursor TR'nin içindeyse veya önündeyse
    if (oldCursorPos <= 2) {
      return _getCursorPositionForDigitCount(newFormatted, newDigitCount);
    }
    
    // Eski formatlanmış text'te cursor'ın hangi rakamın üzerinde olduğunu bul
    final oldDigitsBeforeCursor = _countDigitsBeforePosition(oldFormatted, oldCursorPos);
    
    // Eğer rakam eklendiyse (yeni rakam sayısı > eski rakam sayısı)
    if (newDigitCount > oldDigitCount) {
      // Yeni rakam cursor pozisyonuna eklendi, cursor'ı bir sonraki pozisyona taşı
      return _getCursorPositionForDigitCount(newFormatted, oldDigitsBeforeCursor + 1);
    } else if (newDigitCount < oldDigitCount) {
      // Rakam silindi, cursor'ı bir önceki pozisyona taşı
      return _getCursorPositionForDigitCount(newFormatted, oldDigitsBeforeCursor - 1);
    } else {
      // Rakam sayısı aynı (muhtemelen geçersiz karakter silindi)
      // Cursor pozisyonunu koru
      return _getCursorPositionForDigitCount(newFormatted, oldDigitsBeforeCursor);
    }
  }
  
  // Belirli bir rakam sayısı için cursor pozisyonunu hesapla
  int _getCursorPositionForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 2; // TR'nin sonu
    
    final totalDigits = formatted.replaceAll(' ', '').length - 2; // TR'den sonraki rakam sayısı
    if (digitCount >= totalDigits) {
      return formatted.length; // En son
    }
    
    // Formatlanmış text'te kaç rakam geçtiğini say
    int digitCounter = 0;
    for (int i = 2; i < formatted.length; i++) {
      if (formatted[i] != ' ') {
        digitCounter++;
        if (digitCounter == digitCount) {
          return i + 1; // Rakamdan sonraki pozisyon
        }
      }
    }
    
    return formatted.length;
  }
  
  // Belirli bir pozisyondan önce kaç rakam olduğunu say
  int _countDigitsBeforePosition(String formatted, int position) {
    int count = 0;
    for (int i = 2; i < position && i < formatted.length; i++) {
      if (formatted[i] != ' ') {
        count++;
      }
    }
    return count;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final selection = newValue.selection;

    // Eğer text boşsa, TR ekle
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: 'TR',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // Eski text'ten rakamları çıkar
    final oldDigitsOnly = _extractDigits(oldText);

    // Yeni text'ten rakamları çıkar (başta TR varsa otomatik olarak atlanır)
    final newDigitsOnly = _extractDigits(newText);
    
    // Eski ve yeni rakam sayılarını karşılaştır
    final oldDigitCount = oldDigitsOnly.length;
    final newDigitCount = newDigitsOnly.length;
    
    String finalDigits;
    
    // Eğer rakam eklendiyse (yeni > eski) ve cursor pozisyonu ortadaysa
    if (newDigitCount > oldDigitCount && selection.baseOffset > 2 && oldDigitCount > 0) {
      // Eski text'te cursor pozisyonundan önce kaç rakam var
      final digitsBeforeCursor = _countDigitsBeforePosition(oldText, selection.baseOffset);
      
      // Cursor pozisyonuna göre rakamları yeniden düzenle
      if (digitsBeforeCursor < oldDigitCount) {
        // Cursor ortada, yeni rakamı cursor pozisyonuna ekle
        final beforeCursor = oldDigitsOnly.substring(0, digitsBeforeCursor);
        final afterCursor = oldDigitsOnly.substring(digitsBeforeCursor);
        
        // Yeni eklenen rakamı bul - newDigitsOnly ile oldDigitsOnly'yi karşılaştır
        // newDigitsOnly'deki fazla karakteri bul
        String addedDigit = '';
        if (newDigitsOnly.length > oldDigitsOnly.length) {
          // İki string'i karşılaştırarak yeni eklenen karakteri bul
          int oldIndex = 0;
          for (int i = 0; i < newDigitsOnly.length && oldIndex < oldDigitsOnly.length; i++) {
            if (newDigitsOnly[i] == oldDigitsOnly[oldIndex]) {
              oldIndex++;
            } else {
              // Bu yeni eklenen karakter
              addedDigit = newDigitsOnly[i];
              break;
            }
          }
          // Eğer hala bulamadıysak, son karakteri al
          if (addedDigit.isEmpty && newDigitsOnly.length > oldDigitsOnly.length) {
            addedDigit = newDigitsOnly[newDigitsOnly.length - 1];
          }
        }
        
        if (addedDigit.isNotEmpty) {
          // Yeni rakamı cursor pozisyonuna ekle
          finalDigits = beforeCursor + addedDigit + afterCursor;
          // 24 karakter sınırını kontrol et
          if (finalDigits.length > 24) {
            finalDigits = finalDigits.substring(0, 24);
          }
        } else {
          // Eklenen rakam bulunamadı, direkt kullan
          finalDigits = newDigitsOnly;
        }
      } else {
        // Cursor sonda, direkt ekle
        finalDigits = newDigitsOnly;
      }
    } else {
      // Rakam silindi veya cursor başta, direkt kullan
      finalDigits = newDigitsOnly;
    }
    
    // Maksimum 24 rakam
    final limitedDigits = finalDigits.length > 24 
        ? finalDigits.substring(0, 24) 
        : finalDigits;
    
    final formattedText = formatIban(limitedDigits);
    
    // Cursor pozisyonunu hesapla
    int cursorPosition = _adjustCursorPosition(
      selection.baseOffset,
      oldText,
      formattedText,
      oldDigitCount,
      limitedDigits.length,
    );

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}







