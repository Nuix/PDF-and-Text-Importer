PDF and Text Importer
=====================

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/PDF-and-Text-Importer) or download the latest release [here](https://github.com/Nuix/PDF-and-Text-Importer/releases).

# Overview

**Written By:** Jason Wells

Allows you to import text files and PDF files into your Nuix case by matching files in a directory named either after the corresponding items' GUID or MD5.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Settings

| Setting                                   | Description                                                                                               |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Source Directory**                      | A directory containing PDF and/or text files.  Files may be nested within sub directories.                |
| **Files have MD5 naming**                 | Items will be matched to files by using each file's name as MD5.                                          |
| **Files have GUID naming**                | Items will be matched to files by using each file's name as GUID.                                         |
| **Import PDFs**                           | Determines whether the script will attempt to import PDF files found in the source directory.             |
| **Import Text**                           | Determines whether the script will attempt to import text files found in the source directory.            |
| **Text File Encoding**                    | The encoding used to open text files being imported.                                                      |
| **Append Imported Text to Existing Text** | When checked, imported text will be appended to text already present for the item.                        |
| **Appended Text Separator**               | When appending text, this value will be placed in between the original text and the appended text.  Supports supplying `\n` to specify a newline character and `\t` to specify a tab character. |
| **Tag Updated Items**                     | When checked, items which have text and/or PDF files imported will be tagged with the supplied tag name.  |

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```