import subprocess
import os
import sys

# Configuration
OUTPUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "store_assets", "screenshots", "raw"))

def get_adb():
    adb_path = os.path.expandvars(r"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe")
    return adb_path if os.path.exists(adb_path) else "adb"

ADB = get_adb()

def capture(name):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    
    try:
        # Fast direct capture (exec-out)
        with open(path, "wb") as f:
            subprocess.run([ADB, "exec-out", "screencap", "-p"], stdout=f, check=True)
        print(f"   [OK] Saved: {name}.png")
        return True
    except Exception as e:
        print(f"   [ERROR] Could not capture: {e}")
        return False

def main():
    print("-" * 40)
    print(" SINAN NOTE - SCREENSHOT TOOL ")
    print("-" * 40)
    print(" KEYS:")
    print(" [Enter]        : Capture & Next Screen")
    print(" [Space + Enter]: Retry Current Screen (Overwrite)")
    print(" [S + Enter]    : Exit Program")
    print("-" * 40)

    screens = [
        "01_home",
        "02_editor",
        "03_checklist",
        "04_code",
        "05_vault",
        "06_dark",
        "07_categories",
        "08_reminder"
    ]

    i = 0
    while i < len(screens):
        current_screen = screens[i]
        user_input = input(f"\nREADY [{current_screen}] > ")

        if user_input.lower() == 's':
            print("Exiting...")
            break
        
        elif user_input == " ": # Space was pressed
            capture(current_screen)
            print(f"   [!] Retried {current_screen}. Staying on this screen...")
            # We don't increment 'i' so we stay on the same screen
        
        elif user_input == "": # Just Enter was pressed
            if capture(current_screen):
                i += 1 # Move to the next screen name
        
        else:
            print("   [?] Unknown key. Use Enter, Space, or S.")

    print("\nALL DONE! Screenshots saved in:")
    print(OUTPUT_DIR)

if __name__ == "__main__":
    main()