# cleandir

## Description

A short bash/shell script for cleaning up unorganized directories of images and videos (and any other files).

IMPORTANT: ALWAYS HAVE A BACKUP BEFORE MAKING IRREVERSIBLE CHANGES.

Procedures:

1. Flatten directory by moving all files to the root and removing empty directories.
2. Remove exact duplicates using md5sum.
3. Organize files by the file extension and last modification year.

## Usage

```bash
git clone https://github.com/eteppo/cleandir
bash ./cleandir/clean-directory.sh /full/path/to/target-directory
```
