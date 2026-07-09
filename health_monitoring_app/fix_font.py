import sys
import codecs

def fix_mojibake(filepath):
    with open(filepath, 'rb') as f:
        content_bytes = f.read()
    
    # Try to decode as utf-8 (how it is stored on disk now)
    try:
        content_str = content_bytes.decode('utf-8')
    except Exception as e:
        print(f"File is not utf-8: {e}")
        return
        
    # The string currently contains things like 'KhÃ´ng thá»ƒ'
    # This means the original utf-8 bytes were interpreted as cp1252 (or latin1)
    try:
        # Encode back to bytes using cp1252
        fixed_bytes = content_str.encode('cp1252')
        # Decode the actual utf-8
        fixed_str = fixed_bytes.decode('utf-8')
    except Exception as e:
        print(f"Could not fix using cp1252: {e}")
        try:
            fixed_bytes = content_str.encode('latin1')
            fixed_str = fixed_bytes.decode('utf-8')
        except Exception as e2:
            print(f"Could not fix using latin1: {e2}")
            return
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(fixed_str)
        
    print(f"Successfully fixed mojibake in {filepath}")
    
fix_mojibake(r'c:\duan\CLONE\health_monitoring\health_monitoring_app\lib\utils\medication_dialog_helper.dart')
