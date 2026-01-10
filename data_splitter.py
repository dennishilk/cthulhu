#!/usr/bin/env python3
import os
import zipfile
import argparse
import stat

MAX_SIZE_MB = 100
MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024


def is_regular_file(path):
    try:
        st = os.lstat(path)
        return stat.S_ISREG(st.st_mode)
    except FileNotFoundError:
        return False


def should_skip(path):
    name = os.path.basename(path)
    if name.startswith("Singleton"):
        return True
    if name.endswith(".sock"):
        return True
    return False


def create_backup(source_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    part = 1
    zipf = None
    zip_path = None
    current_size = 0

    def new_zip():
        nonlocal part, zipf, zip_path, current_size
        if zipf:
            zipf.close()
        zip_path = os.path.join(output_dir, f"backup-part{part:03d}.zip")
        zipf = zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED)
        print(f"\n📦 Creating {os.path.basename(zip_path)}")
        current_size = 0
        part += 1

    new_zip()

    for root, dirs, files in os.walk(source_dir):
        for f in files:
            full_path = os.path.join(root, f)

            if should_skip(full_path):
                print(f"⏭️  Skipping {full_path}")
                continue

            if not is_regular_file(full_path):
                continue

            try:
                file_size = os.path.getsize(full_path)
            except FileNotFoundError:
                continue

            # HARD RULE: single file too large → skip
            if file_size >= MAX_SIZE_BYTES:
                print(f"🚫 File too large (>24MB), skipped: {full_path}")
                continue

            # Would exceed ZIP limit → new archive
            if current_size + file_size >= MAX_SIZE_BYTES:
                new_zip()

            try:
                arcname = os.path.relpath(full_path, source_dir)
                zipf.write(full_path, arcname)
                current_size += file_size
            except Exception as e:
                print(f"⚠️  Failed to add {full_path}: {e}")

    if zipf:
        zipf.close()

    print(f"\n✅ Backup finished. All archives < {MAX_SIZE_MB} MB.")


def main():
    parser = argparse.ArgumentParser(
        description="Split directory into GitHub-safe ZIP parts (<24MB)."
    )
    parser.add_argument("source", help="Directory to back up")
    parser.add_argument("output", help="Output directory")

    args = parser.parse_args()
    create_backup(args.source, args.output)


if __name__ == "__main__":
    main()
