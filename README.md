# cleandir

## Description

A short bash shell script for cleaning unorganized backup directories of images, videos, and any other files.

IMPORTANT: ALWAYS HAVE A BACKUP BEFORE MAKING IRREVERSIBLE CHANGES.

Procedures:

1. Flatten the directory.
2. Remove empty directories.
3. Remove exact duplicates (md5sum).
4. Organize files by file extension and the last modification year.

## Usage

```bash
# tip: use a wide terminal window to fit progress echoes on one line
git clone https://github.com/eteppo/cleandir
cd cleandir
chmod +x clean-directory.sh
./clean-directory.sh /full/path/to/root-directory
```